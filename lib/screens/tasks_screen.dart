import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/mata_kuliah_model.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';
import 'detail_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.tasks,
    required this.mataKuliahList,
    required this.onAdd,
    required this.onUpdate,
    required this.onDelete,
    required this.onTaskChanged,
  });

  final List<TaskModel> tasks;
  final List<MataKuliahModel> mataKuliahList;
  final ValueChanged<TaskModel> onAdd;
  final ValueChanged<TaskModel> onUpdate;
  final ValueChanged<String> onDelete;
  final ValueChanged<TaskModel> onTaskChanged;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Belum', 'Proses', 'Selesai'

  Future<void> _openAdd(BuildContext context) async {
    final result = await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(
          mataKuliahList: widget.mataKuliahList,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (!result.isDeleted) {
      widget.onAdd(result.task);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tugas "${result.task.title}" berhasil ditambahkan.'),
          backgroundColor: AppColors.ink,
        ),
      );
    }
  }

  void _openDetail(BuildContext context, TaskModel task) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailTaskScreen(
          task: task,
          mataKuliahList: widget.mataKuliahList,
          onUpdateTask: widget.onUpdate,
          onDeleteTask: widget.onDelete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter status
    final filteredByStatus = widget.tasks.where((t) {
      if (_selectedFilter == 'Belum') return t.status == TaskStatus.todo;
      if (_selectedFilter == 'Proses') return t.status == TaskStatus.inProgress;
      if (_selectedFilter == 'Selesai') return t.status == TaskStatus.completed;
      return true;
    }).toList();

    // 2. Filter pencarian
    final filtered = filteredByStatus.where((t) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.mataKuliah.nama.toLowerCase().contains(q);
    }).toList();

    // 3. Urutkan berdasarkan skor prioritas tertinggi (menurun)
    filtered.sort((a, b) => b.skorPrioritas.compareTo(a.skorPrioritas));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daftar Tugas',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('${widget.tasks.length} tugas total • Diurutkan dari skor tertinggi',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Kolom Pencarian (Wireframe P1)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink, width: 1.8),
              boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(2, 2))],
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari judul, deskripsi, atau matkul...',
                hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.ink),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 14),

          // Filter Chips Status (Wireframe P1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Belum', 'Proses', 'Selesai'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.ink,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.ink, width: 1.5),
                    ),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // List Tugas
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Tidak ada tugas yang cocok dengan "$_searchQuery".'
                      : 'Belum ada tugas untuk filter "$_selectedFilter".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ...filtered.map(
              (task) => TaskTile(
                task: task,
                onChanged: () => widget.onTaskChanged(task),
                onTap: () => _openDetail(context, task), // Buka Wireframe P3 (DetailTaskScreen)
              ),
            ),
        ],
      ),
    );
  }
}
