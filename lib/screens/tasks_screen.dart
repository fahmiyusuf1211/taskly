import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/mata_kuliah_model.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({
    super.key,
    required this.tasks,
    required this.mataKuliahList,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onTaskChanged,
  });

  final List<TaskModel> tasks;
  final List<MataKuliahModel> mataKuliahList;
  final ValueChanged<TaskModel> onAdd;
  final ValueChanged<TaskModel> onUpdate;
  final ValueChanged<String> onDelete;
  final ValueChanged<TaskModel> onTaskChanged;

  Future<void> _openForm(BuildContext context, [TaskModel? taskToEdit]) async {
    final result = await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          mataKuliahList: mataKuliahList,
          initialTask: taskToEdit,
        ),
      ),
    );

    if (!context.mounted) return;

    if (result != null) {
      if (result.isDeleted) {
        onDelete(result.task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tugas "${result.task.title}" telah dihapus.'),
            backgroundColor: AppColors.ink,
          ),
        );
      } else {
        if (taskToEdit == null) {
          onAdd(result.task);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tugas "${result.task.title}" berhasil ditambahkan.'),
              backgroundColor: AppColors.ink,
            ),
          );
        } else {
          onUpdate(result.task);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perubahan tugas "${result.task.title}" disimpan.'),
              backgroundColor: AppColors.ink,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Urutkan berdasarkan skor prioritas tertinggi (menurun)
    final sortedTasks = List<TaskModel>.from(tasks)
      ..sort((a, b) => b.skorPrioritas.compareTo(a.skorPrioritas));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah tugas', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('Daftar Tugas',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('${tasks.length} tugas • Diurutkan berdasarkan skor prioritas',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (sortedTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'Belum ada tugas tersimpan.\nTekan tombol "Tambah tugas" di bawah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ...sortedTasks.map(
              (task) => TaskTile(
                task: task,
                onChanged: () => onTaskChanged(task),
                onTap: () => _openForm(context, task),
              ),
            ),
        ],
      ),
    );
  }
}
