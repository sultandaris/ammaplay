import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'models/quran.dart'; // --- BARU --- Impor file model

class DatabaseHelper {
  static const _databaseName = "amma.db";
  static const _databaseVersion = 2;

  static const settingsTable = 'settings';
  static const usersTable = 'users';
  // --- BARU --- Definisikan nama tabel surah dan ayat
  static const surahTable = 'surat';
  static const ayatTable = 'ayat';

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
        CREATE TABLE $surahTable (
        surat_id INTEGER PRIMARY KEY,
        nama TEXT NOT NULL,
        arti TEXT,
        jumlah_ayat INTEGER
        )
        ''');
    developer.log("Tabel '$surahTable' dibuat.");

    await db.execute('''
    CREATE TABLE $ayatTable (
      ayat_id INTEGER PRIMARY KEY AUTOINCREMENT, -- CUKUP TAMBAHKAN AUTOINCREMENT
      surat_id INTEGER NOT NULL,
      nomor INTEGER NOT NULL,
      teks_arab TEXT NOT NULL,
      teks_latin TEXT NOT NULL,
      teks_indonesia TEXT NOT NULL,
      audio_url TEXT NOT NULL, 
      FOREIGN KEY(surat_id) REFERENCES surat(surat_id)
      )
      ''');
    developer.log("Tabel '$ayatTable' dibuat.");

    await db.execute('''
      INSERT INTO $settingsTable (key, value) VALUES
      ('sound', 'on'),
      ('notifications', 'on'),
      ('font_size', 'medium')
      ''');

    await _insertDataAnNaas(db);
  }

  Future<void> _insertDataAnNaas(Database db) async {
  await db.transaction((txn) async {
    // Masukkan data Surah An-Naas
    int idSurah = await txn.insert(
        surahTable,
        Surah(
          suratId: 114,
          nama: "An-Nas", // Nama disesuaikan dengan UI
          arti: "Manusia",
          jumlahAyat: 6,
        ).toMap());
    developer.log("Data surah An-Nas (ID: $idSurah) dimasukkan.");

    // List data ayat untuk An-Naas dengan data lengkap
    List<Ayat> ayatAnNaas = [
      Ayat(suratId: idSurah, nomor: 1, teksArab: "قُلْ اَعُوْذُ بِرَبِّ النَّاسِۙ", teksLatin: "Qul a'ụżu birabbin-nās", teksIndonesia: "Katakanlah, “Aku berlindung kepada Tuhannya manusia,", audioUrl: "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114001.mp3"),
        Ayat(suratId: idSurah, nomor: 2, teksArab: "مَلِكِ النَّاسِۙ", teksLatin: "Malikin-nās", teksIndonesia: "Raja manusia,", audioUrl: "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114002.mp3"),
        Ayat(suratId: idSurah, nomor: 3, teksArab: "اِلٰهِ النَّاسِۙ", teksLatin: "Ilāhin-nās", teksIndonesia: "sembahan manusia,", audioUrl: "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114003.mp3"),
        Ayat(suratId: idSurah, nomor: 4, teksArab: "مِنْ شَرِّ الْوَسْوَاسِ ەۙ الْخَنَّاسِۖ", teksLatin: "Min syarril-waswāsil-khannās", teksIndonesia: "dari kejahatan (bisikan) setan yang bersembunyi,", audioUrl: "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114004.mp3"),
        Ayat(suratId: idSurah, nomor: 5, teksArab: "الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِۙ", teksLatin: "Allażī yuwaswisu fī ṣudụrin-nās", teksIndonesia: "yang membisikkan (kejahatan) ke dalam dada manusia,", audioUrl: "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114005.mp3"),
        Ayat(suratId: idSurah, nomor: 6, teksArab: "مِنَ الْجِنَّةِ وَالنَّاسِ ࣖ", teksLatin: "Minal-jinnati wan-nās", teksIndonesia: "dari (golongan) jin dan manusia.”", audioUrl: "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114006.mp3"),
    ];

    for (var ayat in ayatAnNaas) {
      await txn.insert(ayatTable, ayat.toMap());
    }

    for (var ayat in ayatAnNaas) {
      await txn.insert(ayatTable, ayat.toMap());
    }
    developer.log("Data ${ayatAnNaas.length} ayat untuk surah An-Nas dimasukkan.");
  });
}

  // --- SEMUA FUNGSI LAMA ANDA TETAP ADA DI BAWAH INI ---
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
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
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> deleteDatabaseFile() async {
    // Tutup koneksi database sebelum menghapus file
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
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

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      usersTable,
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

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

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      usersTable,
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  
  Future<List<Map<String, dynamic>>> querySemuaSurah() async {
    Database db = await instance.database;
    return await db.query(surahTable);
  }

  Future<List<Map<String, dynamic>>> queryAyatBySurah(int idSurah) async {
    Database db = await instance.database;
    return await db.query(
      ayatTable,
      where: 'surat_id = ?',
      whereArgs: [idSurah],
      orderBy: 'nomor ASC',
    );
  }
}