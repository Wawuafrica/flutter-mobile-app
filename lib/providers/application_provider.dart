import '../models/application.dart';
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
// Real-time updates via Pusher are currently handled by listening to relevant Gig events in GigProvider
class ApplicationProvider extends BaseProvider {
  final ApiService _apiService;
  // final PusherService _pusherService; // Pusher is not directly used in this provider anymore

  List<GigApplication> _applications = [];
  List<GigApplication> _userApplications = [];
  GigApplication? _selectedApplication;
  // bool _isSubscribed = false; // No longer needed as this provider doesn't subscribe directly

  // Getters
  List<GigApplication> get applications => _applications;
  List<GigApplication> get userApplications => _userApplications;
  GigApplication? get selectedApplication => _selectedApplication;

  ApplicationProvider({ApiService? apiService, PusherService? pusherService})
      : _apiService = apiService ?? ApiService();
        // _pusherService = pusherService ?? PusherService(); // No longer needed

  /// Fetches applications for a specific gig
  Future<List<GigApplication>> fetchGigApplications(String gigId) async {
    try {
      // Call the API to get applications for a gig
      final response = await _apiService.get<Map<String, dynamic>>(
        '/gigs/\$gigId/applications',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> applicationsJson = response['data'] as List<dynamic>;
        final List<GigApplication> applications = applicationsJson
            .map((json) => GigApplication.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort applications by application date, newest first
        applications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        _applications = applications;

        // No longer subscribing to a specific applications channel here

        return applications;
      } else {
        // Handle empty or invalid response
        _applications = [];
        return [];
      }
    } catch (e) {
      print('Failed to fetch gig applications: \$e');
      return [];
    }
  }

  /// Fetches applications made by the current user
  Future<List<GigApplication>> fetchUserApplications() async {
    try {
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
    } catch (e) {
      print('Failed to fetch user applications: \$e');
      return [];
    }
  }

  /// Creates a new application
  Future<GigApplication?> applyToGig({
    required String gigId,
    required String coverLetter,
    double? proposedBudget,
  }) async {
    try {
      // Create the API request payload
      final Map<String, dynamic> payload = {
        'gig_id': gigId,
        'cover_letter': coverLetter,
      };

      // Add optional fields
      if (proposedBudget != null) payload['proposed_budget'] = proposedBudget;

      // Call the API to create the application
      final response = await _apiService.post<Map<String, dynamic>>(
        '/gigs/\$gigId/applications',
        data: payload,
      );

      if (response.containsKey('data')) {
        final application = GigApplication.fromJson(response['data'] as Map<String, dynamic>);

        // Add to user's applications
        _userApplications.add(application);
        _userApplications.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        return application;
      } else {
        print('Invalid response format when creating application');
        return null;
      }
    } catch (e) {
      print('Failed to apply to gig: \$e');
      return null;
    }
  }

  /// Updates the status of an application
  Future<GigApplication?> updateApplicationStatus({
    required String gigId,
    required String applicationId,
    required String status, // 'accepted', 'rejected'
  }) async {
    try {
      // Call the API to update the application status
      String endpoint;
      if (status == 'accepted') {
        endpoint = '/gigs/\$gigId/applications/\$applicationId/accept';
      } else if (status == 'rejected') {
        endpoint = '/gigs/\$gigId/applications/\$applicationId/reject';
      } else {
        print('Invalid status: \$status');
        return null;
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
        print('Invalid response format when updating application status');
        return null;
      }
    } catch (e) {
      print('Failed to update application status: \$e');
      return null;
    }
  }

  /// Withdraws an application made by the user
  Future<bool> withdrawApplication(String applicationId) async {
    try {
      // Call the API to withdraw the application
      await _apiService.delete<Map<String, dynamic>>(
        '/applications/\$applicationId',
      );

      // Remove from user applications
      _userApplications.removeWhere((app) => app.id == applicationId);

      // Clear selected application if it's the one being withdrawn
      if (_selectedApplication != null && _selectedApplication!.id == applicationId) {
        _selectedApplication = null;
      }

      return true;
    } catch (e) {
      print('Failed to withdraw application: \$e');
      return false;
    }
  }

  /// Sets the selected application
  void selectApplication(String applicationId) {
    // Look in all applications first
    _selectedApplication = _applications.firstWhere(
      (app) => app.id == applicationId,
      orElse: () => _userApplications.firstWhere(
        (app) => app.id == applicationId,
        orElse: () => throw Exception('Application not found: \$applicationId'),
      ),
    );

    notifyListeners();
  }

  /// Clears the selected application
  void clearSelectedApplication() {
    _selectedApplication = null;
    notifyListeners();
  }

  // Removed _subscribeToApplicationsChannel as per new Pusher data

  /// Clears all application data
  void clearAll() {
    _applications = [];
    _userApplications = [];
    _selectedApplication = null;
    // _isSubscribed = false; // No longer needed
    resetState();
  }

  @override
  void dispose() {
    // No longer unsubscribing from a specific applications channel here
    super.dispose();
  }
}
