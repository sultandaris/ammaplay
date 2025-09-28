import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'database_helper_v3.dart';
import 'database_migration_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle databsase migration and initialization
  await _initializeDatabase();

  runApp(const ProviderScope(child: MyApp()));
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

    // Clear any existing test progress data to prevent interference
    // DISABLED: Comment out to preserve progress across app restarts
    // await DatabaseMigrationHelper.clearTestProgress();

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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Amma PLAY App',
      theme: ThemeData(
        fontFamily: 'Sunday Magic',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        // Sunday-magic hint: use gradients in widgets (ThemeData doesn't hold gradients directly)
        // Example gradient to use in widgets:
        // const LinearGradient sundayGradient = LinearGradient(
        //   colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // );
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter, // Use go_router configuration
    );
  }
}
