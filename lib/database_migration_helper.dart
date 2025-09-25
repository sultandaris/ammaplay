import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'database_helper_v3.dart';
import 'models/family_models.dart';

class DatabaseMigrationHelper {
  static const String defaultFamilyName = "Keluarga Muslim";
  static const String defaultParentPin = "1234";

  /// Migrates data from old database to new V3 database
  static Future<bool> migrateToV3() async {
    try {
      developer.log("Starting migration to Database V3...");

      // Initialize both databases
      final oldDb = DatabaseHelper.instance();
      final newDb = DatabaseHelperV3.instance;

      // Delete new database if exists to start fresh
      await newDb.deleteDatabaseFile();

      // Initialize new database
      await newDb.database;

      // Migrate users
      await _migrateUsers(oldDb, newDb);

      // Note: Surahs and Ayat are already inserted during new DB creation
      // No need to migrate them as they're the same data

      developer.log("Migration to V3 completed successfully!");
      return true;
    } catch (e) {
      developer.log("Migration failed: $e");
      return false;
    }
  }

  static Future<void> _migrateUsers(
    DatabaseHelper oldDb,
    DatabaseHelperV3 newDb,
  ) async {
    try {
      // Get all users from old database
      final oldUsers = await _getOldUsers(oldDb);
      developer.log("Found ${oldUsers.length} users to migrate");

      for (final oldUser in oldUsers) {
        // Create family account in new database
        final success = await newDb.createFamilyAccount(
          namaPengguna: oldUser['username'] ?? defaultFamilyName,
          email: oldUser['email'] ?? '',
          password: _generateRandomPassword(), // We can't decrypt old passwords
          pinOrangtua: defaultParentPin,
        );

        if (success) {
          developer.log("Migrated user: ${oldUser['email']}");
        } else {
          developer.log("Failed to migrate user: ${oldUser['email']}");
        }
      }
    } catch (e) {
      developer.log("Error migrating users: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> _getOldUsers(
    DatabaseHelper oldDb,
  ) async {
    try {
      final db = await oldDb.database;
      return await db.query('users');
    } catch (e) {
      developer.log("Error getting old users: $e");
      return [];
    }
  }

  static String _generateRandomPassword() {
    // Generate a temporary password for migrated accounts
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bytes = utf8.encode('temp_$timestamp');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8); // Use first 8 characters
  }

  /// Creates a test family account for development
  static Future<FamilyUser?> createTestFamily() async {
    final newDb = DatabaseHelperV3.instance;

    const testEmail = "test@ammaplay.com";
    const testName = "Keluarga Test";
    const testPassword = "test123";
    const testPin = "1234";

    try {
      // Try to login first (in case account already exists)
      final existingUser = await newDb.loginFamily(testEmail, testPassword);
      if (existingUser != null) {
        developer.log("Test family already exists");
        return existingUser;
      }

      // Create new test family
      final created = await newDb.createFamilyAccount(
        namaPengguna: testName,
        email: testEmail,
        password: testPassword,
        pinOrangtua: testPin,
      );

      if (created) {
        final user = await newDb.loginFamily(testEmail, testPassword);
        developer.log("Test family created successfully");
        return user;
      }

      return null;
    } catch (e) {
      developer.log("Error creating test family: $e");
      return null;
    }
  }

  /// Validates the new database structure
  static Future<bool> validateV3Database() async {
    try {
      final db = DatabaseHelperV3.instance;

      // Test basic queries
      final levels = await db.getAllLevels();
      final surahs = await db.getSurahsByLevel(1);

      developer.log(
        "Validation: Found ${levels.length} levels, ${surahs.length} surahs",
      );

      // Test with a demo user
      final testUser = await createTestFamily();
      if (testUser != null && testUser.idPengguna != null) {
        final surahsWithProgress = await db.getSurahsWithProgress(
          testUser.idPengguna!,
        );
        developer.log(
          "Validation: Found ${surahsWithProgress.length} surahs with progress data",
        );

        // Test progress update
        final progressUpdated = await db.updateProgress(
          testUser.idPengguna!,
          114,
          3,
        );
        developer.log(
          "Validation: Progress update ${progressUpdated ? 'successful' : 'failed'}",
        );

        return true;
      }

      developer.log(
        "Validation failed: Test user creation failed or user ID is null",
      );
      return false;
    } catch (e) {
      developer.log("Validation failed: $e");
      return false;
    }
  }

  /// Prints database statistics for debugging
  static Future<void> printDatabaseStats() async {
    try {
      final db = DatabaseHelperV3.instance;
      final dbInstance = await db.database;

      // Get table counts
      final users = await dbInstance.rawQuery(
        'SELECT COUNT(*) as count FROM users',
      );
      final levels = await dbInstance.rawQuery(
        'SELECT COUNT(*) as count FROM level',
      );
      final surahs = await dbInstance.rawQuery(
        'SELECT COUNT(*) as count FROM surat',
      );
      final ayats = await dbInstance.rawQuery(
        'SELECT COUNT(*) as count FROM ayat',
      );
      final progress = await dbInstance.rawQuery(
        'SELECT COUNT(*) as count FROM progres_pengguna',
      );

      developer.log("=== Database V3 Statistics ===");
      developer.log("Users: ${users.first['count']}");
      developer.log("Levels: ${levels.first['count']}");
      developer.log("Surahs: ${surahs.first['count']}");
      developer.log("Ayats: ${ayats.first['count']}");
      developer.log("Progress Records: ${progress.first['count']}");
      developer.log("===============================");
    } catch (e) {
      developer.log("Error printing stats: $e");
    }
  }
}
