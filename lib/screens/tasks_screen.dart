import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.tasks, required this.onAdd, required this.onTaskChanged});
  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onAdd;
  final ValueChanged<TaskModel> onTaskChanged;

  Future<void> _openAdd(BuildContext context) async {
    final task = await Navigator.push<TaskModel>(
      context, MaterialPageRoute(builder: (_) => const AddTaskScreen()));
    if (task != null) onAdd(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah tugas', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
        children: [
          const Text('My Tasks', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('${tasks.length} tugas tersimpan', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 22),
          if (tasks.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Belum ada tugas. Tekan tombol Tambah tugas.')))
          else
            ...tasks.map((task) => TaskTile(task: task, onChanged: () => onTaskChanged(task))),
        ],
      ),
    );
  }
}
