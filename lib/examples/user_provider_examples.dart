// CONTOH PENGGUNAAN USER PROVIDER
// File ini menunjukkan berbagai cara menggunakan user provider dalam aplikasi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

// 1. CONTOH WIDGET YANG MENAMPILKAN INFORMASI USER
class UserInfoWidget extends ConsumerWidget {
  const UserInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menggunakan provider untuk mengwatch state user
    final userState = ref.watch(userProvider);
    final currentUser = userState.user;
    final isLoggedIn = userState.isLoggedIn;
    final isLoading = userState.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isLoggedIn || currentUser == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.person_off),
          title: Text('Belum login'),
          subtitle: Text('Silakan login untuk mengakses fitur ini'),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.blue),
        title: Text(currentUser.username),
        subtitle: Text(currentUser.email),
        trailing: Text('ID: ${currentUser.id}'),
      ),
    );
  }
}

// 2. CONTOH WIDGET DENGAN CONVENIENT PROVIDER
class SimpleUserInfoWidget extends ConsumerWidget {
  const SimpleUserInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menggunakan convenience provider
    final currentUser = ref.watch(currentUserProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isLoading = ref.watch(isLoadingProvider);

    if (isLoading) {
      return const CircularProgressIndicator();
    }

    if (!isLoggedIn) {
      return const Text('Tidak ada user yang login');
    }

    return Text('Halo, ${currentUser?.username ?? 'User'}!');
  }
}

// 3. CONTOH FORM LOGIN DENGAN USER PROVIDER
class LoginFormExample extends ConsumerStatefulWidget {
  const LoginFormExample({super.key});

  @override
  ConsumerState<LoginFormExample> createState() => _LoginFormExampleState();
}

class _LoginFormExampleState extends ConsumerState<LoginFormExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final userNotifier = ref.read(userProvider.notifier);
    final success = await userNotifier.login(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login berhasil!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login gagal!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Email tidak valid';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            child: isLoading
                ? const CircularProgressIndicator()
                : const Text('Login'),
          ),
        ],
      ),
    );
  }
}

// 4. CONTOH SCREEN YANG MENGGUNAKAN USER PROVIDER
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Widget untuk menampilkan info user
            const UserInfoWidget(),
            const SizedBox(height: 16),
            
            // Widget simple
            const SimpleUserInfoWidget(),
            const SizedBox(height: 16),
            
            // Tombol logout
            Consumer(
              builder: (context, ref, child) {
                final isLoggedIn = ref.watch(isLoggedInProvider);
                
                if (!isLoggedIn) {
                  return const LoginFormExample();
                }
                
                return ElevatedButton(
                  onPressed: () async {
                    final userNotifier = ref.read(userProvider.notifier);
                    await userNotifier.logout();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logout berhasil!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Logout'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 5. CONTOH MENGGUNAKAN USER PROVIDER DALAM STATEFUL WIDGET
class StatefulUserExample extends ConsumerStatefulWidget {
  const StatefulUserExample({super.key});

  @override
  ConsumerState<StatefulUserExample> createState() => _StatefulUserExampleState();
}

class _StatefulUserExampleState extends ConsumerState<StatefulUserExample> {
  User? _previousUser;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    // Listen untuk perubahan user
    ref.listen(currentUserProvider, (previous, next) {
      if (previous != next) {
        print('User berubah dari $previous ke $next');
        // Lakukan sesuatu ketika user berubah
      }
    });

    // Deteksi perubahan user untuk keperluan tertentu
    if (_previousUser != currentUser) {
      _previousUser = currentUser;
      // Lakukan sesuatu ketika user berubah
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Contoh: refresh data ketika user berubah
        print('User profile updated');
      });
    }

    return Text('Current user: ${currentUser?.username ?? "None"}');
  }
}
