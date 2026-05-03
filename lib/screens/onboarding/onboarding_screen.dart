import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/onboarding_question.dart';
import '../../models/country.dart';
import '../../services/storage_service.dart';
import '../../services/country_service.dart';
import '../../services/onboarding_api_service.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isUpdateMode;
  
  const OnboardingScreen({
    super.key,
    this.isUpdateMode = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final List<OnboardingQuestion> _questions = OnboardingQuestion.getQuestions();
  final Map<String, dynamic> _responses = {};
  int _currentPage = 0;

  // For multi-select questions
  final Map<String, List<String>> _multiSelectResponses = {};

  bool _showCountryPage = false;
  Country? _selectedCountry;
  List<Country> _countries = [];
  bool _loadingCountries = false;
  bool _isLoadingPreloads = false;

  @override
  void initState() {
    super.initState();
    if (widget.isUpdateMode) {
      _loadExistingPreferences();
    }
  }

  Future<void> _loadExistingPreferences() async {
    setState(() {
      _isLoadingPreloads = true;
    });

    try {
      final apiService = OnboardingApiService();
      final data = await apiService.getOnboardingResponse();
      
      if (data != null && mounted) {
        setState(() {
          if (data['visitorType'] != null) {
            _responses['q1'] = data['visitorType'];
            if (data['visitorType'] == 'Foreign Visitor') {
              _showCountryPage = true;
              if (data['country'] != null) {
                // Temporary country until loaded
                _selectedCountry = Country(name: data['country'], code: '', flag: '');
              }
            }
          }
          
          if (data['userType'] != null) {
            _responses['q2'] = data['userType'];
          }
          
          if (data['interests'] != null && data['interests'] is List) {
            final List<String> interests = List<String>.from(data['interests']);
            _multiSelectResponses['q3'] = interests;
            _responses['q3'] = interests;
          }
          
          if (data['timePreference'] != null) {
            _responses['q4'] = data['timePreference'];
          }
          
          if (data['languagePreference'] != null) {
            _responses['q5'] = data['languagePreference'];
          }
        });

        // Load full country list if needed
        if (_showCountryPage) {
          await _loadCountries();
          // Try to match the selected country with the actual list
          if (_selectedCountry != null && _countries.isNotEmpty) {
            try {
              final actualCountry = _countries.firstWhere(
                (c) => c.name == _selectedCountry!.name
              );
              setState(() {
                _selectedCountry = actualCountry;
              });
            } catch (e) {
              // Country not found in list, keep the temporary one
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error preloading preferences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreloads = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectOption(String questionId, String option) {
    setState(() {
      _responses[questionId] = option;

      // Check if Q1 (visitor type) and Foreign Visitor selected
      if (questionId == 'q1' && option == 'Foreign Visitor') {
        _showCountryPage = true;
        _loadCountries();
      } else if (questionId == 'q1') {
        _showCountryPage = false;
      }
    });

    // Auto-advance to next question after short delay (only for single select)
    Future.delayed(AppConstants.animationNormal, () {
      if (_currentPage < _getTotalPages() - 1) {
        _pageController.nextPage(
          duration: AppConstants.animationNormal,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadCountries() async {
    if (_countries.isNotEmpty) return;

    setState(() {
      _loadingCountries = true;
    });

    try {
      final countryService = CountryService();
      final countries = await countryService.getAllCountries();
      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });
    } catch (e) {
      setState(() {
        _loadingCountries = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load countries: $e')),
        );
      }
    }
  }

  int _getTotalPages() {
    // Base questions + country page if foreign visitor
    return _questions.length + (_showCountryPage ? 1 : 0);
  }

  int _getActualQuestionIndex() {
    // If we're past Q1 and showing country page
    if (_showCountryPage && _currentPage == 1) {
      return -1; // Country page (not a question)
    } else if (_showCountryPage && _currentPage > 1) {
      return _currentPage - 1; // Adjust for inserted country page
    }
    return _currentPage;
  }

  void _toggleMultiSelect(String questionId, String option) {
    setState(() {
      if (!_multiSelectResponses.containsKey(questionId)) {
        _multiSelectResponses[questionId] = [];
      }

      if (_multiSelectResponses[questionId]!.contains(option)) {
        _multiSelectResponses[questionId]!.remove(option);
      } else {
        _multiSelectResponses[questionId]!.add(option);
      }

      // Update main responses
      _responses[questionId] = _multiSelectResponses[questionId];
    });
  }

  bool _canProceed() {
    // If on country page
    if (_showCountryPage && _currentPage == 1) {
      return _selectedCountry != null;
    }

    // Get the actual question index
    final questionIndex = _getActualQuestionIndex();
    if (questionIndex < 0 || questionIndex >= _questions.length) {
      return false;
    }

    final currentQuestion = _questions[questionIndex];
    if (currentQuestion.type == QuestionType.multiChoice) {
      return _multiSelectResponses[currentQuestion.id]?.isNotEmpty ?? false;
    }
    return _responses.containsKey(currentQuestion.id);
  }

  Future<void> _completeOnboarding() async {
    // Add country to responses if foreign visitor
    if (_selectedCountry != null) {
      _responses['country'] = _selectedCountry!.name;
    }

    final responses = _responses.entries
        .map((e) => OnboardingResponse(
              questionId: e.key,
              selectedOption: e.value,
            ))
        .toList();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBrown),
      ),
    );

    try {
      final apiService = OnboardingApiService();
      await apiService.submitOnboardingResponse(responses: responses);
      
      // Also update local storage to keep state in sync
      final storage = StorageService();
      await storage.saveOnboardingResponses(responses);
      await storage.setOnboardingCompleted(true);
      
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        
        if (widget.isUpdateMode) {
          Navigator.of(context).pop(); // go back to profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          // Initial onboarding flow
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Getting Started',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryBrown,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${_currentPage + 1}/${_getTotalPages()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  // Progress bar
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / _getTotalPages(),
                    backgroundColor: AppColors.creamWhite,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBrown),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                  ),
                ],
              ),
            ),

            // Questions
            Expanded(
              child: _isLoadingPreloads 
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryBrown),
                  )
                : PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _getTotalPages(),
                    itemBuilder: (context, index) {
                      // Show country page after Q1 if foreign visitor
                      if (_showCountryPage && index == 1) {
                        return _buildCountrySelectionPage();
                      }

                      // Adjust index for actual question
                      final questionIndex = _showCountryPage && index > 1 ? index - 1 : index;
                      if (questionIndex >= _questions.length) {
                        return const SizedBox();
                      }

                      final question = _questions[questionIndex];
                      return _buildQuestionPage(question);
                    },
                  ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    OutlinedButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: AppConstants.animationNormal,
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 100),

                  // Next/Complete button
                  if (_currentPage == _getTotalPages() - 1 && _canProceed())
                    ElevatedButton.icon(
                      onPressed: _completeOnboarding,
                      icon: const Icon(Icons.check),
                      label: const Text('Continue'),
                    )
                  else if (_currentPage < _getTotalPages() - 1 && _canProceed())
                    ElevatedButton.icon(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: AppConstants.animationNormal,
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else
                    const SizedBox(width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(OnboardingQuestion question) {
    if (question.type == QuestionType.multiChoice) {
      return _buildMultiChoiceQuestion(question);
    }
    return _buildSingleChoiceQuestion(question);
  }

  Widget _buildSingleChoiceQuestion(OnboardingQuestion question) {
    final selectedOption = _responses[question.id] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.spacingXl),

          // Question
          Text(
            question.question,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Options
          ...question.options.map((option) {
            final isSelected = selectedOption == option;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
              child: _OptionCard(
                option: option,
                isSelected: isSelected,
                onTap: () => _selectOption(question.id, option),
              ),
            );
          }),

          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }

  Widget _buildMultiChoiceQuestion(OnboardingQuestion question) {
    final selectedOptions = _multiSelectResponses[question.id] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.spacingXl),

          // Question
          Text(
            question.question,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
          ),

          const SizedBox(height: AppConstants.spacingSm),

          Text(
            'Tap to select or deselect',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Tags/Chips
          Wrap(
            spacing: AppConstants.spacingMd,
            runSpacing: AppConstants.spacingMd,
            children: question.options.map((option) {
              final isSelected = selectedOptions.contains(option);

              return _InterestChip(
                label: option,
                isSelected: isSelected,
                onTap: () => _toggleMultiSelect(question.id, option),
              );
            }).toList(),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Selected count
          if (selectedOptions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.creamWhite,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primaryBrown,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Text(
                    '${selectedOptions.length} selected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }

  Widget _buildCountrySelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppConstants.spacingXl),

          // Title
          Text(
            'Select your country',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: AppConstants.spacingSm),

          Text(
            'Help us personalize your experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Country dropdown
          if (_loadingCountries)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingXl),
                child: CircularProgressIndicator(
                  color: AppColors.primaryBrown,
                ),
              ),
            )
          else
            _CountrySearchDropdown(
              countries: _countries,
              selectedCountry: _selectedCountry,
              onCountrySelected: (country) {
                setState(() {
                  _selectedCountry = country;
                });
              },
            ),

          const SizedBox(height: AppConstants.spacingXl),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animationFast,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.lightBrown : AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(
                color: isSelected ? AppColors.primaryBrown : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBrown.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.offWhite : AppColors.textTertiary,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.offWhite : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryBrown,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppConstants.spacingMd),

                // Option text
                Expanded(
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected ? AppColors.offWhite : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animationFast,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingMd,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBrown : AppColors.creamWhite,
              borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              border: Border.all(
                color: isSelected ? AppColors.darkBrown : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBrown.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.offWhite,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppColors.offWhite : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountrySearchDropdown extends StatefulWidget {
  final List<Country> countries;
  final Country? selectedCountry;
  final Function(Country) onCountrySelected;

  const _CountrySearchDropdown({
    required this.countries,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<_CountrySearchDropdown> createState() => _CountrySearchDropdownState();
}

class _CountrySearchDropdownState extends State<_CountrySearchDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<Country> _filteredCountries = [];
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = widget.countries;
      } else {
        _filteredCountries = widget.countries
            .where((country) =>
                country.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected country or search field
        InkWell(
          onTap: () {
            setState(() {
              _isDropdownOpen = !_isDropdownOpen;
            });
          },
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(
                color: _isDropdownOpen ? AppColors.primaryBrown : AppColors.divider,
                width: _isDropdownOpen ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (widget.selectedCountry != null) ...[
                  // Country flag
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.selectedCountry!.flag,
                      width: 32,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.flag, size: 24);
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Text(
                      widget.selectedCountry!.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.public,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Text(
                      'Select your country',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
                Icon(
                  _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        // Dropdown list
        if (_isDropdownOpen) ...[
          const SizedBox(height: AppConstants.spacingSm),

          // Search field
          TextField(
            controller: _searchController,
            onChanged: _filterCountries,
            decoration: InputDecoration(
              hintText: 'Search countries...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _filterCountries('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                borderSide: const BorderSide(color: AppColors.primaryBrown, width: 2),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacingSm),

          // Country list
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: _filteredCountries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    child: Center(
                      child: Text(
                        'No countries found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      final isSelected = widget.selectedCountry?.code == country.code;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            widget.onCountrySelected(country);
                            setState(() {
                              _isDropdownOpen = false;
                              _searchController.clear();
                              _filteredCountries = widget.countries;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingLg,
                              vertical: AppConstants.spacingMd,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.creamWhite : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.divider.withOpacity(0.5),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Country flag
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    country.flag,
                                    width: 32,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.flag, size: 24);
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingMd),
                                // Country name
                                Expanded(
                                  child: Text(
                                    country.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryBrown,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}
