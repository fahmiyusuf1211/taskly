import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/task_model.dart';
import '../widgets/neo_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.tasks});
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;
    final pending = tasks.length - done;
    final percent = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Statistics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('Pantau progres produktivitasmu.', style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 22),
      NeoCard(color: AppColors.primary, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('COMPLETION RATE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1)),
        Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900)),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(
          value: tasks.isEmpty ? 0 : done / tasks.length, minHeight: 12, color: AppColors.yellow, backgroundColor: Colors.white24)),
      ])),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: NeoCard(color: AppColors.mint, child: _metric('Completed', '$done'))),
        const SizedBox(width: 14),
        Expanded(child: NeoCard(color: AppColors.yellow, child: _metric('Pending', '$pending'))),
      ]),
      const SizedBox(height: 18),
      NeoCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total tasks', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('${tasks.length}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
      ])),
    ]);
  }

  Widget _metric(String title, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    const SizedBox(height: 8),
    Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
  ]);
}
