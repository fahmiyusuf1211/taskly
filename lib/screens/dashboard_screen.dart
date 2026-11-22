import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/task_model.dart';
import '../widgets/neo_card.dart';
import '../widgets/task_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.tasks,
    required this.onNavigate,
    required this.onTaskChanged,
  });

  final List<TaskModel> tasks;
  final ValueChanged<int> onNavigate;
  final ValueChanged<TaskModel> onTaskChanged;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    const firstName = 'Nailul';

    // Prioritaskan tugas yang belum selesai dan urutkan berdasarkan skor tertinggi
    final sortedUpcoming = List<TaskModel>.from(tasks)
      ..sort((a, b) {
        if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) return 1;
        if (a.status != TaskStatus.completed && b.status == TaskStatus.completed) return -1;
        return b.skorPrioritas.compareTo(a.skorPrioritas);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),
            const Text(
              'Taskly',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
            const Spacer(),
            CircleAvatar(
              backgroundColor: AppColors.yellow,
              child: const Text(
                'N',
                style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          'HELLO, $firstName! 👋',
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Prioritaskan tugas pentingmu.',
          style: TextStyle(fontSize: 26, height: 1.1, fontWeight: FontWeight.w900, color: AppColors.ink),
        ),
        const SizedBox(height: 20),
        NeoCard(
          color: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROGRES PENYELESAIAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completed/${tasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 7, left: 8),
                    child: Text('tugas selesai', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 11,
                  backgroundColor: Colors.white24,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tugas Mendesak', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            TextButton(
              onPressed: () => onNavigate(1), // Navigasi ke tab Tasks
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        if (tasks.isEmpty)
          const NeoCard(child: Text('Belum ada tugas. Tambahkan tugas pertamamu di tab Tasks!'))
        else
          ...sortedUpcoming.take(3).map(
                (task) => TaskTile(
                  task: task,
                  onChanged: () => onTaskChanged(task),
                  onTap: () => onNavigate(1),
                ),
              ),
        const SizedBox(height: 10),
        NeoCard(
          color: AppColors.yellow,
          child: Row(
            children: const [
              Icon(Icons.lightbulb_outline, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Prioritas dihitung otomatis dari SKS, tingkat pemahaman, dan sisa hari.',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
