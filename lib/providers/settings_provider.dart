import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_helper.dart';
import '../models/settings.dart';

// Settings StateNotifier for managing app settings
class SettingsNotifier extends StateNotifier<AppSettings> {
  final DatabaseHelper _databaseHelper;

  SettingsNotifier(this._databaseHelper) : super(const AppSettings()) {
    _loadSettings();
  }

  // Load settings from database when provider is created
  Future<void> _loadSettings() async {
    try {
      final soundSetting = await _databaseHelper.getSetting('sound');
      final notificationsSetting = await _databaseHelper.getSetting(
        'notifications',
      );
      final fontSizeSetting = await _databaseHelper.getSetting('font_size');

      state = AppSettings(
        sound: soundSetting ?? 'on',
        notifications: notificationsSetting ?? 'on',
        fontSize: fontSizeSetting ?? 'medium',
      );
    } catch (e) {
      print('Error loading settings: $e');
      // Keep default settings if loading fails
    }
  }

  // Update sound setting
  Future<void> updateSound(String newSound) async {
    try {
      await _databaseHelper.updateSetting('sound', newSound);
      state = state.copyWith(sound: newSound);
    } catch (e) {
      print('Error updating sound setting: $e');
    }
  }

  // Update notifications setting
  Future<void> updateNotifications(String newNotifications) async {
    try {
      await _databaseHelper.updateSetting('notifications', newNotifications);
      state = state.copyWith(notifications: newNotifications);
    } catch (e) {
      print('Error updating notifications setting: $e');
    }
  }

  // Update font size setting
  Future<void> updateFontSize(String newFontSize) async {
    try {
      await _databaseHelper.updateSetting('font_size', newFontSize);
      state = state.copyWith(fontSize: newFontSize);
    } catch (e) {
      print('Error updating font size setting: $e');
    }
  }

  // Reset all settings to default
  Future<void> resetSettings() async {
    try {
      const defaultSettings = AppSettings();
      await _databaseHelper.updateSetting('sound', defaultSettings.sound);
      await _databaseHelper.updateSetting(
        'notifications',
        defaultSettings.notifications,
      );
      await _databaseHelper.updateSetting(
        'font_size',
        defaultSettings.fontSize,
      );
      state = defaultSettings;
    } catch (e) {
      print('Error resetting settings: $e');
    }
  }
}

// Database Helper Provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Settings Provider - This is what you'll use in your UI
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier(ref.read(databaseHelperProvider));
});
