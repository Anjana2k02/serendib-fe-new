import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/artifact_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/artifact.dart';
import '../../widgets/category_artifacts_sheet.dart';

class ArtifactsListScreen extends StatefulWidget {
  const ArtifactsListScreen({super.key});

  @override
  State<ArtifactsListScreen> createState() => _ArtifactsListScreenState();
}

class _ArtifactsListScreenState extends State<ArtifactsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtifactProvider>().fetchArtifacts();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final artifactProvider = context.read<ArtifactProvider>();
      if (!artifactProvider.isLoading && artifactProvider.hasMore) {
        artifactProvider.loadMore();
      }
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<ArtifactProvider>().refreshArtifacts();
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      context.read<ArtifactProvider>().refreshArtifacts();
    } else {
      context.read<ArtifactProvider>().searchArtifacts(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Artifacts'),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: AppColors.offWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search artifacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: _handleSearch,
            ),
          ),

          // Artifacts List
          Expanded(
            child: Consumer<ArtifactProvider>(
              builder: (context, artifactProvider, child) {
                if (artifactProvider.isLoading && artifactProvider.artifacts.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBrown,
                    ),
                  );
                }

                if (artifactProvider.error != null && artifactProvider.artifacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        Text(
                          artifactProvider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        ElevatedButton(
                          onPressed: _handleRefresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (artifactProvider.artifacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.museum_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        Text(
                          'No artifacts found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        const Text(
                          'Start by adding your first artifact',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.primaryBrown,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    itemCount: artifactProvider.artifacts.length +
                        (artifactProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= artifactProvider.artifacts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppConstants.spacingMd),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryBrown,
                            ),
                          ),
                        );
                      }

                      final artifact = artifactProvider.artifacts[index];
                      return ArtifactCard(artifact: artifact);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Only show FAB for ADMIN or CURATOR roles
          if (authProvider.user?.role == 'ADMIN' ||
              authProvider.user?.role == 'CURATOR') {
            return FloatingActionButton(
              onPressed: () {
                // Navigate to create artifact screen
                Navigator.of(context).pushNamed('/artifacts/create');
              },
              backgroundColor: AppColors.primaryBrown,
              child: const Icon(Icons.add, color: AppColors.offWhite),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class ArtifactCard extends StatelessWidget {
  final Artifact artifact;

  const ArtifactCard({super.key, required this.artifact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      elevation: AppConstants.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/artifacts/detail',
            arguments: artifact,
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon/Image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: const Icon(
                  Icons.museum,
                  color: AppColors.primaryBrown,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    GestureDetector(
                      onTap: () {
                        final filtered = context
                            .read<ArtifactProvider>()
                            .getArtifactsByCategory(artifact.category);
                        showCategoryArtifactsSheet(
                            context, artifact.category, filtered);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            artifact.category,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primaryBrown,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primaryBrown,
                                    ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.expand_less,
                            size: 14,
                            color: AppColors.primaryBrown,
                          ),
                        ],
                      ),
                    ),
                    if (artifact.description != null &&
                        artifact.description!.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        artifact.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacingXs),
                    Row(
                      children: [
                        if (artifact.isOnDisplay)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingSm,
                              vertical: AppConstants.spacingXs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                            ),
                            child: Text(
                              'On Display',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        if (artifact.originCountry != null) ...[
                          if (artifact.isOnDisplay)
                            const SizedBox(width: AppConstants.spacingSm),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            artifact.originCountry!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
