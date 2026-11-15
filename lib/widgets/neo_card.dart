import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
        ],
      ),
      child: child,
    );
  }
}
