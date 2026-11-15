import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/task_model.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  TaskPriority _priority = TaskPriority.medium;

  @override
  void dispose() {
    _title.dispose(); _subject.dispose(); _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Tugas', style: TextStyle(fontWeight: FontWeight.w900))),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          _field('Nama tugas', _title, 'Contoh: Laporan praktikum'),
          _field('Mata kuliah', _subject, 'Contoh: Pemrograman Mobile'),
          _field('Deskripsi (opsional)', _description, 'Detail tugas...', required: false, maxLines: 3),
          const SizedBox(height: 16),
          const Text('Deadline', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(context: context, initialDate: _deadline,
                firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setState(() => _deadline = picked);
            },
            icon: const Icon(Icons.calendar_today),
            label: Text('${_deadline.day}/${_deadline.month}/${_deadline.year}'),
          ),
          const SizedBox(height: 16),
          const Text('Prioritas', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          DropdownButtonFormField<TaskPriority>(
            value: _priority,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _priority = v ?? TaskPriority.medium),
          ),
          const SizedBox(height: 28),
          SizedBox(height: 52, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.ink, width: 2))),
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, TaskModel(title: _title.text.trim(), subject: _subject.text.trim(),
                description: _description.text.trim(), deadline: _deadline, priority: _priority));
            },
            child: const Text('Simpan Tugas', style: TextStyle(fontWeight: FontWeight.w900)),
          )),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, String hint,
      {bool required = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, maxLines: maxLines,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          validator: required ? (v) => v == null || v.trim().isEmpty ? 'Bagian ini wajib diisi' : null : null),
      ]),
    );
  }
}
