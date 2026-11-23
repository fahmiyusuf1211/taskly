import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/pemahaman.dart';
import '../models/task_model.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onChanged,
    this.onTap,
  });

  final TaskModel task;
  final VoidCallback? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = task.status == TaskStatus.completed;

    Color badgeBg;
    String badgeText;
    switch (task.urgensi) {
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

    final pemahamanName = Pemahaman.label[task.pemahaman] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 1.8),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checklist Toggle
                InkWell(
                  onTap: onChanged,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: done ? AppColors.mint : Colors.white,
                      border: Border.all(color: AppColors.ink, width: 1.8),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 20, color: AppColors.ink)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Info Tugas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${task.mataKuliah.nama} (${task.mataKuliah.sks} SKS)',
                            style: const TextStyle(
                                color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const Text('•',
                              style: TextStyle(color: AppColors.muted, fontSize: 11)),
                          Text(
                            'Sisa ${task.sisaHari} hr',
                            style: TextStyle(
                              color: task.sisaHari <= 1 ? Colors.redAccent : AppColors.muted,
                              fontSize: 11,
                              fontWeight: task.sisaHari <= 1 ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                          const Text('•',
                              style: TextStyle(color: AppColors.muted, fontSize: 11)),
                          Text(
                            pemahamanName,
                            style: const TextStyle(color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Urgency Badge (KRITIS / DEKAT / SANTAI)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    border: Border.all(color: AppColors.ink, width: 1.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
