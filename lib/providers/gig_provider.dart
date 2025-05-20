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
    String? serviceId,
  }) async {
    final result = await handleAsync(() async {
      // Build query parameters
      final Map<String, dynamic> queryParams = {
        // Default to first page, 20 items per page
        'page': 1,
        'per_page': 20,
        
        // Optional filters
        if (categories != null && categories.isNotEmpty)
          'category': categories.first, // API uses single category filter
        if (location != null && location.isNotEmpty) 
          'location': location,
        if (minBudget != null) 
          'min_budget': minBudget.toString(),
        if (maxBudget != null) 
          'max_budget': maxBudget.toString(),
        if (skills != null && skills.isNotEmpty) 
          'skills': skills.join(','),
        if (serviceId != null && serviceId.isNotEmpty)
          'service_id': serviceId,
      };
      
      // Call the API
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs',
        queryParameters: queryParams,
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;
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
      } else {
        // Handle empty or invalid response
        _availableGigs = [];
        return [];
      }
    }, errorMessage: 'Failed to fetch available gigs');

    final List<Gig> typedResult = result?.cast<Gig>() ?? []; return typedResult;
  }

  /// Fetches gigs created by a specific user
  Future<List<Gig>> fetchUserGigs(String userId) async {
    final result = await handleAsync(() async {
      // Get my gigs
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs/my-gigs',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> gigsJson = response['data'] as List<dynamic>;
        final List<Gig> gigs =
            gigsJson
                .map((json) => Gig.fromJson(json as Map<String, dynamic>))
                .toList();

        // Sort gigs by creation date, newest first
        gigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _userGigs = gigs;

        return gigs;
      } else {
        // Handle empty or invalid response
        _userGigs = [];
        return [];
      }
    }, errorMessage: 'Failed to fetch user gigs');

    final List<Gig> typedResult = result?.cast<Gig>() ?? []; return typedResult;
  }

  /// Creates a new gig
  Future<Gig?> createGig({
    required String title,
    required String description,
    required String serviceId, // The selected service ID (level 3 category)
    required double budget,
    required String currency,
    required DateTime deadline,
    required String location,
    String? categoryId, // Top level category (optional if serviceId is provided)
    String? subCategoryId, // Middle level category (optional if serviceId is provided)
    List<String>? skills,
    Map<String, dynamic>? additionalDetails,
  }) async {
    return await handleAsync(() async {
      // Create the API request payload
      final Map<String, dynamic> payload = {
        'title': title,
        'description': description,
        'service_id': serviceId, // This is the required identifier for the specific service
        'budget': budget,
        'currency': currency,
        'deadline': deadline.toIso8601String(),
        'location': location,
      };
      
      // Add optional fields
      if (categoryId != null) payload['category_id'] = categoryId;
      if (subCategoryId != null) payload['subcategory_id'] = subCategoryId;
      if (skills != null && skills.isNotEmpty) payload['skills'] = skills;
      if (additionalDetails != null) payload.addAll(additionalDetails);
      
      // Call the API
      final response = await _apiService.post<Map<String, dynamic>>(
        '/gigs',
        data: payload,
      );

      if (response.containsKey('data')) {
        final gig = Gig.fromJson(response['data'] as Map<String, dynamic>);

        // Add to user's gigs
        _userGigs.add(gig);
        _userGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return gig;
      } else {
        throw Exception('Invalid response format when creating gig');
      }
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
    String? serviceId,
    String? categoryId,
    String? subCategoryId,
    List<String>? skills,
    String? location,
    String? status,
    String? assignedTo,
    Map<String, dynamic>? additionalDetails,
  }) async {
    return await handleAsync(() async {
      // Build the update payload with only fields that need to be updated
      final Map<String, dynamic> updateData = {};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (budget != null) updateData['budget'] = budget;
      if (currency != null) updateData['currency'] = currency;
      if (deadline != null) updateData['deadline'] = deadline.toIso8601String();
      if (serviceId != null) updateData['service_id'] = serviceId;
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (subCategoryId != null) updateData['subcategory_id'] = subCategoryId;
      if (skills != null) updateData['skills'] = skills;
      if (location != null) updateData['location'] = location;
      if (status != null) updateData['status'] = status;
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (additionalDetails != null) updateData.addAll(additionalDetails);
      
      // Call the API to update the gig
      final response = await _apiService.put<Map<String, dynamic>>(
        '/gigs/$gigId',
        data: updateData,
      );

      if (response.containsKey('data')) {
        final updatedGig = Gig.fromJson(response['data'] as Map<String, dynamic>);

        // Update in available gigs if present
        _availableGigs = _availableGigs.map((gig) {
          if (gig.id == gigId) {
            return updatedGig;
          }
          return gig;
        }).toList();

        // Update in user gigs if present
        _userGigs = _userGigs.map((gig) {
          if (gig.id == gigId) {
            return updatedGig;
          }
          return gig;
        }).toList();

        // Update selected gig if it's the one being edited
        if (_selectedGig != null && _selectedGig!.id == gigId) {
          _selectedGig = updatedGig;
        }

        return updatedGig;
      }
      throw Exception('Invalid response format when updating gig');
    }, errorMessage: 'Failed to update gig');
  }

  /// Assigns a gig to a user
  Future<bool> assignGig(String gigId, String userId) async {
    final result = await handleAsync(() async {
      // Call the API endpoint for assigning a gig application
      await _apiService.post<Map<String, dynamic>>(
        '/gigs/$gigId/applications/$userId/accept',
        data: {},
      );

      // Update gig in lists to reflect assignment
      await updateGig(gigId: gigId, status: 'assigned', assignedTo: userId);

      return true;
    }, errorMessage: 'Failed to assign gig');

    return result ?? false;
  }

  /// Marks a gig as completed
  Future<bool> completeGig(String gigId) async {
    final result = await handleAsync(() async {
      // Call the API endpoint for completing a gig
      await _apiService.post<Map<String, dynamic>>(
        '/gigs/$gigId/complete',
        data: {},
      );

      // Update gig in lists to reflect completion
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
    // Use the gigs channel as specified in the API document
    const channelName = 'gigs';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to gig created event
      _pusherService.bindToEvent(channelName, 'GigCreated', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('gig') && jsonData['gig'] is Map<String, dynamic>) {
            final gigData = jsonData['gig'] as Map<String, dynamic>;
            final gig = Gig.fromJson(gigData);

            // Add to available gigs if it's open
            if (gig.isOpen()) {
              _availableGigs.add(gig);
              _availableGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              notifyListeners();
            }
          }
        }
      });

      // Bind to gig updated event
      _pusherService.bindToEvent(channelName, 'GigUpdated', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('gig') && jsonData['gig'] is Map<String, dynamic>) {
            final gigData = jsonData['gig'] as Map<String, dynamic>;
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
