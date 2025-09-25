class Surah {
  final int suratId;
  final String nama;
  final String arti;
  final int jumlahAyat;

  Surah({
    required this.suratId,
    required this.nama,
    required this.arti,
    required this.jumlahAyat,
  });

  Map<String, dynamic> toMap() {
    return {
      'surat_id': suratId,
      'nama': nama,
      'arti': arti,
      'jumlah_ayat': jumlahAyat,
    };
  }
}

class Ayat {
  final int? ayatId;
  final int suratId;
  final int nomor;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final String audioUrl; // URL atau path ke file audio

  Ayat({
    this.ayatId,
    required this.suratId,
    required this.nomor,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audioUrl, // Default kosong jika tidak ada
  });

  Map<String, dynamic> toMap() {
    return {
      'ayat_id': ayatId,
      'surat_id': suratId,
      'nomor': nomor,
      'teks_arab': teksArab,
      'teks_latin': teksLatin,
      'teks_indonesia': teksIndonesia,
      'audio_url': audioUrl,
    };
  }
}
