# User Provider Documentation

## Overview
User Provider adalah sistem manajemen state user menggunakan Riverpod yang mengelola authentication dan data user dalam aplikasi AmmaPlay.

## Files Structure
```
lib/
├── models/
│   └── user.dart                    # Model data User
├── providers/
│   └── user_provider.dart           # Provider untuk manajemen state user
├── screens/
│   ├── edit_profile_screen.dart     # Screen untuk edit profil user
│   └── pengaturan.dart              # Screen pengaturan (updated)
└── examples/
    └── user_provider_examples.dart  # Contoh penggunaan
```

## Core Components

### 1. User Model (`models/user.dart`)
Model data untuk menyimpan informasi user:
```dart
class User {
  final int? id;
  final String email;
  final String username;
  
  // Methods: copyWith, toMap, fromMap, toString, ==, hashCode
}
```

### 2. User Provider (`providers/user_provider.dart`)

#### UserState
State yang mengelola kondisi user:
```dart
class UserState {
  final User? user;        // Data user saat ini
  final bool isLoggedIn;   // Status login
  final bool isLoading;    // Status loading
}
```

#### UserNotifier
StateNotifier yang mengelola perubahan state user:
- `login(email, password)` - Login user
- `signup(email, password, username?)` - Registrasi user baru
- `logout()` - Logout user
- `updateProfile(username, email)` - Update profil user
- `getUserByEmail(email)` - Get user berdasarkan email

#### Available Providers
```dart
// Main provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>

// Convenience providers
final currentUserProvider = Provider<User?>        // User saat ini
final isLoggedInProvider = Provider<bool>         // Status login
final isLoadingProvider = Provider<bool>          // Status loading
```

## Usage Examples

### 1. Basic Usage - Menampilkan Info User
```dart
class UserInfoWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    
    if (!isLoggedIn) {
      return Text('Belum login');
    }
    
    return Text('Halo, ${currentUser?.username}!');
  }
}
```

### 2. Login Function
```dart
Future<void> handleLogin(WidgetRef ref, String email, String password) async {
  final userNotifier = ref.read(userProvider.notifier);
  final success = await userNotifier.login(email, password);
  
  if (success) {
    print('Login berhasil');
  } else {
    print('Login gagal');
  }
}
```

### 3. Listening to User Changes
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen untuk perubahan user
    ref.listen(currentUserProvider, (previous, next) {
      if (previous != next) {
        // Handle user change
        print('User berubah dari $previous ke $next');
      }
    });
    
    return Container();
  }
}
```

### 4. Conditional Rendering Based on Login Status
```dart
class ConditionalWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isLoading = ref.watch(isLoadingProvider);
    
    if (isLoading) {
      return CircularProgressIndicator();
    }
    
    return isLoggedIn 
      ? LoggedInWidget() 
      : LoginWidget();
  }
}
```

## Integration dengan Database

User Provider terintegrasi dengan `DatabaseHelper` untuk:
- Menyimpan data user ke SQLite database
- Melakukan hashing password dengan SHA-256
- Mengelola session dengan SharedPreferences

### Database Schema
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  username TEXT NOT NULL 
);
```

## Features

### ✅ Implemented
- [x] User login dengan email/password
- [x] User registration dengan username optional
- [x] Logout functionality
- [x] Edit profile (username & email)
- [x] Automatic session checking saat app start
- [x] Integration dengan SharedPreferences
- [x] Password hashing (SHA-256)
- [x] Error handling dan loading states
- [x] Reactive UI dengan Riverpod

### 🔧 Database Methods Added
- `signUp(email, password, {username?})` - Updated dengan parameter username
- `getUserByEmail(email)` - Get user berdasarkan email
- `updateUserProfile(userId, username, email)` - Update profil user
- `getUserById(userId)` - Get user berdasarkan ID

## Updated Screens

### Login Screen (`login_screen.dart`)
- Diubah ke `ConsumerStatefulWidget`
- Menggunakan `userProvider.notifier.login()`
- Otomatis mengelola session

### Signup Screen (`signup_screen.dart`)
- Diubah ke `ConsumerStatefulWidget`
- Menambahkan field username (optional)
- Menggunakan `userProvider.notifier.signup()`
- Auto-login setelah registrasi berhasil

### Settings Screen (`screens/pengaturan.dart`)
- Menggunakan `userProvider` untuk menampilkan data user
- Tambah tombol "Edit Profil"
- Logout menggunakan `userProvider.notifier.logout()`

### Edit Profile Screen (`screens/edit_profile_screen.dart`)
- Screen baru untuk edit profil user
- Form validation
- Update profile menggunakan `userProvider.notifier.updateProfile()`

## Best Practices

### 1. Selalu gunakan ref.watch untuk UI
```dart
final currentUser = ref.watch(currentUserProvider);
```

### 2. Gunakan ref.read untuk actions
```dart
final userNotifier = ref.read(userProvider.notifier);
await userNotifier.login(email, password);
```

### 3. Handle loading states
```dart
final isLoading = ref.watch(isLoadingProvider);
if (isLoading) return CircularProgressIndicator();
```

### 4. Listen untuk side effects
```dart
ref.listen(userProvider, (previous, next) {
  if (previous?.isLoggedIn != next.isLoggedIn) {
    // Handle login status change
  }
});
```

## Error Handling

User Provider menangani error dengan:
- Try-catch blocks di semua async operations
- Logging error ke console
- Returning boolean success/failure untuk operations
- Maintaining state consistency saat error terjadi

## Next Steps / Possible Enhancements

1. **Password Reset**: Tambah functionality reset password
2. **Email Verification**: Verifikasi email saat registrasi
3. **Profile Picture**: Upload dan manage foto profil
4. **Social Login**: Login dengan Google/Facebook
5. **Biometric Login**: Fingerprint/Face ID authentication
6. **Multi-account**: Support multiple user accounts
7. **Offline Support**: Cache user data untuk offline access

## Migration Guide

Jika mengupdate dari sistem login lama:

1. Update import statements:
```dart
// Old
import 'database_helper.dart';

// New
import 'providers/user_provider.dart';
```

2. Update widget types:
```dart
// Old
class MyWidget extends StatefulWidget

// New  
class MyWidget extends ConsumerStatefulWidget
```

3. Update login calls:
```dart
// Old
final success = await dbHelper.login(email, password);

// New
final userNotifier = ref.read(userProvider.notifier);
final success = await userNotifier.login(email, password);
```
