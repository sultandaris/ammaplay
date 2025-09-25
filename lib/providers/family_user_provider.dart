import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database_helper_v3.dart';
import '../models/family_models.dart';
import '../screens/shared_preferences.dart';

// Family User State
class FamilyUserState {
  final FamilyUser? user;
  final bool isLoggedIn;
  final bool isLoading;
  final KontrolOrangTua? parentalControls;

  const FamilyUserState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.parentalControls,
  });

  FamilyUserState copyWith({
    FamilyUser? user,
    bool? isLoggedIn,
    bool? isLoading,
    KontrolOrangTua? parentalControls,
  }) {
    return FamilyUserState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      parentalControls: parentalControls ?? this.parentalControls,
    );
  }
}

// Family User StateNotifier
class FamilyUserNotifier extends StateNotifier<FamilyUserState> {
  final DatabaseHelperV3 _databaseHelper;

  FamilyUserNotifier(this._databaseHelper) : super(const FamilyUserState()) {
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
        state = const FamilyUserState(isLoggedIn: false, isLoading: false);
      }
    } catch (e) {
      print('Error checking login status: $e');
      state = const FamilyUserState(isLoggedIn: false, isLoading: false);
    }
  }

  // Load current user data from database
  Future<void> _loadCurrentUser() async {
    try {
      // Get the logged in user email from SharedPreferences
      final loggedInEmail =
          await SharedPreferencesHelper.getLoggedInUserEmail();

      if (loggedInEmail != null) {
        // For V3, we need to search by email in our new database
        // This is a simple approach - in production you might want to store user ID
        final allUsers = await _getAllUsers();
        final userData = allUsers.firstWhere(
          (user) => user.email == loggedInEmail,
          orElse: () => throw Exception('User not found'),
        );

        // Load parental controls
        final controls = await _databaseHelper.getParentalControls(
          userData.idPengguna!,
        );

        state = FamilyUserState(
          user: userData,
          isLoggedIn: true,
          isLoading: false,
          parentalControls: controls,
        );
      } else {
        await logout();
      }
    } catch (e) {
      print('Error loading current user: $e');
      await logout();
    }
  }

  // Helper method to get all users (for finding by email)
  Future<List<FamilyUser>> _getAllUsers() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query('users');
      return result.map((map) => FamilyUser.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Create family account (signup)
  Future<bool> createFamilyAccount({
    required String namaPengguna,
    required String email,
    required String password,
    required String pinOrangtua,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final success = await _databaseHelper.createFamilyAccount(
        namaPengguna: namaPengguna,
        email: email,
        password: password,
        pinOrangtua: pinOrangtua,
      );

      if (success) {
        // After successful account creation, login the user
        final loginSuccess = await login(email, password);
        return loginSuccess;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      print('Error creating family account: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  // Login family user
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = await _databaseHelper.loginFamily(email, password);

      if (user != null) {
        // Store login status and user email
        await SharedPreferencesHelper.setLoginStatus(true);
        await SharedPreferencesHelper.setLoggedInUserEmail(email);

        // Load parental controls only if user has valid ID
        KontrolOrangTua? controls;
        if (user.idPengguna != null) {
          controls = await _databaseHelper.getParentalControls(
            user.idPengguna!,
          );
        }

        state = FamilyUserState(
          user: user,
          isLoggedIn: true,
          isLoading: false,
          parentalControls: controls,
        );
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

  // Logout user
  Future<void> logout() async {
    try {
      await SharedPreferencesHelper.setLoginStatus(false);
      await SharedPreferencesHelper.clearLoggedInUserEmail();
      state = const FamilyUserState(isLoggedIn: false, isLoading: false);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Update family user profile
  Future<bool> updateProfile({
    required String namaPengguna,
    required String email,
  }) async {
    if (state.user == null || state.user!.idPengguna == null) return false;

    try {
      final success = await _databaseHelper.updateFamilyUserProfile(
        userId: state.user!.idPengguna!,
        newNamaPengguna: namaPengguna,
        newEmail: email,
      );

      if (success) {
        // Update local state
        final updatedUser = state.user!.copyWith(
          namaPengguna: namaPengguna,
          email: email,
        );

        // Update stored email in SharedPreferences
        await SharedPreferencesHelper.setLoggedInUserEmail(email);

        state = state.copyWith(user: updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Verify parent PIN
  Future<bool> verifyParentPin(String pin) async {
    if (state.user == null) return false;

    try {
      return await _databaseHelper.verifyParentPin(
        state.user!.idPengguna!,
        pin,
      );
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  // Update parental controls
  Future<bool> updateParentalControls(KontrolOrangTua controls) async {
    if (state.user == null) return false;

    try {
      final success = await _databaseHelper.updateParentalControls(controls);

      if (success) {
        state = state.copyWith(parentalControls: controls);
      }

      return success;
    } catch (e) {
      print('Error updating parental controls: $e');
      return false;
    }
  }

  // Get user progress for all surahs
  Future<List<ProgresPengguna>> getUserProgress() async {
    if (state.user == null) return [];

    try {
      return await _databaseHelper.getUserProgress(state.user!.idPengguna!);
    } catch (e) {
      print('Error getting user progress: $e');
      return [];
    }
  }

  // Update progress for a specific surah
  Future<bool> updateProgress(int surahId, int stars) async {
    if (state.user == null) return false;

    try {
      return await _databaseHelper.updateProgress(
        state.user!.idPengguna!,
        surahId,
        stars,
      );
    } catch (e) {
      print('Error updating progress: $e');
      return false;
    }
  }
}

// Family User Provider
final familyUserProvider =
    StateNotifierProvider<FamilyUserNotifier, FamilyUserState>((ref) {
      return FamilyUserNotifier(ref.read(databaseHelperV3Provider));
    });

// Convenience providers for easier access
final currentFamilyUserProvider = Provider<FamilyUser?>((ref) {
  return ref.watch(familyUserProvider).user;
});

final isLoggedInV3Provider = Provider<bool>((ref) {
  return ref.watch(familyUserProvider).isLoggedIn;
});

final isLoadingV3Provider = Provider<bool>((ref) {
  return ref.watch(familyUserProvider).isLoading;
});

final parentalControlsProvider = Provider<KontrolOrangTua?>((ref) {
  return ref.watch(familyUserProvider).parentalControls;
});

// Database Helper V3 Provider
final databaseHelperV3Provider = Provider<DatabaseHelperV3>((ref) {
  return DatabaseHelperV3.instance;
});

// Surah with Progress Provider
final surahsWithProgressProvider =
    FutureProvider.family<List<SurahWithProgress>, int?>((ref, levelId) async {
      final user = ref.watch(currentFamilyUserProvider);
      if (user == null) return [];

      final db = ref.read(databaseHelperV3Provider);
      return await db.getSurahsWithProgress(user.idPengguna!, levelId: levelId);
    });

// Levels Provider
final levelsProvider = FutureProvider<List<Level>>((ref) async {
  final db = ref.read(databaseHelperV3Provider);
  return await db.getAllLevels();
});
