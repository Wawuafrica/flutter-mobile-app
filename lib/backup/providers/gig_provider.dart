import 'dart:convert';
import '../models/gig.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';

/// GigProvider manages the state of gigs/jobs.
///
/// This provider handles:
/// - Fetching available gigs
/// - Fetching user's posted gigs
/// - Creating new gigs
/// - Updating gig status
/// - Real-time gig updates via Pusher
class GigProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Gig> _availableGigs = [];
  List<Gig> _userGigs = [];
  Gig? _selectedGig;
  bool _isSubscribed = false;

  // Getters
  List<Gig> get availableGigs => _availableGigs;
  List<Gig> get userGigs => _userGigs;
  Gig? get selectedGig => _selectedGig;

  GigProvider({ApiService? apiService, PusherService? pusherService})
    : _apiService = apiService ?? ApiService(),
      _pusherService = pusherService ?? PusherService();

  /// Fetches available gigs with optional filtering
  Future<List<Gig>> fetchAvailableGigs({
    List<String>? categories,
    String? location,
    double? minBudget,
    double? maxBudget,
    List<String>? skills,
  }) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs',
        queryParameters: {
          'status': 'open',
          if (categories != null && categories.isNotEmpty)
            'categories': categories.join(','),
          if (location != null) 'location': location,
          if (minBudget != null) 'min_budget': minBudget.toString(),
          if (maxBudget != null) 'max_budget': maxBudget.toString(),
          if (skills != null && skills.isNotEmpty) 'skills': skills.join(','),
        },
      );

      final List<dynamic> gigsJson = response['gigs'] as List<dynamic>;
      final List<Gig> gigs =
          gigsJson
              .map((json) => Gig.fromJson(json as Map<String, dynamic>))
              .toList();

      // Sort gigs by creation date, newest first
      gigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _availableGigs = gigs;

      // Subscribe to gigs channel if not already subscribed
      if (!_isSubscribed) {
        await _subscribeToGigsChannel();
      }

      return gigs;
    }, errorMessage: 'Failed to fetch available gigs');

    return result ?? [];
  }

  /// Fetches gigs created by a specific user
  Future<List<Gig>> fetchUserGigs(String userId) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.get<Map<String, dynamic>>(
        '/users/$userId/gigs',
      );

      final List<dynamic> gigsJson = response['gigs'] as List<dynamic>;
      final List<Gig> gigs =
          gigsJson
              .map((json) => Gig.fromJson(json as Map<String, dynamic>))
              .toList();

      // Sort gigs by creation date, newest first
      gigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _userGigs = gigs;

      return gigs;
    }, errorMessage: 'Failed to fetch user gigs');

    return result ?? [];
  }

  /// Creates a new gig
  Future<Gig?> createGig({
    required String title,
    required String description,
    required String ownerId,
    required double budget,
    required String currency,
    required DateTime deadline,
    required List<String> categories,
    required List<String> skills,
    required String location,
    Map<String, dynamic>? additionalDetails,
  }) async {
    return await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.post<Map<String, dynamic>>(
        '/gigs',
        data: {
          'title': title,
          'description': description,
          'owner_id': ownerId,
          'budget': budget,
          'currency': currency,
          'deadline': deadline.toIso8601String(),
          'categories': categories,
          'skills': skills,
          'location': location,
          if (additionalDetails != null) ...additionalDetails,
        },
      );

      final gig = Gig.fromJson(response['gig'] as Map<String, dynamic>);

      // Add to user's gigs
      _userGigs.add(gig);
      _userGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return gig;
    }, errorMessage: 'Failed to create gig');
  }

  /// Updates an existing gig
  Future<Gig?> updateGig({
    required String gigId,
    String? title,
    String? description,
    double? budget,
    String? currency,
    DateTime? deadline,
    List<String>? categories,
    List<String>? skills,
    String? location,
    String? status,
    String? assignedTo,
    Map<String, dynamic>? additionalDetails,
  }) async {
    return await handleAsync(() async {
      // TODO: Replace with actual endpoint
      final response = await _apiService.put<Map<String, dynamic>>(
        '/gigs/$gigId',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (budget != null) 'budget': budget,
          if (currency != null) 'currency': currency,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
          if (categories != null) 'categories': categories,
          if (skills != null) 'skills': skills,
          if (location != null) 'location': location,
          if (status != null) 'status': status,
          if (assignedTo != null) 'assigned_to': assignedTo,
          if (additionalDetails != null) ...additionalDetails,
        },
      );

      final updatedGig = Gig.fromJson(response['gig'] as Map<String, dynamic>);

      // Update in available gigs if it exists there
      for (int i = 0; i < _availableGigs.length; i++) {
        if (_availableGigs[i].id == gigId) {
          if (updatedGig.isOpen()) {
            _availableGigs[i] = updatedGig;
          } else {
            // Remove if no longer open
            _availableGigs.removeAt(i);
          }
          break;
        }
      }

      // Update in user gigs if it exists there
      for (int i = 0; i < _userGigs.length; i++) {
        if (_userGigs[i].id == gigId) {
          _userGigs[i] = updatedGig;
          break;
        }
      }

      // Update selected gig if it's the one being updated
      if (_selectedGig != null && _selectedGig!.id == gigId) {
        _selectedGig = updatedGig;
      }

      return updatedGig;
    }, errorMessage: 'Failed to update gig');
  }

  /// Assigns a gig to a user
  Future<bool> assignGig(String gigId, String userId) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      await _apiService.put<Map<String, dynamic>>(
        '/gigs/$gigId/assign',
        data: {'user_id': userId},
      );

      // Update gig in lists
      await updateGig(gigId: gigId, status: 'assigned', assignedTo: userId);

      return true;
    }, errorMessage: 'Failed to assign gig');

    return result ?? false;
  }

  /// Marks a gig as completed
  Future<bool> completeGig(String gigId) async {
    final result = await handleAsync(() async {
      // TODO: Replace with actual endpoint
      await _apiService.put<Map<String, dynamic>>('/gigs/$gigId/complete');

      // Update gig in lists
      await updateGig(gigId: gigId, status: 'completed');

      return true;
    }, errorMessage: 'Failed to complete gig');

    return result ?? false;
  }

  /// Sets the selected gig
  void selectGig(String gigId) {
    // Look in available gigs first
    _selectedGig = _availableGigs.firstWhere(
      (gig) => gig.id == gigId,
      orElse:
          () => _userGigs.firstWhere(
            (gig) => gig.id == gigId,
            orElse: () => throw Exception('Gig not found: $gigId'),
          ),
    );

    notifyListeners();
  }

  /// Clears the selected gig
  void clearSelectedGig() {
    _selectedGig = null;
    notifyListeners();
  }

  /// Subscribes to gigs channel for real-time updates
  Future<void> _subscribeToGigsChannel() async {
    // Channel name: 'gigs'
    const channelName = 'gigs';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to gig created event
      _pusherService.bindToEvent(channelName, 'gig-created', (data) async {
        if (data is String) {
          final gigData = jsonDecode(data) as Map<String, dynamic>;
          final gig = Gig.fromJson(gigData);

          // Add to available gigs if it's open
          if (gig.isOpen()) {
            _availableGigs.add(gig);
            _availableGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            notifyListeners();
          }
        }
      });

      // Bind to gig updated event
      _pusherService.bindToEvent(channelName, 'gig-updated', (data) async {
        if (data is String) {
          final gigData = jsonDecode(data) as Map<String, dynamic>;
          final updatedGig = Gig.fromJson(gigData);

          // Update in available gigs
          for (int i = 0; i < _availableGigs.length; i++) {
            if (_availableGigs[i].id == updatedGig.id) {
              // Remove if no longer open
              if (!updatedGig.isOpen()) {
                _availableGigs.removeAt(i);
              } else {
                _availableGigs[i] = updatedGig;
              }
              notifyListeners();
              break;
            }
          }

          // Update in user gigs
          for (int i = 0; i < _userGigs.length; i++) {
            if (_userGigs[i].id == updatedGig.id) {
              _userGigs[i] = updatedGig;
              notifyListeners();
              break;
            }
          }

          // Update selected gig if it's the one being updated
          if (_selectedGig != null && _selectedGig!.id == updatedGig.id) {
            _selectedGig = updatedGig;
            notifyListeners();
          }
        }
      });
    }
  }

  /// Clears all gig data
  void clearAll() {
    _availableGigs = [];
    _userGigs = [];
    _selectedGig = null;
    _isSubscribed = false;
    resetState();
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      _pusherService.unsubscribeFromChannel('gigs');
    }
    super.dispose();
  }
}
