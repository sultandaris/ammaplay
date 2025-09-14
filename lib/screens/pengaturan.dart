import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../models/settings.dart';
import '../router/app_router.dart';
import 'edit_profile_screen.dart';

class SettingsScreenMinimalist extends ConsumerStatefulWidget {
  const SettingsScreenMinimalist({super.key});

  @override
  ConsumerState<SettingsScreenMinimalist> createState() =>
      _SettingsScreenMinimalistState();
}

class _SettingsScreenMinimalistState
    extends ConsumerState<SettingsScreenMinimalist> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          "Pengaturan",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAccountSection(textTheme),
          const SizedBox(height: 24),
          _buildSectionTitle("Preferensi Umum", textTheme),
          const SizedBox(height: 8),
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildNotificationToggle(textTheme, settings),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildSoundSlider(textTheme, settings),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildFontSizeSlider(textTheme, settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: Colors.grey[600],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildAccountSection(TextTheme textTheme) {
    final userState = ref.watch(userProvider);
    final currentUser = userState.user;
    final isLoggedIn = userState.isLoggedIn;
    
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Tautkan Akun Orang Tua",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoggedIn && currentUser != null) ...[
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(currentUser.username, style: textTheme.bodyLarge),
                subtitle: Text(currentUser.email, style: textTheme.bodyMedium),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _editProfile,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text(
                        "Edit Profil",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.push(AppRoutes.signup);
                      },
                      child: const Text("Daftar"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(AppRoutes.login);
                      },
                      child: const Text("Masuk"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final userNotifier = ref.read(userProvider.notifier);
    await userNotifier.logout();
    print("User logged out");
  }

  void _editProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  Widget _buildNotificationToggle(TextTheme textTheme, AppSettings settings) {
    return ListTile(
      title: Text("Notifikasi", style: textTheme.bodyLarge),
      trailing: Switch(
        value: settings.notifications == 'on',
        onChanged: (value) {
          ref
              .read(settingsProvider.notifier)
              .updateNotifications(value ? 'on' : 'off');
        },
        activeThumbColor: Colors.blue,
      ),
    );
  }

  Widget _buildSoundSlider(TextTheme textTheme, AppSettings settings) {
    // Convert sound setting to slider value (0.0 to 1.0)
    double soundValue = settings.sound == 'on' ? 0.8 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Suara Dalam Game", style: textTheme.bodyLarge),
              Text(
                settings.sound == 'on' ? "Hidup" : "Mati",
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          Slider(
            value: soundValue,
            onChanged: (value) {
              String newSoundSetting = value > 0.1 ? 'on' : 'off';
              ref.read(settingsProvider.notifier).updateSound(newSoundSetting);
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider(TextTheme textTheme, AppSettings settings) {
    // Convert font size setting to slider value
    double fontValue = 0.75; // default medium
    if (settings.fontSize == 'small') fontValue = 0.5;
    if (settings.fontSize == 'medium') fontValue = 0.75;
    if (settings.fontSize == 'large') fontValue = 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ukuran Huruf", style: textTheme.bodyLarge),
              Text(
                settings.fontSize.toUpperCase(),
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          Slider(
            value: fontValue,
            onChanged: (value) {
              String newFontSize = 'medium';
              if (value < 0.6) {
                newFontSize = 'small';
              } else if (value > 0.85)
                newFontSize = 'large';
              ref.read(settingsProvider.notifier).updateFontSize(newFontSize);
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
