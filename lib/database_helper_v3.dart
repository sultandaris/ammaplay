import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'models/quran.dart';
import 'models/family_models.dart';

class DatabaseHelperV3 {
  static const _databaseName = "amma_v3.db";
  static const _databaseVersion = 1;

  // Table names
  static const settingsTable = 'settings';
  static const usersTable = 'users';
  static const surahTable = 'surat';
  static const ayatTable = 'ayat';
  static const levelTable = 'level';
  static const progresTable = 'progres_pengguna';
  static const kontrolOrangTuaTable = 'kontrol_orangtua';

  DatabaseHelperV3._privateConstructor();
  static final DatabaseHelperV3 instance =
      DatabaseHelperV3._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    developer.log("Database path: ${documentsDirectory.path}/$_databaseName");

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Settings table
    await db.execute('''
      CREATE TABLE $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Enhanced users table with family features
    await db.execute('''
      CREATE TABLE $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pengguna TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        hash_password TEXT NOT NULL,
        hash_pin_orangtua TEXT NOT NULL,
        dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Level table for surah grouping
    await db.execute('''
      CREATE TABLE $levelTable (
        id_level INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_level TEXT NOT NULL,
        deskripsi TEXT
      )
    ''');

    // Enhanced surah table with level relationship
    await db.execute('''
      CREATE TABLE $surahTable (
        id_surat INTEGER PRIMARY KEY,
        nama_latin TEXT NOT NULL,
        nama_arab TEXT NOT NULL,
        jumlah_ayat INTEGER NOT NULL,
        arti_nama TEXT,
        id_level INTEGER NOT NULL,
        urutan_di_level INTEGER NOT NULL,
        FOREIGN KEY(id_level) REFERENCES $levelTable(id_level)
      )
    ''');

    // Ayat table (compatible with existing structure)
    await db.execute('''
      CREATE TABLE $ayatTable (
        ayat_id INTEGER PRIMARY KEY AUTOINCREMENT,
        surat_id INTEGER NOT NULL,
        nomor INTEGER NOT NULL,
        teks_arab TEXT NOT NULL,
        teks_latin TEXT NOT NULL,
        teks_indonesia TEXT NOT NULL,
        audio_url TEXT NOT NULL,
        FOREIGN KEY(surat_id) REFERENCES $surahTable(id_surat)
      )
    ''');

    // Progress tracking table
    await db.execute('''
      CREATE TABLE $progresTable (
        id_pengguna INTEGER NOT NULL,
        id_surat INTEGER NOT NULL,
        total_bintang INTEGER NOT NULL DEFAULT 0,
        terakhir_diperbarui TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (id_pengguna, id_surat),
        FOREIGN KEY(id_pengguna) REFERENCES $usersTable(id),
        FOREIGN KEY(id_surat) REFERENCES $surahTable(id_surat)
      )
    ''');

    // Parental controls table
    await db.execute('''
      CREATE TABLE $kontrolOrangTuaTable (
        id_pengguna INTEGER PRIMARY KEY,
        batas_waktu_menit INTEGER NOT NULL DEFAULT 0,
        notifikasi_solat_aktif INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(id_pengguna) REFERENCES $usersTable(id)
      )
    ''');

    // Insert default settings
    await db.execute('''
      INSERT INTO $settingsTable (key, value) VALUES
      ('sound', 'on'),
      ('notifications', 'on'),
      ('font_size', 'medium')
    ''');

    // Initialize data
    await _insertDefaultLevels(db);
    await _insertDefaultSurahs(db);

    developer.log("Database V3 created successfully");
  }

  Future<void> _insertDefaultLevels(Database db) async {
    final levels = [
      Level(
        idLevel: 1,
        namaLevel: 'Surat Pendek',
        deskripsi: 'Surat-surat pendek untuk pemula',
      ),
      Level(
        idLevel: 2,
        namaLevel: 'Surat Menengah',
        deskripsi: 'Surat-surat dengan tingkat kesulitan menengah',
      ),
    ];

    for (final level in levels) {
      await db.insert(levelTable, level.toMap());
    }
    developer.log("Default levels inserted");
  }

  Future<void> _insertDefaultSurahs(Database db) async {
    await db.transaction((txn) async {
      // Insert Enhanced Surahs
      final surahs = [
        EnhancedSurah(
          idSurat: 114,
          namaLatin: "An-Nas",
          namaArab: "النَّاس",
          jumlahAyat: 6,
          artiNama: "Manusia",
          idLevel: 1,
          urutanDiLevel: 1,
        ),
        EnhancedSurah(
          idSurat: 113,
          namaLatin: "Al-Falaq",
          namaArab: "الْفَلَق",
          jumlahAyat: 5,
          artiNama: "Fajar",
          idLevel: 1,
          urutanDiLevel: 2,
        ),
        EnhancedSurah(
          idSurat: 108,
          namaLatin: "Al-Kautsar",
          namaArab: "الْكَوْثَر",
          jumlahAyat: 3,
          artiNama: "Nikmat yang Banyak",
          idLevel: 1,
          urutanDiLevel: 3,
        ),
      ];

      for (final surah in surahs) {
        await txn.insert(surahTable, surah.toMap());
      }

      // Insert Ayat data
      await _insertAyatAnNas(txn);
      await _insertAyatAlFalaq(txn);
      await _insertAyatAlKautsar(txn);

      developer.log("Default surahs and ayat inserted");
    });
  }

  Future<void> _insertAyatAnNas(Transaction txn) async {
    final ayatList = [
      Ayat(
        suratId: 114,
        nomor: 1,
        teksArab: "قُلْ اَعُوْذُ بِرَبِّ النَّاسِۙ",
        teksLatin: "Qul a'ụżu birabbin-nās",
        teksIndonesia: "Katakanlah: \"Aku berlindung kepada Tuhannya manusia,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114001.mp3",
      ),
      Ayat(
        suratId: 114,
        nomor: 2,
        teksArab: "مَلِكِ النَّاسِۙ",
        teksLatin: "Malikin-nās",
        teksIndonesia: "Raja manusia,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114002.mp3",
      ),
      Ayat(
        suratId: 114,
        nomor: 3,
        teksArab: "اِلٰهِ النَّاسِۙ",
        teksLatin: "Ilāhin-nās",
        teksIndonesia: "sembahan manusia,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114003.mp3",
      ),
      Ayat(
        suratId: 114,
        nomor: 4,
        teksArab: "مِنْ شَرِّ الْوَسْوَاسِ ەۙ الْخَنَّاسِۖ",
        teksLatin: "Min syarril-waswāsil-khannās",
        teksIndonesia: "dari kejahatan (bisikan) setan yang bersembunyi,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114004.mp3",
      ),
      Ayat(
        suratId: 114,
        nomor: 5,
        teksArab: "الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِۙ",
        teksLatin: "Allażī yuwaswisu fī ṣudụrin-nās",
        teksIndonesia: "yang membisikkan (kejahatan) ke dalam dada manusia,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114005.mp3",
      ),
      Ayat(
        suratId: 114,
        nomor: 6,
        teksArab: "مِنَ الْجِنَّةِ وَالنَّاسِ ࣖ",
        teksLatin: "Minal-jinnati wan-nās",
        teksIndonesia: "dari (golongan) jin dan manusia.\"",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/114006.mp3",
      ),
    ];

    for (final ayat in ayatList) {
      await txn.insert(ayatTable, ayat.toMap());
    }
  }

  Future<void> _insertAyatAlFalaq(Transaction txn) async {
    final ayatList = [
      Ayat(
        suratId: 113,
        nomor: 1,
        teksArab: "قُلْ اَعُوْذُ بِرَبِّ الْفَلَقِۙ",
        teksLatin: "Qul a'ụżu birabbil-falaq",
        teksIndonesia:
            "Katakanlah: \"Aku berlindung kepada Tuhan yang menguasai fajar,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/113001.mp3",
      ),
      Ayat(
        suratId: 113,
        nomor: 2,
        teksArab: "مِنْ شَرِّ مَا خَلَقَۙ",
        teksLatin: "Min syarri mā khalaq",
        teksIndonesia: "dari kejahatan apa yang Dia ciptakan,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/113002.mp3",
      ),
      Ayat(
        suratId: 113,
        nomor: 3,
        teksArab: "وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَۙ",
        teksLatin: "Wa min syarri ghāsiqin iżā waqab",
        teksIndonesia:
            "dan dari kejahatan malam yang gelap gulita apabila telah tiba,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/113003.mp3",
      ),
      Ayat(
        suratId: 113,
        nomor: 4,
        teksArab: "وَمِنْ شَرِّ النَّفّٰثٰتِ فِى الْعُقَدِۙ",
        teksLatin: "Wa min syarrin-naffāṡāti fil-'uqad",
        teksIndonesia:
            "dan dari kejahatan para tukang sihir wanita yang meniup pada buhul-buhul,",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/113004.mp3",
      ),
      Ayat(
        suratId: 113,
        nomor: 5,
        teksArab: "وَمِنْ شَرِّ حَاسِدٍ اِذَا حَسَدَ ࣖ",
        teksLatin: "Wa min syarri ḥāsidin iżā ḥasad",
        teksIndonesia:
            "dan dari kejahatan orang yang dengki apabila dia dengki.\"",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/113005.mp3",
      ),
    ];

    for (final ayat in ayatList) {
      await txn.insert(ayatTable, ayat.toMap());
    }
  }

  Future<void> _insertAyatAlKautsar(Transaction txn) async {
    final ayatList = [
      Ayat(
        suratId: 108,
        nomor: 1,
        teksArab: "اِنَّآ اَعْطَيْنٰكَ الْكَوْثَرَۗ",
        teksLatin: "Innā a'ṭainākal-kauṡar",
        teksIndonesia:
            "Sesungguhnya Kami telah memberikan kepadamu nikmat yang banyak.",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/108001.mp3",
      ),
      Ayat(
        suratId: 108,
        nomor: 2,
        teksArab: "فَصَلِّ لِرَبِّكَ وَانْحَرْۗ",
        teksLatin: "Fa ṣalli lirabbika wanḥar",
        teksIndonesia:
            "Maka laksanakanlah shalat karena Tuhanmu, dan berkorbanlah!",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/108002.mp3",
      ),
      Ayat(
        suratId: 108,
        nomor: 3,
        teksArab: "اِنَّ شَانِئَكَ هُوَ الْاَبْتَرُ ࣖ",
        teksLatin: "Inna syāni'aka huwal-abtar",
        teksIndonesia:
            "Sesungguhnya orang-orang yang membenci kamu dialah yang terputus.",
        audioUrl:
            "https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/108003.mp3",
      ),
    ];

    for (final ayat in ayatList) {
      await txn.insert(ayatTable, ayat.toMap());
    }
  }

  // --- FAMILY USER METHODS ---

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> createFamilyAccount({
    required String namaPengguna,
    required String email,
    required String password,
    required String pinOrangtua,
  }) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);
    final hashedPin = _hashPassword(pinOrangtua);

    try {
      final userId = await db.insert(usersTable, {
        'nama_pengguna': namaPengguna,
        'email': email,
        'hash_password': hashedPassword,
        'hash_pin_orangtua': hashedPin,
        'dibuat_pada': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.fail);

      // Create default parental controls
      await db.insert(kontrolOrangTuaTable, {
        'id_pengguna': userId,
        'batas_waktu_menit': 60, // Default 1 hour
        'notifikasi_solat_aktif': 1,
      });

      developer.log("Family account created with ID: $userId");
      return true;
    } catch (e) {
      developer.log("Error creating family account: $e");
      return false;
    }
  }

  Future<FamilyUser?> loginFamily(String email, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);

    try {
      final result = await db.query(
        usersTable,
        where: 'email = ? AND hash_password = ?',
        whereArgs: [email, hashedPassword],
      );

      if (result.isNotEmpty) {
        return FamilyUser.fromMap(result.first);
      }
      return null;
    } catch (e) {
      developer.log("Login error: $e");
      return null;
    }
  }

  Future<bool> verifyParentPin(int userId, String pin) async {
    final db = await database;
    final hashedPin = _hashPassword(pin);

    try {
      final result = await db.query(
        usersTable,
        columns: ['id'],
        where: 'id = ? AND hash_pin_orangtua = ?',
        whereArgs: [userId, hashedPin],
      );

      return result.isNotEmpty;
    } catch (e) {
      developer.log("PIN verification error: $e");
      return false;
    }
  }

  // --- LEVEL AND SURAH METHODS ---

  Future<List<Level>> getAllLevels() async {
    final db = await database;
    final result = await db.query(levelTable, orderBy: 'id_level ASC');
    return result.map((map) => Level.fromMap(map)).toList();
  }

  Future<List<EnhancedSurah>> getSurahsByLevel(int levelId) async {
    final db = await database;
    final result = await db.query(
      surahTable,
      where: 'id_level = ?',
      whereArgs: [levelId],
      orderBy: 'urutan_di_level ASC',
    );
    return result.map((map) => EnhancedSurah.fromMap(map)).toList();
  }

  Future<List<SurahWithProgress>> getSurahsWithProgress(
    int userId, {
    int? levelId,
  }) async {
    final db = await database;

    String whereClause = levelId != null ? 'WHERE s.id_level = ?' : '';
    List<dynamic> whereArgs = levelId != null ? [levelId] : [];

    final result = await db.rawQuery(
      '''
      SELECT 
        s.*, 
        l.*,
        p.total_bintang,
        p.terakhir_diperbarui
      FROM $surahTable s
      JOIN $levelTable l ON s.id_level = l.id_level
      LEFT JOIN $progresTable p ON s.id_surat = p.id_surat AND p.id_pengguna = ?
      $whereClause
      ORDER BY s.id_level ASC, s.urutan_di_level ASC
    ''',
      [userId, ...whereArgs],
    );

    return result.map((row) {
      final surah = EnhancedSurah.fromMap(row);
      final level = Level.fromMap(row);
      final progres = row['total_bintang'] != null
          ? ProgresPengguna.fromMap(row)
          : null;

      // Simple unlock logic: first surah in each level is always unlocked
      // Others are unlocked if previous surah has at least 1 star
      bool isUnlocked = surah.urutanDiLevel == 1;

      return SurahWithProgress(
        surah: surah,
        level: level,
        progres: progres,
        isUnlocked: isUnlocked,
      );
    }).toList();
  }

  // --- PROGRESS METHODS ---

  Future<bool> updateProgress(int userId, int surahId, int stars) async {
    final db = await database;

    try {
      await db.insert(progresTable, {
        'id_pengguna': userId,
        'id_surat': surahId,
        'total_bintang': stars,
        'terakhir_diperbarui': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      developer.log(
        "Progress updated: User $userId, Surah $surahId, Stars: $stars",
      );
      return true;
    } catch (e) {
      developer.log("Error updating progress: $e");
      return false;
    }
  }

  Future<ProgresPengguna?> getProgress(int userId, int surahId) async {
    final db = await database;

    try {
      final result = await db.query(
        progresTable,
        where: 'id_pengguna = ? AND id_surat = ?',
        whereArgs: [userId, surahId],
      );

      if (result.isNotEmpty) {
        return ProgresPengguna.fromMap(result.first);
      }
      return null;
    } catch (e) {
      developer.log("Error getting progress: $e");
      return null;
    }
  }

  Future<List<ProgresPengguna>> getUserProgress(int userId) async {
    final db = await database;

    try {
      final result = await db.query(
        progresTable,
        where: 'id_pengguna = ?',
        whereArgs: [userId],
        orderBy: 'terakhir_diperbarui DESC',
      );

      return result.map((map) => ProgresPengguna.fromMap(map)).toList();
    } catch (e) {
      developer.log("Error getting user progress: $e");
      return [];
    }
  }

  // --- PARENTAL CONTROL METHODS ---

  Future<KontrolOrangTua?> getParentalControls(int userId) async {
    final db = await database;

    try {
      final result = await db.query(
        kontrolOrangTuaTable,
        where: 'id_pengguna = ?',
        whereArgs: [userId],
      );

      if (result.isNotEmpty) {
        return KontrolOrangTua.fromMap(result.first);
      }
      return null;
    } catch (e) {
      developer.log("Error getting parental controls: $e");
      return null;
    }
  }

  Future<bool> updateParentalControls(KontrolOrangTua controls) async {
    final db = await database;

    try {
      await db.insert(
        kontrolOrangTuaTable,
        controls.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      developer.log(
        "Parental controls updated for user ${controls.idPengguna}",
      );
      return true;
    } catch (e) {
      developer.log("Error updating parental controls: $e");
      return false;
    }
  }

  // --- AYAT METHODS (Compatible with existing code) ---

  Future<List<Map<String, dynamic>>> queryAyatBySurah(int surahId) async {
    final db = await database;
    return await db.query(
      ayatTable,
      where: 'surat_id = ?',
      whereArgs: [surahId],
      orderBy: 'nomor ASC',
    );
  }

  // --- SETTINGS METHODS ---

  Future<int> updateSetting(String key, String value) async {
    final db = await database;
    return await db.insert(settingsTable, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      settingsTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  // --- USER PROFILE UPDATE METHODS ---

  Future<bool> updateFamilyUserProfile({
    required int userId,
    String? newNamaPengguna,
    String? newEmail,
  }) async {
    final db = await database;

    try {
      Map<String, dynamic> updates = {};
      if (newNamaPengguna != null) updates['nama_pengguna'] = newNamaPengguna;
      if (newEmail != null) updates['email'] = newEmail;

      if (updates.isEmpty) return false;

      final rowsUpdated = await db.update(
        usersTable,
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (rowsUpdated > 0) {
        developer.log(
          "Family user profile updated: ID $userId, Updates: $updates",
        );
        return true;
      }
      return false;
    } catch (e) {
      developer.log("Error updating family user profile: $e");
      return false;
    }
  }

  // --- UTILITY METHODS ---

  Future<void> deleteDatabaseFile() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
      developer.log("Database V3 deleted: $path");
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
