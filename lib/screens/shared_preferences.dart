import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class SharedPreferencesHelper {
  static Future<void> setLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
    developer.log('Login status set to: $isLoggedIn');
  }

  static Future<bool> getLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Store logged in user email
  static Future<void> setLoggedInUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUserEmail', email);
    developer.log('Logged in user email set to: $email');
  }

  // Get logged in user email
  static Future<String?> getLoggedInUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loggedInUserEmail');
  }

  // Clear logged in user email
  static Future<void> clearLoggedInUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUserEmail');
    developer.log('Logged in user email cleared');
  }
}
