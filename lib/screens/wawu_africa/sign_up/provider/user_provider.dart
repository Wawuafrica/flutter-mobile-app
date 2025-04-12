import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wawu_mobile/services/auth_service.dart';
import 'package:wawu_mobile/services/http_service.dart';
import 'package:wawu_mobile/widgets/in_app_notifications.dart';
// import 'package:wawu_mobile/screens/wawu_africa/sign_up/provider/userProvider.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoading = false;
  HttpService service = HttpService();
  AuthService authService = AuthService();

  bool get isLoading => _isLoading;

  /// Handles user sign-up by sending a POST request to the server.
  /// Updates the loading state and notifies listeners.
  Future<void> handleSignUp(
    Map<String, dynamic> userData,
    BuildContext context,
  ) async {
    _setLoading(true);
    final String requestBody = jsonEncode(userData);
    final Uri url = Uri.parse(service.baseUrl);

    try {
      final http.Response response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        await authService.saveUserDataToSharedPreferences(
          jsonDecode(response.body),
        );
        // Notify success
        showNotification('Registration successful!', context);
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String errorMessage = responseData['message'];
        showNotification(errorMessage, context);
      }
    } catch (e) {
      showNotification('An error occurred. Please try again.', context);
    } finally {
      _setLoading(false);
    }
  }

  /// Handles user login by sending a POST request to the server.
  Future<void> handleLogin(
    Map<String, dynamic> loginData,
    BuildContext context,
  ) async {
    _setLoading(true);
    final String requestBody = jsonEncode(loginData);
    final Uri url = Uri.parse('${service.baseUrl}/login');

    try {
      final http.Response response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        await authService.saveUserDataToSharedPreferences(
          jsonDecode(response.body),
        );
        showNotification('Login successful!', context);
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String errorMessage = responseData['message'];
        showNotification(errorMessage, context);
      }
    } catch (e) {
      showNotification('An error occurred. Please try again.', context);
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the user by clearing saved preferences and resetting state.
  Future<void> handleLogout(BuildContext context) async {
    _setLoading(true);
    try {
      await authService.clearUserDataFromSharedPreferences();
      showNotification('Logout successful!', context);
    } catch (e) {
      showNotification('An error occurred. Please try again.', context);
    } finally {
      _setLoading(false);
    }
  }

  /// Sets the loading state and notifies listeners.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
