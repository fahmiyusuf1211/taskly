import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/neo_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('My Profile', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 22),
      NeoCard(color: AppColors.surfaceBlue, child: const Column(children: [
        CircleAvatar(radius: 38, backgroundColor: AppColors.yellow,
          child: Text('F', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink))),
        SizedBox(height: 12),
        Text('Fahmi Yusuf', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 4),
        Text('Mahasiswa • Teknik Informatika', style: TextStyle(color: AppColors.muted)),
      ])),
      const SizedBox(height: 20),
      _setting(Icons.person_outline, 'Edit Profile'),
      _setting(Icons.notifications_outlined, 'Notification Settings'),
      _setting(Icons.palette_outlined, 'Appearance'),
      _setting(Icons.info_outline, 'About Taskly'),
    ]);
  }

  Widget _setting(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: NeoCard(child: Row(children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
      const Icon(Icons.chevron_right),
    ])),
  );
}
