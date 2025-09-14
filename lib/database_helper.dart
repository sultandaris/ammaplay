import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "amma.db";
  static const _databaseVersion = 2;

  static const settingsTable = 'settings';
  static const usersTable = 'users';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    developer.log("Database path: ${documentsDirectory.path}/amma.db");
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $settingsTable (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
          ''');

    await db.execute('''
          CREATE TABLE $usersTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            username TEXT NOT NULL 
          )
          ''');

    await db.execute('''
        CREATE TABLE surat (
        surat_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        arti TEXT,
        jumlah_ayat INTEGER
        )
        ''');

    await db.execute('''
      CREATE TABLE ayat (
        ayat_id INTEGER PRIMARY KEY AUTOINCREMENT,
        surat_id INTEGER NOT NULL,
        nomor INTEGER NOT NULL,
        teks TEXT NOT NULL,
        FOREIGN KEY(surat_id) REFERENCES surat(surat_id)
      )
      ''');

    await db.execute('''
      INSERT INTO $settingsTable (key, value) VALUES
      ('sound', 'on'),
      ('notifications', 'on'),
      ('font_size', 'medium')
      ''');
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Encode password ke bytes
    final digest = sha256.convert(bytes); // Gunakan algoritma hashing SHA-256
    return digest.toString();
  }

  Future<bool> signUp(String email, String password, {String? username}) async {
    print("Memproses pendaftaran");
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);
    try {
      await db.insert(
        usersTable,
        {
          'email': email,
          'password_hash': hashedPassword,
          'username': username ?? 'Sahabat',
        },
        conflictAlgorithm: ConflictAlgorithm.fail, // Gagal jika email sudah ada
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> deleteDatabaseFile() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, DatabaseHelper._databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print("Database deleted: $path");
    }
  }

  Future<bool> login(String email, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    final result = await db.query(
      usersTable,
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, hashedPassword],
    );
    List<Map<String, dynamic>> users = await db.query(usersTable);
    developer.log('Users in database: $users');
    return result.isNotEmpty;
  }

  Future<int> updateSetting(String key, String value) async {
    Database db = await instance.database;
    return await db.insert(settingsTable, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      settingsTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'];
    }
    return null;
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      usersTable,
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Update user profile
  Future<bool> updateUserProfile(int userId, String username, String email) async {
    final db = await instance.database;
    try {
      final count = await db.update(
        usersTable,
        {
          'username': username,
          'email': email,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      return count > 0;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      usersTable,
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
