import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/mata_kuliah_model.dart';
import '../models/pemahaman.dart';
import '../models/task_model.dart';

class TaskFormResult {
  TaskFormResult.saved(this.task) : isDeleted = false;
  TaskFormResult.deleted(this.task) : isDeleted = true;

  final TaskModel task;
  final bool isDeleted;
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({
    super.key,
    required this.mataKuliahList,
    this.initialTask,
  });

  final List<MataKuliahModel> mataKuliahList;
  final TaskModel? initialTask;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  MataKuliahModel? _selectedMataKuliah;
  late DateTime _deadline;
  late int _pemahaman;
  late TaskStatus _status;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _deadline = task?.deadline ?? DateTime.now().add(const Duration(days: 2));
    _pemahaman = task?.pemahaman ?? 3;
    _status = task?.status ?? TaskStatus.todo;

    if (task != null) {
      // Cari instance yang sama dari list jika ada
      final match = widget.mataKuliahList.where((mk) => mk.id == task.mataKuliah.id);
      _selectedMataKuliah = match.isNotEmpty ? match.first : task.mataKuliah;
    } else if (widget.mataKuliahList.isNotEmpty) {
      _selectedMataKuliah = widget.mataKuliahList.first;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
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
        content: Text('Tugas "${widget.initialTask?.title}" akan dihapus permanen.'),
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
              Navigator.pop(ctx); // tutup dialog
              Navigator.pop(context, TaskFormResult.deleted(widget.initialTask!));
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEditing ? 'Ubah Tugas' : 'Tambah Tugas',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Hapus Tugas',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            _field('Judul Tugas', _title, 'Contoh: Laporan praktikum Modul 13'),
            const SizedBox(height: 4),

            // Pilihan Mata Kuliah (Dropdown)
            const Text('Mata Kuliah (Bobot SKS)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            if (widget.mataKuliahList.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: const Text(
                  'Belum ada mata kuliah tersimpan. Harap tambahkan mata kuliah terlebih dahulu di menu Mata Kuliah.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              )
            else
              DropdownButtonFormField<MataKuliahModel>(
                initialValue: _selectedMataKuliah,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
                  ),
                ),
                items: widget.mataKuliahList.map((mk) {
                  return DropdownMenuItem<MataKuliahModel>(
                    value: mk,
                    child: Text(
                      '${mk.nama} (${mk.sks} SKS)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedMataKuliah = val),
                validator: (val) => val == null ? 'Pilih salah satu mata kuliah' : null,
              ),

            const SizedBox(height: 18),

            // Deadline Picker
            const Text('Deadline Waktu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.ink, width: 1.5),
                ),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              icon: const Icon(Icons.calendar_month, color: AppColors.primary),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.ink),
                  ),
                  Text(
                    '(${_deadline.difference(DateTime.now()).inDays <= 0 ? "Hari ini" : "Sisa ${_deadline.difference(DateTime.now()).inDays} hari"})',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Jangkar Kognitif Pemahaman Materi (Skala 1 - 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pemahaman Materi',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(
                  'Bobot pengali: ${Pemahaman.bobot(_pemahaman)}x',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pilihan: $_pemahaman - ${Pemahaman.label[_pemahaman] ?? ""}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13),
            ),
            const SizedBox(height: 10),

            // 5 Tombol Angka Neo-Brutalism
            Row(
              children: [1, 2, 3, 4, 5].map((lvl) {
                final isSelected = _pemahaman == lvl;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _pemahaman = lvl),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.yellow : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.ink,
                            width: isSelected ? 2.2 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? const [BoxShadow(color: AppColors.ink, offset: Offset(2, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$lvl',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isSelected ? AppColors.ink : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Teks Bantuan / Arti Lengkap Jangkar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.ink, width: 1.2),
              ),
              child: Text(
                'Arti: "${Pemahaman.arti[_pemahaman] ?? ""}"',
                style: const TextStyle(fontSize: 12, color: AppColors.ink, fontStyle: FontStyle.italic),
              ),
            ),

            const SizedBox(height: 20),

            _field('Deskripsi (opsional)', _description, 'Detail instruksi tugas...',
                required: false, maxLines: 3),

            // Pilihan Status jika Edit
            if (_isEditing) ...[
              const Text('Status Pengerjaan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<TaskStatus>(
                segments: const [
                  ButtonSegment(value: TaskStatus.todo, label: Text('Belum')),
                  ButtonSegment(value: TaskStatus.inProgress, label: Text('Proses')),
                  ButtonSegment(value: TaskStatus.completed, label: Text('Selesai')),
                ],
                selected: {_status},
                onSelectionChanged: (set) {
                  setState(() => _status = set.first);
                },
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 12),

            // Tombol Simpan
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.ink, width: 2),
                  ),
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  if (_selectedMataKuliah == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap pilih mata kuliah terlebih dahulu.')),
                    );
                    return;
                  }

                  final resultTask = TaskModel(
                    id: widget.initialTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _title.text.trim(),
                    mataKuliah: _selectedMataKuliah!,
                    deadline: _deadline,
                    pemahaman: _pemahaman,
                    description: _description.text.trim(),
                    status: _status,
                  );

                  Navigator.pop(context, TaskFormResult.saved(resultTask));
                },
                child: Text(
                  _isEditing ? 'Simpan Perubahan' : 'Tambahkan Tugas',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String hint,
      {bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
            validator: required
                ? (v) => v == null || v.trim().isEmpty ? 'Bagian ini wajib diisi' : null
                : null,
          ),
        ],
      ),
    );
  }
}
