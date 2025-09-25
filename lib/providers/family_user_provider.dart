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

  // Get parental controls for current user
  Future<KontrolOrangTua?> getKontrolOrangTua(int userId) async {
    try {
      return await _databaseHelper.getParentalControls(userId);
    } catch (e) {
      print('Error getting parental controls: $e');
      return null;
    }
  }

  // Validate parent PIN
  Future<bool> validatePin(int userId, String pin) async {
    try {
      return await _databaseHelper.verifyParentPin(userId, pin);
    } catch (e) {
      print('Error validating PIN: $e');
      return false;
    }
  }

  // Update parental controls with individual parameters
  Future<bool> updateKontrolOrangTua(
    int userId,
    int batasWaktuMenit,
    bool notifikasiSolatAktif,
  ) async {
    try {
      final controls = KontrolOrangTua(
        idPengguna: userId,
        batasWaktuMenit: batasWaktuMenit,
        notifikasiSolatAktif: notifikasiSolatAktif,
      );

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

// Surah with Progress Provider (by Level)
final surahsWithProgressProvider =
    FutureProvider.family<List<SurahWithProgress>, int?>((ref, levelId) async {
      final user = ref.watch(currentFamilyUserProvider);
      if (user == null) return [];

      final db = ref.read(databaseHelperV3Provider);
      return await db.getSurahsWithProgress(user.idPengguna!, levelId: levelId);
    });

// Surah with Progress Provider (by User ID) - for hafalan surat screen
final surahsWithProgressByUserProvider =
    FutureProvider.family<List<SurahWithProgress>, int>((ref, userId) async {
      final db = ref.read(databaseHelperV3Provider);
      return await db.getSurahsWithProgress(userId);
    });

// Levels Provider
final levelsProvider = FutureProvider<List<Level>>((ref) async {
  final db = ref.read(databaseHelperV3Provider);
  return await db.getAllLevels();
});

// ========== UNIFIED PROGRESS STATE MANAGEMENT ==========

// Progress State untuk single source of truth
class UnifiedProgressState {
  final Map<int, ProgresPengguna> progressBySurahId;
  final Map<int, List<SurahWithProgress>> surahsByLevelId;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const UnifiedProgressState({
    this.progressBySurahId = const {},
    this.surahsByLevelId = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  UnifiedProgressState copyWith({
    Map<int, ProgresPengguna>? progressBySurahId,
    Map<int, List<SurahWithProgress>>? surahsByLevelId,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return UnifiedProgressState(
      progressBySurahId: progressBySurahId ?? this.progressBySurahId,
      surahsByLevelId: surahsByLevelId ?? this.surahsByLevelId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

// Unified Progress Notifier - Single source of truth untuk progress data
class UnifiedProgressNotifier extends StateNotifier<UnifiedProgressState> {
  final DatabaseHelperV3 _databaseHelper;
  final Ref _ref;

  UnifiedProgressNotifier(this._databaseHelper, this._ref)
    : super(const UnifiedProgressState()) {
    _initializeData();
  }

  // Initialize data saat provider pertama kali digunakan
  Future<void> _initializeData() async {
    final user = _ref.read(currentFamilyUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _loadAllProgressData(user.idPengguna!);
    } catch (e) {
      print('Error initializing progress data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load semua data progress dari database
  Future<void> _loadAllProgressData(int userId) async {
    try {
      // Get all surahs with progress
      final surahsWithProgress = await _databaseHelper.getSurahsWithProgress(
        userId,
      );

      // Build progress map
      final Map<int, ProgresPengguna> progressMap = {};
      final Map<int, List<SurahWithProgress>> levelMap = {};

      for (final swp in surahsWithProgress) {
        // Add to progress map if has progress
        if (swp.progres != null) {
          progressMap[swp.surah.idSurat] = swp.progres!;
        }

        // Group by level
        final levelId = swp.surah.idLevel;
        if (levelMap[levelId] == null) {
          levelMap[levelId] = [];
        }
        levelMap[levelId]!.add(swp);
      }

      state = state.copyWith(
        progressBySurahId: progressMap,
        surahsByLevelId: levelMap,
        isLoading: false,
        error: null,
      );

      print('=== UNIFIED PROGRESS LOADED ===');
      print('Progress count: ${progressMap.length}');
      print('Level groups: ${levelMap.keys.toList()}');
      progressMap.forEach((surahId, progress) {
        print('Surah $surahId: ${progress.totalBintang} stars');
      });
      print('================================');
    } catch (e) {
      print('Error loading progress data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update progress untuk surah tertentu - AUTO NOTIFY ALL LISTENERS
  Future<bool> updateProgress(int surahId, int newStars) async {
    final user = _ref.read(currentFamilyUserProvider);
    if (user == null) {
      print('UPDATE GAGAL: No current user');
      return false;
    }

    try {
      // Update database first
      final success = await _databaseHelper.updateProgress(
        user.idPengguna!,
        surahId,
        newStars,
      );

      if (success) {
        // Update local state - otomatis notify semua listeners!
        final newProgress = ProgresPengguna(
          idPengguna: user.idPengguna!,
          idSurat: surahId,
          totalBintang: newStars,
        );

        final updatedProgressMap = Map<int, ProgresPengguna>.from(
          state.progressBySurahId,
        );
        updatedProgressMap[surahId] = newProgress;

        // Rebuild level groups dengan progress terbaru
        await _rebuildLevelGroups(user.idPengguna!, updatedProgressMap);

        print('=== UNIFIED PROGRESS UPDATED ===');
        print('Surah ID: $surahId');
        print('New Stars: $newStars');
        print('Total progress entries: ${updatedProgressMap.length}');
        print('=================================');

        return true;
      }

      return false;
    } catch (e) {
      print('Error updating progress: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Rebuild level groups setelah progress update
  Future<void> _rebuildLevelGroups(
    int userId,
    Map<int, ProgresPengguna> progressMap,
  ) async {
    try {
      final surahsWithProgress = await _databaseHelper.getSurahsWithProgress(
        userId,
      );

      final Map<int, List<SurahWithProgress>> levelMap = {};

      for (final swp in surahsWithProgress) {
        final levelId = swp.surah.idLevel;
        if (levelMap[levelId] == null) {
          levelMap[levelId] = [];
        }

        // Use updated progress from progressMap
        final updatedSwp = SurahWithProgress(
          surah: swp.surah,
          level: swp.level,
          progres: progressMap[swp.surah.idSurat],
          isUnlocked: swp.isUnlocked,
        );

        levelMap[levelId]!.add(updatedSwp);
      }

      state = state.copyWith(
        progressBySurahId: progressMap,
        surahsByLevelId: levelMap,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error rebuilding level groups: $e');
    }
  }

  // Reset progress untuk surah tertentu (untuk testing)
  Future<bool> resetProgress(int surahId) async {
    final user = _ref.read(currentFamilyUserProvider);
    if (user == null) return false;

    try {
      final db = await _databaseHelper.database;
      final deletedRows = await db.delete(
        'progres_pengguna',
        where: 'id_pengguna = ? AND id_surat = ?',
        whereArgs: [user.idPengguna!, surahId],
      );

      // Always proceed with reset (even if no DB rows found)
      // Remove from local state
      final updatedProgressMap = Map<int, ProgresPengguna>.from(
        state.progressBySurahId,
      );
      updatedProgressMap.remove(surahId);

      // Rebuild level groups
      await _rebuildLevelGroups(user.idPengguna!, updatedProgressMap);

      print('=== PROGRESS RESET ===');
      print('Surah ID: $surahId');
      print('Deleted rows: $deletedRows');
      print('======================');

      return true;
    } catch (e) {
      print('Error resetting progress: $e');
      return false;
    }
  }

  // Clear all progress (untuk debugging)
  Future<bool> clearAllProgress() async {
    try {
      final db = await _databaseHelper.database;
      final deletedRows = await db.delete('progres_pengguna');

      // Clear local state
      state = state.copyWith(
        progressBySurahId: {},
        lastUpdated: DateTime.now(),
      );

      // Reload data untuk rebuild semua
      final user = _ref.read(currentFamilyUserProvider);
      if (user != null) {
        await _loadAllProgressData(user.idPengguna!);
      }

      print('=== ALL PROGRESS CLEARED ===');
      print('Deleted rows: $deletedRows');
      print('============================');

      return true;
    } catch (e) {
      print('Error clearing all progress: $e');
      return false;
    }
  }

  // Force refresh dari database
  Future<void> refreshFromDatabase() async {
    final user = _ref.read(currentFamilyUserProvider);
    if (user != null) {
      await _loadAllProgressData(user.idPengguna!);
    }
  }
}

// Unified Progress Provider - SINGLE SOURCE OF TRUTH
final unifiedProgressProvider =
    StateNotifierProvider<UnifiedProgressNotifier, UnifiedProgressState>((ref) {
      final databaseHelper = ref.read(databaseHelperV3Provider);
      return UnifiedProgressNotifier(databaseHelper, ref);
    });

// ========== NEW SIMPLIFIED PROVIDERS USING UNIFIED STATE ==========

// Enhanced Surah with Progress Provider (by Level) - Uses unified state
final enhancedSurahsWithProgressProvider =
    Provider.family<List<SurahWithProgress>, int?>((ref, levelId) {
      final progressState = ref.watch(unifiedProgressProvider);

      if (progressState.isLoading) {
        return []; // Return empty list while loading
      }

      if (levelId == null) {
        // Return all surahs from all levels
        return progressState.surahsByLevelId.values
            .expand((surahList) => surahList)
            .toList();
      } else {
        // Return surahs for specific level
        return progressState.surahsByLevelId[levelId] ?? [];
      }
    });

// Enhanced Surah with Progress Provider (by User) - Uses unified state
final enhancedSurahsWithProgressByUserProvider =
    Provider.family<List<SurahWithProgress>, int>((ref, userId) {
      final progressState = ref.watch(unifiedProgressProvider);

      if (progressState.isLoading) {
        return []; // Return empty list while loading
      }

      // Return all surahs from all levels for the user
      return progressState.surahsByLevelId.values
          .expand((surahList) => surahList)
          .toList();
    });

// Progress Map Provider - Easy access to progress by surah ID
final progressMapProvider = Provider<Map<int, ProgresPengguna>>((ref) {
  final progressState = ref.watch(unifiedProgressProvider);
  return progressState.progressBySurahId;
});

// Individual Surah Progress Provider - Get progress for specific surah
final surahProgressProvider = Provider.family<ProgresPengguna?, int>((
  ref,
  surahId,
) {
  final progressMap = ref.watch(progressMapProvider);
  return progressMap[surahId];
});

// Loading State Provider - Check if progress data is loading
final progressLoadingProvider = Provider<bool>((ref) {
  final progressState = ref.watch(unifiedProgressProvider);
  return progressState.isLoading;
});

// Error State Provider - Get any progress-related errors
final progressErrorProvider = Provider<String?>((ref) {
  final progressState = ref.watch(unifiedProgressProvider);
  return progressState.error;
});
