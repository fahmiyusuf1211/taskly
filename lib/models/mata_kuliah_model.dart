class MataKuliahModel {
  MataKuliahModel({
    required this.id,
    required this.nama,
    required this.sks,
    this.jumlahTugas = 0,
  });

  final String id;
  final String nama;
  final int sks;

  /// Jumlah tugas yang memakai mata kuliah ini.
  /// Hanya diisi oleh GET /api/mata-kuliah (server menghitungnya lewat JOIN);
  /// pada objek yang dibuat lokal nilainya 0 dan tidak dipakai untuk apa pun
  /// selain tampilan daftar.
  final int jumlahTugas;

  /// Membaca satu mata kuliah dari JSON server.
  ///
  /// Bentuk JSON: { "id": "...", "nama": "Pemrograman Mobile", "sks": 3,
  ///                "jumlahTugas": 2 }
  factory MataKuliahModel.fromJson(Map<String, dynamic> json) {
    return MataKuliahModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      // sks dikirim sebagai angka JSON; toInt() menjaga kalau nilainya
      // datang sebagai double (mis. 3.0 dari beberapa encoder).
      sks: (json['sks'] as num).toInt(),
      jumlahTugas: (json['jumlahTugas'] as num?)?.toInt() ?? 0,
    );
  }

  /// Bentuk yang dikirim ke server saat POST/PUT /api/mata-kuliah.
  ///
  /// `id` dan `jumlahTugas` sengaja tidak disertakan: id dibuat database,
  /// jumlahTugas hasil hitungan server.
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'sks': sks,
    };
  }

  MataKuliahModel copyWith({
    String? id,
    String? nama,
    int? sks,
    int? jumlahTugas,
  }) {
    return MataKuliahModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      sks: sks ?? this.sks,
      jumlahTugas: jumlahTugas ?? this.jumlahTugas,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MataKuliahModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MataKuliahModel($id, $nama, $sks sks)';
}
