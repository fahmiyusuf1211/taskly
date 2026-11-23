import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/mata_kuliah_model.dart';
import '../models/task_model.dart';
import '../widgets/neo_card.dart';

class MataKuliahScreen extends StatelessWidget {
  const MataKuliahScreen({
    super.key,
    required this.mataKuliahList,
    required this.tasks,
    required this.onAddMataKuliah,
    required this.onUpdateMataKuliah,
    required this.onDeleteMataKuliah,
  });

  final List<MataKuliahModel> mataKuliahList;
  final List<TaskModel> tasks;
  final ValueChanged<MataKuliahModel> onAddMataKuliah;
  final ValueChanged<MataKuliahModel> onUpdateMataKuliah;
  final ValueChanged<String> onDeleteMataKuliah;

  int _countTasksFor(String mataKuliahId) {
    return tasks.where((t) => t.mataKuliah.id == mataKuliahId).length;
  }

  void _showFormDialog(BuildContext context, [MataKuliahModel? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.nama ?? '');
    int selectedSks = existing?.sks ?? 3;
    final isEditing = existing != null;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.ink, width: 2),
              ),
              title: Text(
                isEditing ? 'Ubah Mata Kuliah' : 'Tambah Mata Kuliah',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Mata Kuliah',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Pemrograman Mobile',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama mata kuliah wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Bobot SKS (1 - 6)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedSks,
                          isExpanded: true,
                          items: [1, 2, 3, 4, 5, 6].map((sks) {
                            return DropdownMenuItem<int>(
                              value: sks,
                              child: Text('$sks SKS ${sks >= 4 ? '(Bobot Tinggi)' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                            );
                          }).toList(),
                          onChanged: (newSks) {
                            if (newSks != null) {
                              setDialogState(() => selectedSks = newSks);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal',
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.ink, width: 1.5),
                    ),
                  ),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (isEditing) {
                      final updated = existing.copyWith(
                        nama: nameController.text.trim(),
                        sks: selectedSks,
                      );
                      onUpdateMataKuliah(updated);
                    } else {
                      final newMk = MataKuliahModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nama: nameController.text.trim(),
                        sks: selectedSks,
                      );
                      onAddMataKuliah(newMk);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Mata kuliah berhasil diperbarui'
                              : 'Mata kuliah berhasil ditambahkan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppColors.ink,
                      ),
                    );
                  },
                  child: Text(isEditing ? 'Perbarui' : 'Simpan',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MataKuliahModel mk) {
    final taskCount = _countTasksFor(mk.id);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.ink, width: 2),
          ),
          title: const Text('Hapus Mata Kuliah?',
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus "${mk.nama}" (${mk.sks} SKS)?',
                style: const TextStyle(fontSize: 14),
              ),
              if (taskCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ink, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.ink),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Peringatan: $taskCount tugas di dalamnya akan ikut terhapus (Cascade Delete)!',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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
                onDeleteMataKuliah(mk.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mata kuliah "${mk.nama}" berhasil dihapus.',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.ink,
                  ),
                );
              },
              child: const Text('Hapus Permanen',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Mata Kuliah', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mata Kuliah',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${mataKuliahList.length} mata kuliah tersimpan',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          NeoCard(
            color: AppColors.surfaceBlue,
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined, size: 30, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('KOMPONEN BOBOT PRIORITAS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 1)),
                      SizedBox(height: 2),
                      Text('SKS adalah pembilang utama rumus prioritas. Makin besar SKS, tugas makin mendesak dikerjakan.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (mataKuliahList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: NeoCard(
                  child: Column(
                    children: const [
                      Icon(Icons.menu_book_outlined, size: 40, color: AppColors.muted),
                      SizedBox(height: 10),
                      Text('Belum ada mata kuliah tersimpan.',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('Tekan tombol di bawah untuk menambah.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...mataKuliahList.map((mk) {
              final taskCount = _countTasksFor(mk.id);
              final isHighSks = mk.sks >= 4;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeoCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isHighSks ? AppColors.yellow : AppColors.mint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Text(
                          '${mk.sks} SKS',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mk.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$taskCount tugas terikat',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit Mata Kuliah',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showFormDialog(context, mk),
                      ),
                      IconButton(
                        tooltip: 'Hapus Mata Kuliah',
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmDialog(context, mk),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
