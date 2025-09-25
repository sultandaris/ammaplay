import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../providers/family_user_provider.dart';
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
    final userState = ref.watch(familyUserProvider);
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
              "Informasi Akun Keluarga",
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoggedIn && currentUser != null) ...[
              // User Profile Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue[600],
                          child: Icon(
                            Icons.family_restroom,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Keluarga',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                currentUser.namaPengguna,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.blue[200], height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Akun',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                currentUser.email,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (currentUser.idPengguna != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: Colors.blue[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID Pengguna',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '#${currentUser.idPengguna}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit Profil"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text("Keluar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Not logged in state
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!, width: 1),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 48,
                      color: Colors.orange[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Belum Masuk",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Masuk untuk menyimpan progress belajar",
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.orange[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.signup);
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text("Daftar"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(AppRoutes.login);
                      },
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text("Masuk"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
    final familyUserNotifier = ref.read(familyUserProvider.notifier);
    await familyUserNotifier.logout();
    print("User logged out");
  }

  void _editProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EditProfileScreen()));
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
