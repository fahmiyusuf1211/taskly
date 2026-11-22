import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_colors.dart';
import '../core/app_routes.dart';
import '../models/mata_kuliah_model.dart';
import '../models/task_model.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'statistics_screen.dart';
import 'tasks_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Data Awal Mata Kuliah
  final List<MataKuliahModel> _mataKuliahList = [
    MataKuliahModel(id: 'mk-1', nama: 'Pemrograman Mobile', sks: 3),
    MataKuliahModel(id: 'mk-2', nama: 'Basis Data', sks: 3),
    MataKuliahModel(id: 'mk-3', nama: 'Rekayasa Perangkat Lunak', sks: 2),
    MataKuliahModel(id: 'mk-4', nama: 'Kecerdasan Buatan', sks: 4),
  ];

  // Data Awal Tugas
  late final List<TaskModel> _tasks = [
    TaskModel(
      id: 't-1',
      title: 'Membuat laporan praktikum Modul 13',
      mataKuliah: _mataKuliahList[0],
      deadline: DateTime.now().add(const Duration(days: 1)),
      pemahaman: 2, // Masih bingung -> pembilang tinggi, sisa 1 hari -> KRITIS
      description: 'Laporan 5 bab dan pengujian aplikasi flutter.',
    ),
    TaskModel(
      id: 't-2',
      title: 'Perancangan ERD dan Skema Tabel',
      mataKuliah: _mataKuliahList[1],
      deadline: DateTime.now().add(const Duration(days: 3)),
      pemahaman: 3,
      description: 'Normalisasi 3NF dan pembuatan foreign key.',
    ),
    TaskModel(
      id: 't-3',
      title: 'Membaca modul Neural Network',
      mataKuliah: _mataKuliahList[3],
      deadline: DateTime.now().add(const Duration(days: 7)),
      pemahaman: 4,
      description: 'Review arsitektur Multi-Layer Perceptron.',
    ),
  ];

  // Handler Mata Kuliah
  void _addMataKuliah(MataKuliahModel mk) {
    setState(() => _mataKuliahList.add(mk));
  }

  void _updateMataKuliah(MataKuliahModel updated) {
    setState(() {
      final index = _mataKuliahList.indexWhere((mk) => mk.id == updated.id);
      if (index != -1) {
        _mataKuliahList[index] = updated;
        for (var i = 0; i < _tasks.length; i++) {
          if (_tasks[i].mataKuliah.id == updated.id) {
            _tasks[i] = _tasks[i].copyWith(mataKuliah: updated);
          }
        }
      }
    });
  }

  void _deleteMataKuliah(String id) {
    setState(() {
      _mataKuliahList.removeWhere((mk) => mk.id == id);
      _tasks.removeWhere((t) => t.mataKuliah.id == id);
    });
  }

  // Handler Tugas
  void _addTask(TaskModel task) {
    setState(() => _tasks.insert(0, task));
  }

  void _updateTask(TaskModel updated) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _tasks[index] = updated;
      }
    });
  }

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((t) => t.id == id));
  }

  void _toggleTaskStatus(TaskModel task) {
    setState(() {
      task.status = task.status == TaskStatus.completed
          ? TaskStatus.todo
          : TaskStatus.completed;
    });
  }

  void _openMataKuliah() {
    Get.toNamed<void>(
      AppRoutes.mataKuliah,
      arguments: MataKuliahArgs(
        mataKuliahList: _mataKuliahList,
        tasks: _tasks,
        onAddMataKuliah: _addMataKuliah,
        onUpdateMataKuliah: _updateMataKuliah,
        onDeleteMataKuliah: _deleteMataKuliah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        tasks: _tasks,
        onNavigate: (i) => setState(() => _index = i),
        onTaskChanged: _toggleTaskStatus,
      ),
      TasksScreen(
        tasks: _tasks,
        mataKuliahList: _mataKuliahList,
        onAdd: _addTask,
        onUpdate: _updateTask,
        onDelete: _deleteTask,
        onTaskChanged: _toggleTaskStatus,
      ),
      ScheduleScreen(
        onManageMataKuliah: _openMataKuliah,
      ),
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
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
