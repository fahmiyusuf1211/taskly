import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly/main.dart';
import 'package:taskly/models/mata_kuliah_model.dart';
import 'package:taskly/models/pemahaman.dart';
import 'package:taskly/models/task_model.dart';
import 'package:taskly/screens/detail_task_screen.dart';

void main() {
  group('Formula Prioritas & Model Tests', () {
    test('Bobot pemahaman berkebalikan dengan nilai 1-5', () {
      expect(Pemahaman.bobot(1), 5); // Belum paham -> bobot 5 (sangat mendesak)
      expect(Pemahaman.bobot(2), 4);
      expect(Pemahaman.bobot(3), 3);
      expect(Pemahaman.bobot(4), 2);
      expect(Pemahaman.bobot(5), 1); // Sudah lancar -> bobot 1
    });

    test('Perhitungan skor prioritas tugas: (sks * bobot_pemahaman) / sisa_hari', () {
      final matkul = MataKuliahModel(id: 'mk-test', nama: 'Pemrograman Mobile', sks: 3);
      final taskKritis = TaskModel(
        id: 't-1',
        title: 'Tugas Kritis',
        mataKuliah: matkul,
        deadline: DateTime.now().add(const Duration(days: 1)),
        pemahaman: 1, // Bobot = 5
      );

      // SKS = 3, Pemahaman = 1 (Bobot 5), sisa hari = 1 -> skor = (3 * 5) / 1 = 15.0
      expect(taskKritis.skorPrioritas, 15.0);
      expect(taskKritis.urgensi, UrgencyLevel.kritis);
    });
  });

  group('Widget Tests', () {
    testWidgets('Smoke test render TasklyApp dan navigasi utama', (WidgetTester tester) async {
      await tester.pumpWidget(const TasklyApp());
      await tester.pumpAndSettle();

      // Cek tulisan Taskly pada Dashboard
      expect(find.text('Taskly'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Matkul'), findsOneWidget);
    });

    testWidgets('DetailTaskScreen render countdown dan breakdown skor', (WidgetTester tester) async {
      final mk = MataKuliahModel(id: 'mk-1', nama: 'Basis Data', sks: 3);
      final task = TaskModel(
        id: 't-test',
        title: 'Latihan SQL Join',
        mataKuliah: mk,
        deadline: DateTime.now().add(const Duration(days: 2)),
        pemahaman: 2,
        description: 'Mengerjakan query join multi-tabel.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetailTaskScreen(
            task: task,
            mataKuliahList: [mk],
            onUpdateTask: (_) {},
            onDeleteTask: (_) {},
          ),
        ),
      );

      expect(find.text('Detail Tugas'), findsOneWidget);
      expect(find.text('Latihan SQL Join'), findsOneWidget);
      expect(find.text('BREAKDOWN FORMULA PRIORITAS'), findsOneWidget);
      expect(find.text('Mengerjakan query join multi-tabel.'), findsOneWidget);
    });
  });
}
