class MataKuliahModel {
  MataKuliahModel({
    required this.id,
    required this.nama,
    required this.sks,
  });

  final String id;
  final String nama;
  final int sks;

  MataKuliahModel copyWith({
    String? id,
    String? nama,
    int? sks,
  }) {
    return MataKuliahModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      sks: sks ?? this.sks,
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
}
