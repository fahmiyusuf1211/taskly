class Pemahaman {
  static const Map<int, String> label = {
    1: 'Belum tersentuh',
    2: 'Masih bingung',
    3: 'Paham konsep',
    4: 'Bisa, perlu contekan',
    5: 'Sudah lancar',
  };

  static const Map<int, String> arti = {
    1: 'Belum buka materi atau baca soalnya sama sekali',
    2: 'Sudah baca sekilas, tapi belum menangkap intinya',
    3: 'Mengerti teorinya, belum bisa mengerjakan sendiri',
    4: 'Bisa mengerjakan, masih perlu buka referensi',
    5: 'Bisa mengerjakan tanpa bantuan',
  };

  /// Rumus bobot prioritas: makin rendah pemahaman, makin besar bobot urgensinya.
  static int bobot(int nilaiPemahaman) {
    final clamped = nilaiPemahaman.clamp(1, 5);
    return 6 - clamped;
  }
}
