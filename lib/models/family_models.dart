// Enhanced models for family learning system

class FamilyUser {
  final int? idPengguna;
  final String namaPengguna;
  final String email;
  final String hashPassword;
  final String hashPinOrangtua;
  final DateTime? dibuatPada;

  const FamilyUser({
    this.idPengguna,
    required this.namaPengguna,
    required this.email,
    required this.hashPassword,
    required this.hashPinOrangtua,
    this.dibuatPada,
  });

  FamilyUser copyWith({
    int? idPengguna,
    String? namaPengguna,
    String? email,
    String? hashPassword,
    String? hashPinOrangtua,
    DateTime? dibuatPada,
  }) {
    return FamilyUser(
      idPengguna: idPengguna ?? this.idPengguna,
      namaPengguna: namaPengguna ?? this.namaPengguna,
      email: email ?? this.email,
      hashPassword: hashPassword ?? this.hashPassword,
      hashPinOrangtua: hashPinOrangtua ?? this.hashPinOrangtua,
      dibuatPada: dibuatPada ?? this.dibuatPada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_pengguna': idPengguna,
      'nama_pengguna': namaPengguna,
      'email': email,
      'hash_password': hashPassword,
      'hash_pin_orangtua': hashPinOrangtua,
      'dibuat_pada': dibuatPada?.toIso8601String(),
    };
  }

  factory FamilyUser.fromMap(Map<String, dynamic> map) {
    return FamilyUser(
      idPengguna: map['id']?.toInt(), // Database uses 'id', not 'id_pengguna'
      namaPengguna: map['nama_pengguna'] ?? '',
      email: map['email'] ?? '',
      hashPassword: map['hash_password'] ?? '',
      hashPinOrangtua: map['hash_pin_orangtua'] ?? '',
      dibuatPada: map['dibuat_pada'] != null
          ? DateTime.parse(map['dibuat_pada'])
          : null,
    );
  }

  @override
  String toString() {
    return 'FamilyUser(idPengguna: $idPengguna, namaPengguna: $namaPengguna, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyUser &&
        other.idPengguna == idPengguna &&
        other.namaPengguna == namaPengguna &&
        other.email == email;
  }

  @override
  int get hashCode {
    return idPengguna.hashCode ^ namaPengguna.hashCode ^ email.hashCode;
  }
}

class Level {
  final int idLevel;
  final String namaLevel;
  final String? deskripsi;

  const Level({required this.idLevel, required this.namaLevel, this.deskripsi});

  Map<String, dynamic> toMap() {
    return {
      'id_level': idLevel,
      'nama_level': namaLevel,
      'deskripsi': deskripsi,
    };
  }

  factory Level.fromMap(Map<String, dynamic> map) {
    return Level(
      idLevel: map['id_level']?.toInt() ?? 0,
      namaLevel: map['nama_level'] ?? '',
      deskripsi: map['deskripsi'],
    );
  }

  @override
  String toString() {
    return 'Level(idLevel: $idLevel, namaLevel: $namaLevel, deskripsi: $deskripsi)';
  }
}

class EnhancedSurah {
  final int idSurat;
  final String namaLatin;
  final String namaArab;
  final int jumlahAyat;
  final String? artiNama;
  final int idLevel;
  final int urutanDiLevel;

  const EnhancedSurah({
    required this.idSurat,
    required this.namaLatin,
    required this.namaArab,
    required this.jumlahAyat,
    this.artiNama,
    required this.idLevel,
    required this.urutanDiLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_surat': idSurat,
      'nama_latin': namaLatin,
      'nama_arab': namaArab,
      'jumlah_ayat': jumlahAyat,
      'arti_nama': artiNama,
      'id_level': idLevel,
      'urutan_di_level': urutanDiLevel,
    };
  }

  factory EnhancedSurah.fromMap(Map<String, dynamic> map) {
    return EnhancedSurah(
      idSurat: map['id_surat']?.toInt() ?? 0,
      namaLatin: map['nama_latin'] ?? '',
      namaArab: map['nama_arab'] ?? '',
      jumlahAyat: map['jumlah_ayat']?.toInt() ?? 0,
      artiNama: map['arti_nama'],
      idLevel: map['id_level']?.toInt() ?? 1,
      urutanDiLevel: map['urutan_di_level']?.toInt() ?? 1,
    );
  }

  @override
  String toString() {
    return 'EnhancedSurah(idSurat: $idSurat, namaLatin: $namaLatin, namaArab: $namaArab)';
  }
}

class ProgresPengguna {
  final int idPengguna;
  final int idSurat;
  final int totalBintang;
  final DateTime? terakhirDiperbarui;

  const ProgresPengguna({
    required this.idPengguna,
    required this.idSurat,
    required this.totalBintang,
    this.terakhirDiperbarui,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_pengguna': idPengguna,
      'id_surat': idSurat,
      'total_bintang': totalBintang,
      'terakhir_diperbarui': terakhirDiperbarui?.toIso8601String(),
    };
  }

  factory ProgresPengguna.fromMap(Map<String, dynamic> map) {
    return ProgresPengguna(
      idPengguna: map['id_pengguna']?.toInt() ?? 0,
      idSurat: map['id_surat']?.toInt() ?? 0,
      totalBintang: map['total_bintang']?.toInt() ?? 0,
      terakhirDiperbarui: map['terakhir_diperbarui'] != null
          ? DateTime.parse(map['terakhir_diperbarui'])
          : null,
    );
  }

  ProgresPengguna copyWith({
    int? idPengguna,
    int? idSurat,
    int? totalBintang,
    DateTime? terakhirDiperbarui,
  }) {
    return ProgresPengguna(
      idPengguna: idPengguna ?? this.idPengguna,
      idSurat: idSurat ?? this.idSurat,
      totalBintang: totalBintang ?? this.totalBintang,
      terakhirDiperbarui: terakhirDiperbarui ?? this.terakhirDiperbarui,
    );
  }

  @override
  String toString() {
    return 'ProgresPengguna(idPengguna: $idPengguna, idSurat: $idSurat, totalBintang: $totalBintang)';
  }
}

class KontrolOrangTua {
  final int idPengguna;
  final int batasWaktuMenit;
  final bool notifikasiSolatAktif;

  const KontrolOrangTua({
    required this.idPengguna,
    required this.batasWaktuMenit,
    required this.notifikasiSolatAktif,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_pengguna': idPengguna,
      'batas_waktu_menit': batasWaktuMenit,
      'notifikasi_solat_aktif': notifikasiSolatAktif ? 1 : 0,
    };
  }

  factory KontrolOrangTua.fromMap(Map<String, dynamic> map) {
    return KontrolOrangTua(
      idPengguna: map['id_pengguna']?.toInt() ?? 0,
      batasWaktuMenit: map['batas_waktu_menit']?.toInt() ?? 0,
      notifikasiSolatAktif: (map['notifikasi_solat_aktif'] ?? 1) == 1,
    );
  }

  KontrolOrangTua copyWith({
    int? idPengguna,
    int? batasWaktuMenit,
    bool? notifikasiSolatAktif,
  }) {
    return KontrolOrangTua(
      idPengguna: idPengguna ?? this.idPengguna,
      batasWaktuMenit: batasWaktuMenit ?? this.batasWaktuMenit,
      notifikasiSolatAktif: notifikasiSolatAktif ?? this.notifikasiSolatAktif,
    );
  }

  @override
  String toString() {
    return 'KontrolOrangTua(idPengguna: $idPengguna, batasWaktu: $batasWaktuMenit, notifikasi: $notifikasiSolatAktif)';
  }
}

// Data class to combine Surah with progress information
class SurahWithProgress {
  final EnhancedSurah surah;
  final Level level;
  final ProgresPengguna? progres;
  final bool isUnlocked;

  const SurahWithProgress({
    required this.surah,
    required this.level,
    this.progres,
    required this.isUnlocked,
  });

  @override
  String toString() {
    return 'SurahWithProgress(surah: ${surah.namaLatin}, level: ${level.namaLevel}, stars: ${progres?.totalBintang ?? 0})';
  }
}
