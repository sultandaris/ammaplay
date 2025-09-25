// Legacy Database Helper - Compatibility Layer
// This file provides backward compatibility for older components
// while the app transitions to the new Database V3 system

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper.instance() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ammaplay_legacy.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE surat(
        surat_id INTEGER PRIMARY KEY,
        nama TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ayat(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surat_id INTEGER,
        ayat_id INTEGER,
        arab TEXT,
        latin TEXT,
        FOREIGN KEY (surat_id) REFERENCES surat (surat_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT,
        username TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> querySemuaSurah() async {
    final db = await database;
    return await db.query('surat', orderBy: 'surat_id DESC');
  }

  Future<List<Map<String, dynamic>>> queryAyatBySurah(int suratId) async {
    final db = await database;
    return await db.query(
      'ayat',
      where: 'surat_id = ?',
      whereArgs: [suratId],
      orderBy: 'ayat_id ASC',
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> login(String email, String password) async {
    final user = await getUserByEmail(email);
    return user != null && user['password'] == password;
  }

  Future<bool> signUp(String email, String password, {String? username}) async {
    try {
      final db = await database;
      await db.insert('users', {
        'email': email,
        'password': password,
        'username': username ?? email.split('@').first,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String email,
    String? newUsername,
    String? newPassword,
  }) async {
    try {
      final db = await database;
      Map<String, dynamic> updates = {};

      if (newUsername != null) updates['username'] = newUsername;
      if (newPassword != null) updates['password'] = newPassword;

      if (updates.isEmpty) return false;

      final rowsUpdated = await db.update(
        'users',
        updates,
        where: 'email = ?',
        whereArgs: [email],
      );
      return rowsUpdated > 0;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> loginFamily(
    String email,
    String password,
  ) async {
    final user = await getUserByEmail(email);
    if (user != null && user['password'] == password) {
      return user;
    }
    return null;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
