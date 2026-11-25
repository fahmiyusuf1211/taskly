import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/mata_kuliah_model.dart';
import '../models/pemahaman.dart';
import '../models/task_model.dart';
import '../widgets/neo_card.dart';
import 'add_task_screen.dart';

class DetailTaskScreen extends StatefulWidget {
  const DetailTaskScreen({
    super.key,
    required this.task,
    required this.mataKuliahList,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  final TaskModel task;
  final List<MataKuliahModel> mataKuliahList;
  final ValueChanged<TaskModel> onUpdateTask;
  final ValueChanged<String> onDeleteTask;

  @override
  State<DetailTaskScreen> createState() => _DetailTaskScreenState();
}

class _DetailTaskScreenState extends State<DetailTaskScreen> {
  late TaskModel _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  void _toggleStatus() {
    final newStatus = _task.status == TaskStatus.completed
        ? TaskStatus.todo
        : TaskStatus.completed;
    final updated = _task.copyWith(status: newStatus);
    setState(() => _task = updated);
    widget.onUpdateTask(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == TaskStatus.completed
              ? 'Tugas ditandai selesai! 🎉'
              : 'Status tugas diubah menjadi belum selesai.',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  Future<void> _openEdit() async {
    final result = await Get.toNamed<TaskFormResult>(
      AppRoutes.tambahTugas,
      arguments: TambahTugasArgs(
        mataKuliahList: widget.mataKuliahList,
        initialTask: _task,
      ),
    );

    if (!mounted || result == null) return;

    if (result.isDeleted) {
      widget.onDeleteTask(_task.id);
      Get.back();
    } else {
      setState(() => _task = result.task);
      widget.onUpdateTask(result.task);
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: const Text('Hapus Tugas Ini?',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
        content: Text('Tugas "${_task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
            onPressed: () {
              widget.onDeleteTask(_task.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tugas "${_task.title}" berhasil dihapus.'),
                  backgroundColor: AppColors.ink,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sisa = _task.sisaHari;
    final skor = _task.skorPrioritas.toStringAsFixed(1);
    final isDone = _task.status == TaskStatus.completed;

    Color badgeBg;
    String badgeText;
    switch (_task.urgensi) {
      case UrgencyLevel.kritis:
        badgeBg = AppColors.coral;
        badgeText = 'KRITIS';
        break;
      case UrgencyLevel.dekat:
        badgeBg = AppColors.yellow;
        badgeText = 'DEKAT';
        break;
      case UrgencyLevel.santai:
        badgeBg = AppColors.mint;
        badgeText = 'SANTAI';
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Detail Tugas',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
        actions: [
          IconButton(
            tooltip: 'Ubah Tugas',
            icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
            onPressed: _openEdit,
          ),
          IconButton(
            tooltip: 'Hapus Tugas',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          // Banner Countdown Besar (Wireframe P3)
          NeoCard(
            color: _task.urgensi == UrgencyLevel.kritis
                ? AppColors.coral
                : _task.urgensi == UrgencyLevel.dekat
                    ? AppColors.yellow
                    : AppColors.surfaceBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SISA WAKTU DEADLINE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppColors.ink)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        border: Border.all(color: AppColors.ink, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sisa <= 1 ? '$sisa HARI LAGI!' : '$sisa HARI LAGI',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Batas waktu: ${_task.deadline.day}/${_task.deadline.month}/${_task.deadline.year}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Judul dan Status
          NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _task.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.mint : AppColors.surfaceBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ink, width: 1.4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDone ? Icons.check_circle : Icons.pending_outlined,
                            size: 16,
                            color: AppColors.ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isDone ? 'Selesai' : 'Belum Selesai',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.ink, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _toggleStatus,
                      icon: Icon(isDone ? Icons.undo : Icons.check, size: 18),
                      label: Text(
                        isDone ? 'Tandai Belum' : 'Tandai Selesai',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Rincian Formula Matematis
          NeoCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BREAKDOWN FORMULA PRIORITAS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: AppColors.muted)),
                const SizedBox(height: 14),
                _infoRow('Mata Kuliah', '${_task.mataKuliah.nama} (${_task.mataKuliah.sks} SKS)'),
                const Divider(height: 20),
                _infoRow('Tingkat Pemahaman',
                    '${_task.pemahaman} • ${Pemahaman.label[_task.pemahaman]} (Bobot ${Pemahaman.bobot(_task.pemahaman)}x)'),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Arti: "${Pemahaman.arti[_task.pemahaman]}"',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
                  ),
                ),
                const Divider(height: 20),
                _infoRow('Kalkulasi Skor',
                    '(${_task.mataKuliah.sks} SKS × ${Pemahaman.bobot(_task.pemahaman)}) / $sisa hari = $skor'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Deskripsi Lengkap
          NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DESKRIPSI TUGAS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: AppColors.muted)),
                const SizedBox(height: 10),
                Text(
                  _task.description.isEmpty
                      ? '(Tidak ada deskripsi tambahan)'
                      : _task.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _task.description.isEmpty ? AppColors.muted : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
