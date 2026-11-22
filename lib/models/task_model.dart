import 'mata_kuliah_model.dart';
import 'pemahaman.dart';

enum TaskStatus { todo, inProgress, completed }

enum UrgencyLevel { kritis, dekat, santai }

class TaskModel {
  TaskModel({
    required this.id,
    required this.title,
    required this.mataKuliah,
    required this.deadline,
    this.description = '',
    this.pemahaman = 3,
    this.status = TaskStatus.todo,
  });

  final String id;
  final String title;
  final MataKuliahModel mataKuliah;
  final DateTime deadline;
  final String description;
  final int pemahaman;
  TaskStatus status;

  /// Menghitung sisa hari menuju deadline (minimal 1 hari untuk mencegah pembagian 0)
  int get sisaHari {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = target.difference(today).inDays;
    return diff <= 0 ? 1 : diff;
  }

  /// Rumus Prioritas UAS: skor = (sks * (6 - pemahaman)) / sisa_hari
  double get skorPrioritas {
    final bobotPemahaman = Pemahaman.bobot(pemahaman);
    return (mataKuliah.sks * bobotPemahaman) / sisaHari;
  }

  /// Urgensi statis awal per item, atau dievaluasi relatif terhadap skor tertinggi di controller/view
  UrgencyLevel get urgensi {
    if (sisaHari <= 1 || skorPrioritas >= 6.0) {
      return UrgencyLevel.kritis;
    } else if (sisaHari <= 3 || skorPrioritas >= 3.0) {
      return UrgencyLevel.dekat;
    } else {
      return UrgencyLevel.santai;
    }
  }

  /// Membaca satu tugas dari JSON server.
  ///
  /// Bentuk JSON: {
  ///   "id": "...", "title": "...", "deadline": "2026-11-25T15:00:00.000Z",
  ///   "description": "...", "pemahaman": 2, "status": "todo",
  ///   "mataKuliah": { "id": "...", "nama": "...", "sks": 3 }
  /// }
  ///
  /// `mataKuliah` datang bersarang, jadi langsung dipetakan ke objek —
  /// dengan begitu `skorPrioritas` bisa dihitung tanpa request tambahan.
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      mataKuliah: MataKuliahModel.fromJson(
        json['mataKuliah'] as Map<String, dynamic>,
      ),
      // Server mengirim ISO 8601 UTC. toLocal() supaya sisaHari dan
      // tampilan tanggal mengikuti zona waktu perangkat, bukan UTC.
      deadline: DateTime.parse(json['deadline'] as String).toLocal(),
      description: (json['description'] as String?) ?? '',
      pemahaman: (json['pemahaman'] as num).toInt(),
      status: _statusFromString(json['status'] as String),
    );
  }

  /// Bentuk bersarang — dipakai kalau perlu menyimpan/mengirim objek utuh
  /// (mis. cache lokal, atau menyalin tugas ke tempat lain).
  ///
  /// Untuk body POST/PUT ke server pakai [toRequestJson], karena server
  /// mengharapkan `mataKuliahId` datar, bukan objek bersarang.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'mataKuliah': mataKuliah.toJson(),
      'deadline': deadline.toUtc().toIso8601String(),
      'description': description,
      'pemahaman': pemahaman,
      'status': _statusToString(status),
    };
  }

  /// Bentuk datar sesuai kontrak POST/PUT/PATCH /api/tugas.
  ///
  /// Dua bentuk ini sengaja dipisah: kalau digabung jadi satu, salah satu
  /// arah pasti rusak — server menolak `mataKuliah` berupa objek, dan
  /// `fromJson` butuh objek bersarang untuk mengisi `mataKuliah.nama/sks`.
  Map<String, dynamic> toRequestJson() {
    return {
      'title': title,
      'mataKuliahId': mataKuliah.id,
      'deadline': deadline.toUtc().toIso8601String(),
      'description': description,
      'pemahaman': pemahaman,
      'status': _statusToString(status),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    MataKuliahModel? mataKuliah,
    DateTime? deadline,
    String? description,
    int? pemahaman,
    TaskStatus? status,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      mataKuliah: mataKuliah ?? this.mataKuliah,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      pemahaman: pemahaman ?? this.pemahaman,
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'TaskModel($id, $title, ${mataKuliah.nama}, status: $status)';

  // --- Pemetaan enum <-> string -------------------------------------------
  //
  // Nilai string HARUS sama dengan yang dipakai backend
  // (lihat CHECK constraint pada kolom `status` di backend/db/schema.sql).
  //
  // Sengaja pakai switch eksplisit, bukan TaskStatus.values.byName():
  // byName() melempar ArgumentError yang tidak informatif kalau server
  // mengirim nilai baru, sedangkan di sini pesannya jelas dan mudah dilacak.

  static TaskStatus _statusFromString(String value) {
    switch (value) {
      case 'todo':
        return TaskStatus.todo;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        throw FormatException('Status tugas tidak dikenal dari server: "$value"');
    }
  }

  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'inProgress';
      case TaskStatus.completed:
        return 'completed';
    }
  }
}
