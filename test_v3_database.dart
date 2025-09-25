import 'package:flutter/material.dart';
import 'lib/database_helper_v3.dart';
import 'lib/database_migration_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Testing V3 Database System...');

  try {
    // Initialize V3 database
    final dbHelperV3 = DatabaseHelperV3.instance;
    print('✅ V3 Database instance created successfully');

    // Test migration helper
    await DatabaseMigrationHelper.migrateToV3();
    print('✅ Migration completed successfully');

    // Test getting surahs with progress
    final surahs = await dbHelperV3.getSurahsWithProgress(1); // Test user ID 1
    print('✅ Retrieved ${surahs.length} surahs with progress');

    for (var surah in surahs.take(5)) {
      // Show first 5 surahs
      print(
        '  - ${surah.surah.namaLatin} (${surah.surah.namaArab}) - Level: ${surah.level.namaLevel} - Stars: ${surah.progres?.totalBintang ?? 0}',
      );
    }

    // Test family account creation
    await dbHelperV3.createFamilyAccount(
      namaPengguna: 'Test Family',
      email: 'test@family.com',
      password: 'password123',
      pinOrangtua: '1234',
    );
    print('✅ Test family account created');

    print('\n🎉 All V3 Database tests passed successfully!');
  } catch (e, stackTrace) {
    print('❌ Error testing V3 database: $e');
    print('Stack trace: $stackTrace');
  }
}
