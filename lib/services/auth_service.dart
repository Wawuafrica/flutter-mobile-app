import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Function to save user data to shared preferences
  Future<void> saveUserDataToSharedPreferences(
    Map<String, dynamic> userData,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userDataString = jsonEncode(userData);
    await prefs.setString('userData', userDataString);
  }

  // Function to retrieve user data from shared preferences
  Future<Map<String, dynamic>?> getUserDataFromSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> _accessDataFromSharedPrefs() async {
    // Retrieve user data from shared preferences
    final Map<String, dynamic>? userData =
        await getUserDataFromSharedPreferences();

    if (userData != null) {
      // Access the fields from the user data
      final String? userId = userData['_id'];
      final String? name = userData['name'];
      final String? email = userData['email'];
      final String? role = userData['role'];
      final String? token = userData['token'];
      final String? profileImage = userData['profileImage'];
      // Use the retrieved data as needed
    } else {
      // Handle case where user data is not found in shared preferences
    }
  }

  // Function to clear user data from shared preferences
  Future<void> clearUserDataFromSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
  }
}
