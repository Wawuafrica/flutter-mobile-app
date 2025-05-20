import 'dart:convert';
import '../models/application.dart';
import '../models/gig.dart';
import '../providers/base_provider.dart';
import '../services/api_service.dart';
import '../services/pusher_service.dart';

/// ApplicationProvider manages the state of gig applications.
///
/// This provider handles:
/// - Fetching applications for a gig
/// - Fetching applications made by the current user
/// - Creating new applications
/// - Updating application status
/// - Real-time updates via Pusher
class ApplicationProvider extends BaseProvider {
  final ApiService _apiService;
  final PusherService _pusherService;

  List<GigApplication> _applications = [];
  List<GigApplication> _userApplications = [];
  GigApplication? _selectedApplication;
  bool _isSubscribed = false;

  // Getters
  List<GigApplication> get applications => _applications;
  List<GigApplication> get userApplications => _userApplications;
  GigApplication? get selectedApplication => _selectedApplication;

  ApplicationProvider({ApiService? apiService, PusherService? pusherService})
      : _apiService = apiService ?? ApiService(),
        _pusherService = pusherService ?? PusherService();

  /// Fetches applications for a specific gig
  Future<List<GigApplication>> fetchGigApplications(String gigId) async {
    final result = await handleAsync(() async {
      // Call the API to get applications for a gig
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs/$gigId/applications',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> applicationsJson = response['data'] as List<dynamic>;
        final List<GigApplication> applications = applicationsJson
            .map((json) => GigApplication.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort applications by application date, newest first
        applications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        _applications = applications;

        // Subscribe to applications channel if not already subscribed
        if (!_isSubscribed) {
          await _subscribeToApplicationsChannel();
        }

        return applications;
      } else {
        // Handle empty or invalid response
        _applications = [];
        return [];
      }
    }, errorMessage: 'Failed to fetch gig applications');

    return result ?? [];
  }

  /// Fetches applications made by the current user
  Future<List<GigApplication>> fetchUserApplications() async {
    final result = await handleAsync(() async {
      // Call the API to get user's applications
      final response = await _apiService.get<Map<String, dynamic>>(
        '/applications/my-applications',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> applicationsJson = response['data'] as List<dynamic>;
        final List<GigApplication> applications = applicationsJson
            .map((json) => GigApplication.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort applications by application date, newest first
        applications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        _userApplications = applications;

        return applications;
      } else {
        // Handle empty or invalid response
        _userApplications = [];
        return [];
      }
    }, errorMessage: 'Failed to fetch user applications');

    return result ?? [];
  }

  /// Creates a new application
  Future<GigApplication?> applyToGig({
    required String gigId,
    required String coverLetter,
    double? proposedBudget,
  }) async {
    return await handleAsync(() async {
      // Create the API request payload
      final Map<String, dynamic> payload = {
        'gig_id': gigId,
        'cover_letter': coverLetter,
      };

      // Add optional fields
      if (proposedBudget != null) payload['proposed_budget'] = proposedBudget;

      // Call the API to create the application
      final response = await _apiService.post<Map<String, dynamic>>(
        '/gigs/$gigId/applications',
        data: payload,
      );

      if (response.containsKey('data')) {
        final application = GigApplication.fromJson(response['data'] as Map<String, dynamic>);

        // Add to user's applications
        _userApplications.add(application);
        _userApplications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        return application;
      } else {
        throw Exception('Invalid response format when creating application');
      }
    }, errorMessage: 'Failed to apply to gig');
  }

  /// Updates the status of an application
  Future<GigApplication?> updateApplicationStatus({
    required String gigId,
    required String applicationId,
    required String status, // 'accepted', 'rejected'
  }) async {
    return await handleAsync(() async {
      // Call the API to update the application status
      String endpoint;
      if (status == 'accepted') {
        endpoint = '/gigs/$gigId/applications/$applicationId/accept';
      } else if (status == 'rejected') {
        endpoint = '/gigs/$gigId/applications/$applicationId/reject';
      } else {
        throw Exception('Invalid status: $status');
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        endpoint,
        data: {},
      );

      if (response.containsKey('data')) {
        final updatedApplication = GigApplication.fromJson(response['data'] as Map<String, dynamic>);

        // Update in applications list if present
        for (int i = 0; i < _applications.length; i++) {
          if (_applications[i].id == applicationId) {
            _applications[i] = updatedApplication;
            break;
          }
        }

        // Update in user applications if present
        for (int i = 0; i < _userApplications.length; i++) {
          if (_userApplications[i].id == applicationId) {
            _userApplications[i] = updatedApplication;
            break;
          }
        }

        // Update selected application if it's the one being updated
        if (_selectedApplication != null && _selectedApplication!.id == applicationId) {
          _selectedApplication = updatedApplication;
        }

        return updatedApplication;
      } else {
        throw Exception('Invalid response format when updating application status');
      }
    }, errorMessage: 'Failed to update application status');
  }

  /// Withdraws an application made by the user
  Future<bool> withdrawApplication(String applicationId) async {
    final result = await handleAsync(() async {
      // Call the API to withdraw the application
      await _apiService.delete<Map<String, dynamic>>(
        '/applications/$applicationId',
      );

      // Remove from user applications
      _userApplications.removeWhere((app) => app.id == applicationId);

      // Clear selected application if it's the one being withdrawn
      if (_selectedApplication != null && _selectedApplication!.id == applicationId) {
        _selectedApplication = null;
      }

      return true;
    }, errorMessage: 'Failed to withdraw application');

    return result ?? false;
  }

  /// Sets the selected application
  void selectApplication(String applicationId) {
    // Look in all applications first
    _selectedApplication = _applications.firstWhere(
      (app) => app.id == applicationId,
      orElse: () => _userApplications.firstWhere(
        (app) => app.id == applicationId,
        orElse: () => throw Exception('Application not found: $applicationId'),
      ),
    );

    notifyListeners();
  }

  /// Clears the selected application
  void clearSelectedApplication() {
    _selectedApplication = null;
    notifyListeners();
  }

  /// Subscribes to applications channel for real-time updates
  Future<void> _subscribeToApplicationsChannel() async {
    // Channel for applications
    const channelName = 'applications';

    final channel = await _pusherService.subscribeToChannel(channelName);
    if (channel != null) {
      _isSubscribed = true;

      // Bind to application created event
      _pusherService.bindToEvent(channelName, 'ApplicationCreated', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('application') && jsonData['application'] is Map<String, dynamic>) {
            final appData = jsonData['application'] as Map<String, dynamic>;
            final application = GigApplication.fromJson(appData);

            // Add to applications if it's for a gig we're currently viewing
            if (_applications.isNotEmpty && _applications.first.gigId == application.gigId) {
              _applications.add(application);
              _applications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
              notifyListeners();
            }
          }
        }
      });

      // Bind to application updated event
      _pusherService.bindToEvent(channelName, 'ApplicationUpdated', (data) async {
        if (data is String) {
          final jsonData = jsonDecode(data) as Map<String, dynamic>;
          
          if (jsonData.containsKey('application') && jsonData['application'] is Map<String, dynamic>) {
            final appData = jsonData['application'] as Map<String, dynamic>;
            final updatedApplication = GigApplication.fromJson(appData);

            // Update in applications list
            for (int i = 0; i < _applications.length; i++) {
              if (_applications[i].id == updatedApplication.id) {
                _applications[i] = updatedApplication;
                notifyListeners();
                break;
              }
            }

            // Update in user applications
            for (int i = 0; i < _userApplications.length; i++) {
              if (_userApplications[i].id == updatedApplication.id) {
                _userApplications[i] = updatedApplication;
                notifyListeners();
                break;
              }
            }

            // Update selected application if it's the one being updated
            if (_selectedApplication != null && _selectedApplication!.id == updatedApplication.id) {
              _selectedApplication = updatedApplication;
              notifyListeners();
            }
          }
        }
      });
    }
  }

  /// Clears all application data
  void clearAll() {
    _applications = [];
    _userApplications = [];
    _selectedApplication = null;
    _isSubscribed = false;
    resetState();
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      _pusherService.unsubscribeFromChannel('applications');
    }
    super.dispose();
  }
}
