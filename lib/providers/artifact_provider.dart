import 'package:flutter/foundation.dart';
import '../models/artifact.dart';
import '../models/api_error.dart';
import '../services/artifact_service.dart';

class ArtifactProvider with ChangeNotifier {
  final ArtifactService _artifactService = ArtifactService();

  List<Artifact> _artifacts = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  final int _pageSize = 10;

  List<Artifact> get artifacts => _artifacts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get hasMore => _currentPage < _totalPages - 1;

  Future<void> fetchArtifacts({int page = 0, bool refresh = false}) async {
    if (refresh) {
      _artifacts.clear();
      _currentPage = 0;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _artifactService.getArtifacts(
        page: page,
        size: _pageSize,
      );

      if (refresh) {
        _artifacts = response.content;
      } else {
        _artifacts.addAll(response.content);
      }

      _currentPage = response.number;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;

      _isLoading = false;
      notifyListeners();
    } on ApiError catch (e) {
      _error = e.displayMessage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load artifacts. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _isLoading) return;
    await fetchArtifacts(page: _currentPage + 1);
  }

  Future<void> refreshArtifacts() async {
    await fetchArtifacts(page: 0, refresh: true);
  }

  Future<bool> createArtifact(Artifact artifact) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdArtifact = await _artifactService.createArtifact(artifact);
      _artifacts.insert(0, createdArtifact);
      _totalElements++;

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.displayMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to create artifact. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateArtifact(int id, Artifact artifact) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedArtifact = await _artifactService.updateArtifact(id, artifact);
      final index = _artifacts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _artifacts[index] = updatedArtifact;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.displayMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update artifact. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteArtifact(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _artifactService.deleteArtifact(id);
      _artifacts.removeWhere((a) => a.id == id);
      _totalElements--;

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.displayMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to delete artifact. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> searchArtifacts(String searchTerm) async {
    if (searchTerm.isEmpty) {
      await refreshArtifacts();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _artifactService.searchArtifacts(
        searchTerm,
        page: 0,
        size: _pageSize,
      );

      _artifacts = response.content;
      _currentPage = response.number;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;

      _isLoading = false;
      notifyListeners();
    } on ApiError catch (e) {
      _error = e.displayMessage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to search artifacts. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns up to 10 artifacts matching the given category (client-side filter).
  List<Artifact> getArtifactsByCategory(String category) {
    return _artifacts
        .where((a) => a.category.toLowerCase() == category.toLowerCase())
        .take(10)
        .toList();
  }

  /// Returns up to 10 artifacts related to a map location name.
  /// Splits the location name into keywords and matches against artifact
  /// category or name (case-insensitive contains).
  List<Artifact> getArtifactsForLocation(String locationName) {
    final keywords = locationName
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    if (keywords.isEmpty) return [];

    return _artifacts.where((a) {
      final cat = a.category.toLowerCase();
      final name = a.name.toLowerCase();
      return keywords.any((k) => cat.contains(k) || name.contains(k));
    }).take(10).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
