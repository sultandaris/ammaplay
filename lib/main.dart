import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'screens/shared_preferences.dart';
import 'database_helper_v3.dart';
import 'database_migration_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle database migration and initialization
  await _initializeDatabase();

  final isLoggedIn = await SharedPreferencesHelper.getLoginStatus();

  runApp(ProviderScope(child: MyApp(isLoggedIn: isLoggedIn)));
}

Future<void> _initializeDatabase() async {
  try {
    print("Initializing Database V3...");

    // Initialize the V3 database (this will create it if it doesn't exist)
    final dbV3 = DatabaseHelperV3.instance;
    await dbV3.database;

    // Create a test family account for development
    // This is safe to call multiple times - it won't create duplicates
    await DatabaseMigrationHelper.createTestFamily();

    // Validate the database
    final isValid = await DatabaseMigrationHelper.validateV3Database();
    print("Database V3 validation: ${isValid ? 'PASSED' : 'FAILED'}");

    // Print database statistics for debugging
    await DatabaseMigrationHelper.printDatabaseStats();

    print("Database initialization complete!");
  } catch (e) {
    print("Database initialization error: $e");
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Amma PLAY App',
      theme: ThemeData(
        fontFamily: 'YourCustomFont',
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter, // Use go_router configuration
    );
  }
}
