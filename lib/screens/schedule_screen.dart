import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/neo_card.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('08:00 - 09:40', 'Pemrograman Mobile', 'Lab Komputer 2', AppColors.surfaceBlue),
      ('10:00 - 11:40', 'Basis Data', 'Ruang B-204', AppColors.yellow),
      ('13:00 - 14:40', 'Rekayasa Perangkat Lunak', 'Ruang C-102', AppColors.mint),
    ];
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('My Schedule', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      const Text('Preview jadwal perkuliahan mingguan', style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 22),
      NeoCard(color: AppColors.primary, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TODAY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1)),
        SizedBox(height: 6),
        Text('Your class agenda', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
      ])),
      const SizedBox(height: 20),
      ...items.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: NeoCard(color: e.$4, child: Row(children: [
          const Icon(Icons.access_time, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 5),
            Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(e.$3, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
        ])),
      )),
      const Text('Catatan: jadwal di atas masih berupa data contoh.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
    ]);
  }
}
