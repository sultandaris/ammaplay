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
}
