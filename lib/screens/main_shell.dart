import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/task_model.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'schedule_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final List<TaskModel> _tasks = [
    TaskModel(title: 'Membuat laporan praktikum', subject: 'Pemrograman Mobile',
        deadline: DateTime.now().add(const Duration(days: 1)), priority: TaskPriority.high),
    TaskModel(title: 'Mengerjakan desain UI', subject: 'Interaksi Manusia Komputer',
        deadline: DateTime.now().add(const Duration(days: 2)), priority: TaskPriority.medium),
    TaskModel(title: 'Membaca materi basis data', subject: 'Basis Data',
        deadline: DateTime.now().add(const Duration(days: 4)), priority: TaskPriority.low),
  ];

  void _addTask(TaskModel task) => setState(() => _tasks.insert(0, task));

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(tasks: _tasks, onNavigate: (i) => setState(() => _index = i),
          onTaskChanged: (task) => setState(() {
            task.status = task.status == TaskStatus.completed
                ? TaskStatus.todo : TaskStatus.completed;
          })),
      TasksScreen(tasks: _tasks, onAdd: _addTask,
          onTaskChanged: (task) => setState(() {
            task.status = task.status == TaskStatus.completed
                ? TaskStatus.todo : TaskStatus.completed;
          })),
      const ScheduleScreen(),
      StatisticsScreen(tasks: _tasks),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: _index,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDCEAFF),
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Schedule'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
