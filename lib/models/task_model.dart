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
}
