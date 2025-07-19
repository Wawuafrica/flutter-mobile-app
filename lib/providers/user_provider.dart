import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio; // Still needed for MultipartFile
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/pusher_service.dart';

// UserProvider does not extend BaseProvider in the current structure,
// but it implements similar state management methods.
class UserProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  final PusherService _pusherService;
  final Logger _logger = Logger();

  User? _currentUser;
  User? _viewedUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  bool _hasError = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _userChannelName;
  bool _isSubscribed = false;

  UserProvider({
    required ApiService apiService,
    required AuthService authService,
    required PusherService pusherService,
  }) : _apiService = apiService,
       _authService = authService,
       _pusherService = pusherService {
    _currentUser = _authService.currentUser;
    if (_currentUser != null && _authService.isAuthenticated) {
      _subscribeToUserChannel();
    }
  }

  User? get currentUser => _currentUser;
  User? get viewedUser => _viewedUser;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  bool get isAuthenticated => _authService.isAuthenticated;

  void setLoading() {
    isLoading = true;
  }

  void setError(String message) {
    isLoading = false;
    _hasError = true;
    _errorMessage = message;
    _isSuccess = false;
    notifyListeners();
  }

  void setSuccess() {
    isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = true;
    notifyListeners();
  }

  void resetState() {
    isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    setLoading();
    try {
      _currentUser = await _authService.signIn(email, password);
      if (_currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Login failed: User object is null.');
      }
    } catch (e) {
      // Catch generic Exception
      _logger.e('An unexpected error occurred during login: $e');
      setError(e.toString()); // Use e.toString() directly
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    setLoading();
    try {
      _currentUser = await _authService.register(userData);
      if (_authService.isAuthenticated && _currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Registration successful but failed to log in automatically.');
      }
    } catch (e) {
      // Catch generic Exception
      _logger.e('An unexpected error occurred during registration: $e');
      setError(e.toString()); // Use e.toString() directly
    }
  }

  Future<void> logout() async {
    setLoading();
    try {
      if (_userChannelName != null && _isSubscribed) {
        _logger.i(
          'UserProvider: Unsubscribing from channel: $_userChannelName',
        );
        await _pusherService.unsubscribeFromChannel(_userChannelName!);
        _userChannelName = null;
        _isSubscribed = false;
      }
      await _authService.logout();
      _currentUser = null;
      _viewedUser = null;
      setSuccess();
    } catch (e) {
      // Catch generic Exception
      _logger.e('Logout failed: $e');
      setError(e.toString()); // Use e.toString() directly
    } finally {
      _currentUser = null;
      _viewedUser = null;
      resetState();
    }
  }

  Future<void> fetchCurrentUser() async {
    if (!_authService.isAuthenticated) {
      _currentUser = null;
      resetState();
      return;
    }
    setLoading();
    try {
      _currentUser = await _authService.getCurrentUserProfile();
      if (_currentUser != null) {
        await _subscribeToUserChannel();
        setSuccess();
      } else {
        setError('Failed to fetch user profile: User is null after fetch.');
      }
    } catch (e) {
      // Catch generic Exception
      _logger.e('Failed to fetch current user profile: $e');
      setError(e.toString()); // Use e.toString() directly
    }
  }

  Future<void> updateAccountType(int roleValue) async {
    if (!_authService.isAuthenticated ||
        _authService.currentUser == null ||
        _authService.currentUser!.uuid.isEmpty) {
      setError(
        'User not authenticated or UUID missing for account type update.',
      );
      return;
    }

    setLoading();
    try {
      final response = await _apiService.post(
        '/user/onboard/${_authService.currentUser!.uuid}',
        data: {'role': roleValue},
      );

      if (response['statusCode'] == 200 && response.containsKey('data')) {
        final updatedUser = User.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        _currentUser = updatedUser;
        await _authService.saveUser(_currentUser!);
        setSuccess();
        _logger.i(
          'UserProvider: Account Type updated successfully for: ${_currentUser!.email} to role: ${_currentUser!.role}',
        );
      } else {
        final message =
            response['message'] as String? ??
            'Failed to update account type: Invalid response structure.';
        setError(message);
      }
    } catch (e) {
      // Catch generic Exception
      _logger.e('Failed to update account type: $e');
      setError(e.toString()); // Use e.toString() directly
    }
  }

  Future<void> updateCurrentUserProfile({
    Map<String, dynamic>? data,
    XFile? profileImage,
    XFile? coverImage,
    XFile? professionalCertificationImage,
    XFile? meansOfIdentification,
  }) async {
    if (!_authService.isAuthenticated ||
        _authService.currentUser == null ||
        _authService.currentUser!.uuid.isEmpty) {
      setError('User not authenticated for profile update.');
      return;
    }

    setLoading();
    try {
      final imageFormDataMap = <String, dynamic>{};
      final profileFormDataMap = <String, dynamic>{};

      // Handle profile and cover images
      if (profileImage != null) {
        imageFormDataMap['profileImage[file]'] =
            kIsWeb
                ? dio.MultipartFile.fromBytes(
                  await profileImage.readAsBytes(),
                  filename: 'profile_image.png',
                )
                : await dio.MultipartFile.fromFile(
                  profileImage.path,
                  filename: profileImage.path.split('/').last,
                );
        imageFormDataMap['profileImage[fileName]'] =
            kIsWeb ? 'profile_image.png' : profileImage.path.split('/').last;
      }

      if (coverImage != null) {
        imageFormDataMap['coverImage[file]'] =
            kIsWeb
                ? dio.MultipartFile.fromBytes(
                  await coverImage.readAsBytes(),
                  filename: 'cover_image.png',
                )
                : await dio.MultipartFile.fromFile(
                  coverImage.path,
                  filename: coverImage.path.split('/').last,
                );
        imageFormDataMap['coverImage[fileName]'] =
            kIsWeb ? 'cover_image.png' : coverImage.path.split('/').last;
      }

      // Upload profile/cover images first if they exist
      if (imageFormDataMap.isNotEmpty) {
        final imageResponse = await _apiService.post(
          '/user/profile/image/update',
          data: dio.FormData.fromMap(imageFormDataMap),
        );
        if (imageResponse['statusCode'] != 200) {
          final message =
              imageResponse['message'] as String? ??
              'Failed to update profile images.';
          setError(message);
          return;
        }
      }

      // Handle about section
      if (data?['about'] != null &&
          data!['about'].toString().trim().isNotEmpty) {
        profileFormDataMap['about'] = data['about'].toString().trim();
      }

      // Handle skills array
      if (data?['skills'] != null &&
          data!['skills'] is List &&
          (data['skills'] as List).isNotEmpty) {
        final skills = data['skills'] as List;
        for (int i = 0; i < skills.length; i++) {
          profileFormDataMap['skills[${i + 1}]'] = skills[i].toString();
        }
      }

      // Handle education
      final hasEducationData =
          (data?['educationCertification'] != null &&
              data!['educationCertification'].toString().isNotEmpty) ||
          (data?['educationInstitution'] != null &&
              data!['educationInstitution'].toString().isNotEmpty) ||
          (data?['educationCourseOfStudy'] != null &&
              data!['educationCourseOfStudy'].toString().isNotEmpty) ||
          (data?['educationGraduationDate'] != null &&
              data!['educationGraduationDate'].toString().isNotEmpty) ||
          (data?['educationEndDate'] != null &&
              data!['educationEndDate'].toString().isNotEmpty);

      if (hasEducationData) {
        if (data['educationCertification'] != null &&
            data['educationCertification'].toString().isNotEmpty) {
          profileFormDataMap['education[1][certification]'] =
              data['educationCertification'].toString();
        }
        if (data['educationInstitution'] != null &&
            data['educationInstitution'].toString().isNotEmpty) {
          profileFormDataMap['education[1][institution]'] =
              data['educationInstitution'].toString();
        }
        if (data['educationCourseOfStudy'] != null &&
            data['educationCourseOfStudy'].toString().isNotEmpty) {
          profileFormDataMap['education[1][courseOfStudy]'] =
              data['educationCourseOfStudy'].toString();
        }
        if (data['educationGraduationDate'] != null &&
            data['educationGraduationDate'].toString().isNotEmpty) {
          profileFormDataMap['education[1][startDate]'] =
              data['educationGraduationDate'].toString();
        }
        if (data['educationEndDate'] != null &&
            data['educationEndDate'].toString().isNotEmpty) {
          profileFormDataMap['education[1][endDate]'] =
              data['educationEndDate'].toString();
        }
      }

      // Handle professional certification
      final hasProfessionalCertificationData =
          (data?['professionalCertificationName'] != null &&
              data!['professionalCertificationName'].toString().isNotEmpty) &&
          (data['professionalCertificationOrganization'] != null &&
              data['professionalCertificationOrganization']
                  .toString()
                  .isNotEmpty) &&
          professionalCertificationImage != null;

      if (hasProfessionalCertificationData) {
        if (data['professionalCertificationName'] != null &&
            data['professionalCertificationName'].toString().isNotEmpty) {
          profileFormDataMap['professionalCertification[1][name]'] =
              data['professionalCertificationName'].toString();
        }
        if (data['professionalCertificationOrganization'] != null &&
            data['professionalCertificationOrganization']
                .toString()
                .isNotEmpty) {
          profileFormDataMap['professionalCertification[1][organization]'] =
              data['professionalCertificationOrganization'].toString();
        }

        profileFormDataMap['professionalCertification[1][file]'] =
            kIsWeb
                ? dio.MultipartFile.fromBytes(
                  await professionalCertificationImage.readAsBytes(),
                  filename: 'cert_doc.png',
                )
                : await dio.MultipartFile.fromFile(
                  professionalCertificationImage.path,
                  filename: professionalCertificationImage.path.split('/').last,
                );
        profileFormDataMap['professionalCertification[1][fileName]'] =
            kIsWeb
                ? 'cert_doc.png'
                : professionalCertificationImage.path.split('/').last;
      }

      // Handle means of identification
      if (meansOfIdentification != null) {
        profileFormDataMap['meansOfIdentification[file]'] =
            kIsWeb
                ? dio.MultipartFile.fromBytes(
                  await meansOfIdentification.readAsBytes(),
                  filename: 'id_doc.png',
                )
                : await dio.MultipartFile.fromFile(
                  meansOfIdentification.path,
                  filename: meansOfIdentification.path.split('/').last,
                );
        profileFormDataMap['meansOfIdentification[fileName]'] =
            kIsWeb ? 'id_doc.png' : meansOfIdentification.path.split('/').last;
      }

      // Handle location data
      if (data?['country'] != null &&
          data!['country'].toString().trim().isNotEmpty) {
        profileFormDataMap['country'] = data['country'].toString().trim();
      }
      if (data?['state'] != null &&
          data!['state'].toString().trim().isNotEmpty) {
        profileFormDataMap['state'] = data['state'].toString().trim();
      }

      // Handle phone number
      if (data?['phoneNumber'] != null &&
          data!['phoneNumber'].toString().trim().isNotEmpty) {
        profileFormDataMap['phoneNumber'] =
            data['phoneNumber'].toString().trim();
      }

      // Handle social handles
      if (data?['socialHandles'] != null && data!['socialHandles'] is Map) {
        final socialMap = data['socialHandles'] as Map<String, dynamic>;
        // Only add social handle if its value is not empty
        if (socialMap['facebook'] != null &&
            socialMap['facebook'].toString().trim().isNotEmpty) {
          profileFormDataMap['social[facebook]'] =
              socialMap['facebook'].toString().trim();
        }
        if (socialMap['linkedIn'] != null &&
            socialMap['linkedIn'].toString().trim().isNotEmpty) {
          profileFormDataMap['social[linkedIn]'] =
              socialMap['linkedIn'].toString().trim();
        }
        if (socialMap['instagram'] != null &&
            socialMap['instagram'].toString().trim().isNotEmpty) {
          profileFormDataMap['social[instagram]'] =
              socialMap['instagram'].toString().trim();
        }
        if (socialMap['twitter'] != null &&
            socialMap['twitter'].toString().trim().isNotEmpty) {
          profileFormDataMap['social[twitter]'] =
              socialMap['twitter'].toString().trim();
        }
      }

      // Handle subcategory
      if (data?['subCategoryUuid'] != null &&
          data!['subCategoryUuid'].toString().isNotEmpty) {
        profileFormDataMap['subCategoryUuid'] = data['subCategoryUuid'];
      }

      _logger.d('Updating profile with data: $profileFormDataMap');

      // Only send profile update if there's data to update
      if (profileFormDataMap.isNotEmpty) {
        final response = await _apiService.post(
          '/user/profile/update',
          data: dio.FormData.fromMap(profileFormDataMap),
        );

        if (response['statusCode'] != 200) {
          final message =
              response['message'] as String? ??
              'Failed to update profile: Invalid response structure.';
          setError(message);
          return;
        }
      }

      // Fetch updated profile
      final finalResponse = await _apiService.get('/user/profile');
      if (finalResponse['statusCode'] == 200 &&
          finalResponse.containsKey('data')) {
        final updatedUser = User.fromJson(
          finalResponse['data'] as Map<String, dynamic>,
        );
        _currentUser = updatedUser;
        await _authService.saveUser(_currentUser!);
        setSuccess();
      } else {
        // Even if fetching the latest profile fails, the update might have gone through.
        // So, we still set success for the operation.
        setSuccess();
        _logger.e('Failed to fetch latest user profile after update.');
      }
    } catch (e) {
      // Catch generic Exception
      _logger.e('Error during profile update: $e');
      setError(e.toString()); // Use e.toString() directly
    } finally {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Deletes the current user's account by calling the /user/delete endpoint.
  Future<bool> deleteUserAccount() async {
    setLoading();
    try {
      final response = await _apiService.post(
        '/user/account/delete',
        // data: {},
      );
      if (response['statusCode'] == 200) {
        // Clear all user state and log out
        await logout();
        setSuccess();
        return true;
      } else {
        final message =
            response['message'] as String? ?? 'Failed to delete account.';
        setError(message);
        return false;
      }
    } catch (e) {
      // Catch generic Exception
      _logger.e('Failed to delete account: $e');
      setError(e.toString()); // Use e.toString() directly
      return false;
    }
  }

  Future<void> fetchUserById(String userId) async {
    setLoading();
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/user/$userId',
      );
      if (response['statusCode'] == 200 && response.containsKey('data')) {
        _viewedUser = User.fromJson(response['data'] as Map<String, dynamic>);
        setSuccess();
      } else {
        final message =
            response['message'] as String? ??
            'Failed to fetch user profile by ID: Invalid response structure.';
        setError(message);
        _viewedUser = null;
      }
    } catch (e) {
      // Catch generic Exception
      _logger.e('Failed to fetch user profile: $e');
      setError(e.toString()); // Use e.toString() directly
      _viewedUser = null;
    }
  }

  Future<void> _subscribeToUserChannel() async {
    if (!_authService.isAuthenticated ||
        _authService.currentUser == null ||
        _authService.currentUser!.uuid.isEmpty) {
      _logger.w(
        'UserProvider: Cannot subscribe, user not authenticated or UUID missing',
      );
      setError(
        'User not authenticated or UUID missing for channel subscription.',
      ); // Report error
      return;
    }

    if (!_pusherService.isInitialized) {
      _logger.w(
        'UserProvider: PusherService not initialized, cannot subscribe',
      );
      setError(
        'PusherService not initialized, cannot subscribe to user channel.',
      ); // Report error
      return;
    }

    final channelName = 'user.profile.${_authService.currentUser!.uuid}';
    if (_userChannelName == channelName && _isSubscribed) {
      _logger.d('UserProvider: Already subscribed to channel: $channelName');
      return;
    }

    // Unsubscribe from old channel if exists
    if (_userChannelName != null &&
        _userChannelName!.isNotEmpty &&
        _isSubscribed) {
      _logger.i(
        'UserProvider: Unsubscribing from old channel: $_userChannelName',
      );
      await _pusherService.unsubscribeFromChannel(_userChannelName!);
      _userChannelName = null;
      _isSubscribed = false;
    }

    try {
      _logger.i(
        'UserProvider: Attempting to subscribe to channel: $channelName',
      );
      final success = await _pusherService.subscribeToChannel(channelName);
      if (success) {
        _userChannelName = channelName;
        _isSubscribed = true;

        // Bind to user profile updated event
        _pusherService.bindToEvent(channelName, 'user.profile.updated', (
          event,
        ) {
          try {
            _logger.i(
              'UserProvider: Received user.profile.updated event: ${event.data}',
            );
            if (event.data == null) {
              _logger.w('UserProvider: Event data is null, skipping update');
              setError('User profile update event data is null.');
              return;
            }

            final eventData = event.data as Map<String, dynamic>;

            // Check if 'user' field exists and handle both String and Map cases
            if (!eventData.containsKey('user')) {
              _logger.e('UserProvider: Event data does not contain user field');
              setError('Event data missing user information.');
              return;
            }

            final userData = eventData['user'];
            Map<String, dynamic> userMap;

            // Handle both String (JSON) and Map cases
            if (userData is String) {
              // Parse JSON string to Map
              try {
                userMap = jsonDecode(userData) as Map<String, dynamic>;
              } catch (parseError) {
                _logger.e(
                  'UserProvider: Failed to parse user JSON string: $parseError',
                );
                setError('Failed to parse user data from event.');
                return;
              }
            } else if (userData is Map<String, dynamic>) {
              // Already a Map
              userMap = userData;
            } else {
              _logger.e(
                'UserProvider: Unexpected user data type: ${userData.runtimeType}',
              );
              setError('Unexpected user data format in event.');
              return;
            }

            // Create User object from the parsed/extracted Map
            final updatedUser = User.fromJson(userMap);

            _currentUser = updatedUser;
            _authService.saveUser(_currentUser!);
            setSuccess();
            _logger.i(
              'UserProvider: User profile updated: ${_currentUser!.uuid}',
            );
          } catch (e) {
            _logger.e(
              'UserProvider: Error processing user.profile.updated event: $e. Data: ${event.data}',
            );
            setError(e.toString());
          }
        });
        _logger.i(
          'UserProvider: Successfully subscribed to channel: $channelName',
        );
        setSuccess(); // Indicate success for subscription
      } else {
        _logger.e(
          'UserProvider: Failed to subscribe to Pusher channel: $channelName',
        );
        setError(
          'Failed to subscribe to Pusher channel: $channelName',
        ); // Report error
        _userChannelName = null;
        _isSubscribed = false;
      }
    } catch (e) {
      _logger.e(
        'UserProvider: Error subscribing to Pusher channel $channelName: $e',
      );
      setError(e.toString()); // Use e.toString() directly
      _userChannelName = null;
      _isSubscribed = false;
    }
  }

  @override
  void dispose() {
    if (_userChannelName != null && _isSubscribed) {
      _logger.i(
        'UserProvider: Disposing and unsubscribing from channel: $_userChannelName',
      );
      _pusherService.unsubscribeFromChannel(_userChannelName!);
    }
    super.dispose();
  }
}
