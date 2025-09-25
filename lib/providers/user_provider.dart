import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_helper.dart';
import '../models/user.dart';
import '../screens/shared_preferences.dart';

// User State
class UserState {
  final User? user;
  final bool isLoggedIn;
  final bool isLoading;

  const UserState({this.user, this.isLoggedIn = false, this.isLoading = false});

  UserState copyWith({User? user, bool? isLoggedIn, bool? isLoading}) {
    return UserState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// User StateNotifier
class UserNotifier extends StateNotifier<UserState> {
  final DatabaseHelper _databaseHelper;

  UserNotifier(this._databaseHelper) : super(const UserState()) {
    _checkLoginStatus();
  }

  // Check if user is logged in when app starts
  Future<void> _checkLoginStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final isLoggedIn = await SharedPreferencesHelper.getLoginStatus();

      if (isLoggedIn) {
        await _loadCurrentUser();
      } else {
        state = const UserState(isLoggedIn: false, isLoading: false);
      }
    } catch (e) {
      print('Error checking login status: $e');
      state = const UserState(isLoggedIn: false, isLoading: false);
    }
  }

  // Load current user data from database
  Future<void> _loadCurrentUser() async {
    try {
      // Get the logged in user email from SharedPreferences
      final loggedInEmail =
          await SharedPreferencesHelper.getLoggedInUserEmail();

      if (loggedInEmail != null) {
        // Get user by email to ensure we get the correct user
        final userData = await _databaseHelper.getUserByEmail(loggedInEmail);

        if (userData != null) {
          final user = User.fromMap(userData);
          state = UserState(user: user, isLoggedIn: true, isLoading: false);
        } else {
          // User not found in database, logout
          await logout();
        }
      } else {
        // No logged in email stored, logout
        await logout();
      }
    } catch (e) {
      print('Error loading current user: $e');
      state = const UserState(isLoggedIn: false, isLoading: false);
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    try {
      final success = await _databaseHelper.login(email, password);

      if (success) {
        // Store login status and user email
        await SharedPreferencesHelper.setLoginStatus(true);
        await SharedPreferencesHelper.setLoggedInUserEmail(email);

        // Load the specific user who just logged in
        await _loadCurrentUser();
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  // Signup user
  Future<bool> signup(String email, String password, {String? username}) async {
    state = state.copyWith(isLoading: true);

    try {
      final success = await _databaseHelper.signUp(
        email,
        password,
        username: username,
      );

      if (success) {
        // After successful signup, login the user
        final loginSuccess = await login(email, password);
        return loginSuccess;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      print('Error during signup: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await SharedPreferencesHelper.setLoginStatus(false);
      await SharedPreferencesHelper.clearLoggedInUserEmail();
      state = const UserState(isLoggedIn: false, isLoading: false);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Update user profile
  Future<bool> updateProfile(String username, String email) async {
    if (state.user == null) return false;

    try {
      final success = await _databaseHelper.updateUserProfile(
        email: state.user!.email,
        newUsername: username,
        newPassword:
            email, // This should be password, but we're using email for now
      );

      if (success) {
        final updatedUser = state.user!.copyWith(
          username: username,
          email: email,
        );
        state = state.copyWith(user: updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Get user by email (helper method)
  Future<User?> getUserByEmail(String email) async {
    try {
      final userData = await _databaseHelper.getUserByEmail(email);
      return userData != null ? User.fromMap(userData) : null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }
}

// User Provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(databaseHelperProvider));
});

// Convenience providers for easier access
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).isLoggedIn;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userProvider).isLoading;
});

// Database Helper Provider (if not already defined elsewhere)
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance();
});
