import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/task_model.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.onChanged});
  final TaskModel task;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.completed;
    final priorityColor = task.priority == TaskPriority.high
        ? const Color(0xFFFECdd3)
        : task.priority == TaskPriority.medium
            ? AppColors.yellow
            : AppColors.mint;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 1.8),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onChanged,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: done ? AppColors.mint : Colors.white,
                border: Border.all(color: AppColors.ink, width: 1.8),
                borderRadius: BorderRadius.circular(7),
              ),
              child: done
                  ? const Icon(Icons.check, size: 19, color: AppColors.ink)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.muted : AppColors.ink,
                    )),
                const SizedBox(height: 5),
                Text('${task.subject} • ${task.deadline.day}/${task.deadline.month}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: priorityColor,
              border: Border.all(color: AppColors.ink, width: 1.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(task.priority.name.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
