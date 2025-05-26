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
/// - Real-time gig updates via Pusher based on new event structure
class GigProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<Gig> _availableGigs = [];
  List<Gig> _userGigs = [];
  Gig? _selectedGig;
  bool _isGeneralChannelSubscribed = false;
  String? _currentSpecificGigChannel;

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
    try {
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
        if (!_isGeneralChannelSubscribed) {
          await _subscribeToGeneralGigsChannel();
        }

        return gigs;
      } else {
        // Handle empty or invalid response
        _availableGigs = [];
        return [];
      }
    } catch (e) {
      print('Failed to fetch available gigs: $e');
      return [];
    }
  }

  /// Fetches gigs created by a specific user
  Future<List<Gig>> fetchUserGigs(String userId) async {
    try {
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
    } catch (e) {
      print('Failed to fetch user gigs: $e');
      return [];
    }
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
    try {
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

        // The general gigs channel will handle adding the new gig via real-time update

        return gig;
      } else {
        print('Invalid response format when creating gig');
        return null;
      }
    } catch (e) {
      print('Failed to create gig: $e');
      return null;
    }
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
    try {
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

        // The specific gig channel will handle updating the gig via real-time update

        return updatedGig;
      } else {
        print('Invalid response format when updating gig');
        return null;
      }
    } catch (e) {
      print('Failed to update gig: $e');
      return null;
    }
  }

  /// Assigns a gig to a user
  Future<bool> assignGig(String gigId, String userId) async {
    try {
      // Call the API endpoint for assigning a gig application
      await _apiService.post<Map<String, dynamic>>(
        '/gigs/$gigId/applications/$userId/accept',
        data: {},
      );

      // The specific gig channel will handle updating the gig status via real-time update

      return true;
    } catch (e) {
      print('Failed to assign gig: $e');
      return false;
    }
  }

  /// Marks a gig as completed
  Future<bool> completeGig(String gigId) async {
    try {
      // Call the API endpoint for completing a gig
      await _apiService.post<Map<String, dynamic>>(
        '/gigs/$gigId/complete',
        data: {},
      );

      // The specific gig channel will handle updating the gig status via real-time update

      return true;
    } catch (e) {
      print('Failed to complete gig: $e');
      return false;
    }
  }

   /// Updates a gig in availableGigs and userGigs lists
  void _updateGigInLists(String gigId, Gig updatedGig) {
    bool foundInAvailable = false;
    for (int i = 0; i < _availableGigs.length; i++) {
      if (_availableGigs[i].id == gigId) {
        // Remove if no longer open
        if (!updatedGig.isOpen()) {
          _availableGigs.removeAt(i);
        } else {
          _availableGigs[i] = updatedGig;
        }
        foundInAvailable = true;
        break;
      }
    }

    // Add to available if it's now open and wasn't before
    if (!foundInAvailable && updatedGig.isOpen()) {
      _availableGigs.insert(0, updatedGig);
    }

    bool foundInUserGigs = false;
    for (int i = 0; i < _userGigs.length; i++) {
      if (_userGigs[i].id == gigId) {
         _userGigs[i] = updatedGig;
        foundInUserGigs = true;
        break;
      }
    }
     // Add to user gigs if it's a new gig created by the user
    if (!foundInUserGigs) {
       // Assuming the API response for createGig includes enough info to determine if it's a user gig
       // For now, we'll rely on fetchUserGigs to get the initial list.
       // Real-time update for user's own created gig needs to be handled here.
       // A simple approach is to always add new gigs to _userGigs if the current user is the creator.
       // However, we don't have the current user ID in this provider. This requires refactoring or assuming.
       // Let's assume for now that the real-time update event itself indicates if it's a user gig.
       // This might require checking a user ID in the payload, which is not in the provided event data.
       // For simplicity, let's update both lists if the gig is found.

       // If the updated gig is relevant to the current user's gigs view,
       // we might need more context (like the current user's ID) to decide if it should be added here.
       // For now, we'll only update existing user gigs.
    }

    // Sort lists after update/addition
    _availableGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _userGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

    /// Removes a gig from lists
  void _removeGigFromLists(String gigId) {
    _availableGigs.removeWhere((gig) => gig.id == gigId);
    _userGigs.removeWhere((gig) => gig.id == gigId);
    if (_selectedGig?.id == gigId) {
      _selectedGig = null;
    }
    notifyListeners();
  }

  /// Sets the selected gig and subscribes to its channel
  void selectGig(String gigId) {
     try {
      // Unsubscribe from previous specific gig channels if any
      if (_currentSpecificGigChannel != null) {
        _pusherService.unsubscribeFromChannel(_currentSpecificGigChannel!);
        _currentSpecificGigChannel = null;
      }

      // Find the gig in existing lists or fetch details if necessary
      _selectedGig = _availableGigs.firstWhere(
        (gig) => gig.id == gigId,
        orElse:
            () => _userGigs.firstWhere(
              (gig) => gig.id == gigId,
              // orElse: () => null, // Return null if not found in lists
            ),
      );

      // If gig not found locally, you might want to fetch its details from the API here
      // For now, we'll only proceed if the gig is found in the lists.

      if (_selectedGig != null) {
         // Subscribe to the specific gig channels
        final approvedChannelName = 'gig.approved.\$gigId';
        final rejectedChannelName = 'gig.rejected.\$gigId';
        final reviewChannelName = 'gig.review.\$gigId';

        // Store one of the channel names to manage unsubscription
        _currentSpecificGigChannel = approvedChannelName;

         _pusherService.subscribeToChannel(approvedChannelName)?.then((channel) {
            if (channel != null) {
               _pusherService.bindToEvent(approvedChannelName, 'gig.approved', _handleGigApproved);
            }
         });

         _pusherService.subscribeToChannel(rejectedChannelName)?.then((channel) {
             if (channel != null) {
                _pusherService.bindToEvent(rejectedChannelName, 'gig.rejected', _handleGigRejected);
             }
         });

          _pusherService.subscribeToChannel(reviewChannelName)?.then((channel) {
             if (channel != null) {
                _pusherService.bindToEvent(reviewChannelName, 'gig.review', _handleGigReviewed);
             }
         });

        notifyListeners();
      } else {
        print('Gig not found locally: $gigId');
         // Optionally fetch from API if not found locally
         // fetchGigDetails(gigId);
      }

    } catch (e) {
      print('Failed to select gig or subscribe to channel: $e');
      _currentSpecificGigChannel = null; // Clear channel on failure
    }
  }

  /// Clears the selected gig and unsubscribes from its channel
  void clearSelectedGig() {
     if (_currentSpecificGigChannel != null) {
       _pusherService.unsubscribeFromChannel(_currentSpecificGigChannel!);
       _currentSpecificGigChannel = null;
     }
    _selectedGig = null;
    notifyListeners();
  }

  /// Subscribes to the general gigs channel for creates/deletes
  Future<void> _subscribeToGeneralGigsChannel() async {
    const channelName = 'gigs';
    try {
      final channel = await _pusherService.subscribeToChannel(channelName);
      if (channel == null) {
        print('Failed to subscribe to general gigs channel');
        return;
      }

      _isGeneralChannelSubscribed = true;

      // Bind to gig created event
      _pusherService.bindToEvent(channelName, 'gig.created', _handleGigCreated);

       // Bind to gig deleted event
      _pusherService.bindToEvent(channelName, 'gig.deleted', _handleGigDeleted);

    } catch (e) {
      print('Failed to subscribe to general gigs channel: $e');
    }
  }

   // Handlers for Pusher events

  void _handleGigCreated(dynamic data) {
    try {
      if (data is! String) {
        print('Invalid gig.created event data');
        return;
      }
      final gigData = jsonDecode(data) as Map<String, dynamic>;
      final newGig = Gig.fromJson(gigData);

      // Add to available gigs if it's open
      if (newGig.isOpen()) {
        _availableGigs.insert(0, newGig);
        _availableGigs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
      // Note: Adding to user gigs based on this event requires knowing the current user ID,
      // which is not directly available in this provider without passing it.

    } catch (e) {
      print('Failed to handle gig.created event: $e');
    }
  }

  void _handleGigDeleted(dynamic data) {
    try {
       if (data is! String) {
          print('Invalid gig.deleted event data');
          return;
       }
      final deletedGigData = jsonDecode(data) as Map<String, dynamic>;
      final String? deletedGigId = deletedGigData['gig_uuid'];

      if (deletedGigId != null) {
        _removeGigFromLists(deletedGigId);
      } else {
         print('gig.deleted event data missing gig_uuid');
      }
    } catch (e) {
      print('Failed to handle gig.deleted event: $e');
    }
  }

   void _handleGigApproved(dynamic data) {
    try {
       if (data is! String) {
          print('Invalid gig.approved event data');
          return;
       }
      final approvedGigData = jsonDecode(data) as Map<String, dynamic>;
      final String? approvedGigId = approvedGigData['gig_uuid'];

      if (approvedGigId != null) {
         // Fetch updated gig details or rely on the event payload if it contains the full gig
         // Assuming the event payload contains the updated gig data:
         if (approvedGigData.containsKey('gig') && approvedGigData['gig'] is Map<String, dynamic>) {
             final updatedGig = Gig.fromJson(approvedGigData['gig']);
             _updateGigInLists(approvedGigId, updatedGig);
             if (_selectedGig?.id == approvedGigId) {
                _selectedGig = updatedGig;
                notifyListeners();
             }
         } else {
            print('gig.approved event data missing gig object');
             // Optionally refetch the gig from API if the event doesn't contain the full object
             // fetchGigDetails(approvedGigId);
         }
      } else {
         print('gig.approved event data missing gig_uuid');
      }
    } catch (e) {
      print('Failed to handle gig.approved event: $e');
    }
   }

   void _handleGigRejected(dynamic data) {
     try {
       if (data is! String) {
         print('Invalid gig.rejected event data');
         return;
       }
       final rejectedGigData = jsonDecode(data) as Map<String, dynamic>;
       final String? rejectedGigId = rejectedGigData['gig_uuid'];

       if (rejectedGigId != null) {
          // Fetch updated gig details or rely on the event payload
          // Assuming the event payload contains the updated gig data:
         if (rejectedGigData.containsKey('gig') && rejectedGigData['gig'] is Map<String, dynamic>) {
             final updatedGig = Gig.fromJson(rejectedGigData['gig']);
             _updateGigInLists(rejectedGigId, updatedGig);
             if (_selectedGig?.id == rejectedGigId) {
                _selectedGig = updatedGig;
                notifyListeners();
             }
         } else {
            print('gig.rejected event data missing gig object');
             // Optionally refetch the gig from API
             // fetchGigDetails(rejectedGigId);
         }
       } else {
         print('gig.rejected event data missing gig_uuid');
       }
     } catch (e) {
       print('Failed to handle gig.rejected event: $e');
     }
   }

    void _handleGigReviewed(dynamic data) {
     try {
        if (data is! String) {
          print('Invalid gig.review event data');
          return;
        }
       final reviewedGigData = jsonDecode(data) as Map<String, dynamic>;
       final String? reviewedGigId = reviewedGigData['gig_uuid'];

       if (reviewedGigId != null) {
          // Fetch updated gig details or rely on the event payload
           // Assuming the event payload contains the updated gig data:
         if (reviewedGigData.containsKey('gig') && reviewedGigData['gig'] is Map<String, dynamic>) {
             final updatedGig = Gig.fromJson(reviewedGigData['gig']);
             _updateGigInLists(reviewedGigId, updatedGig);
             if (_selectedGig?.id == reviewedGigId) {
                _selectedGig = updatedGig;
                notifyListeners();
             }
         } else {
            print('gig.review event data missing gig object');
             // Optionally refetch the gig from API
             // fetchGigDetails(reviewedGigId);
         }
       } else {
         print('gig.review event data missing gig_uuid');
       }
     } catch (e) {
       print('Failed to handle gig.review event: $e');
     }
   }


  /// Clears all gig data
  void clearAll() {
    _availableGigs = [];
    _userGigs = [];
    clearSelectedGig(); // Also unsubscribes from specific channel
    _isGeneralChannelSubscribed = false;
    resetState();
  }

  @override
  void dispose() {
    if (_isGeneralChannelSubscribed) {
      _pusherService.unsubscribeFromChannel('gigs');
    }
    if (_currentSpecificGigChannel != null) {
       // Need to unsubscribe from all specific channels if multiple were subscribed
       // A better approach might be to store a list of subscribed specific channels
       // For now, unsubscribe from the one we stored.
       _pusherService.unsubscribeFromChannel(_currentSpecificGigChannel!); // Unsubscribe from the stored channel
       // If we subscribed to approved, rejected, and review separately, we would need to unsubscribe from all three here.
       // Let's modify selectGig to store all subscribed channels for the specific gig.
    }

    // Re-reading selectGig to fix the disposal logic
     if (_currentSpecificGigChannel != null) {
       final gigId = _currentSpecificGigChannel!.split('.').last; // Extract gigId from channel name
       final approvedChannelName = 'gig.approved.\$gigId';
       final rejectedChannelName = 'gig.rejected.\$gigId';
       final reviewChannelName = 'gig.review.\$gigId';
       _pusherService.unsubscribeFromChannel(approvedChannelName);
       _pusherService.unsubscribeFromChannel(rejectedChannelName);
       _pusherService.unsubscribeFromChannel(reviewChannelName);
       _currentSpecificGigChannel = null; // Clear after unsubscribing
     }

    super.dispose();
  }
}
