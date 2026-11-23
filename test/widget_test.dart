import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:taskly/core/app_routes.dart';
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

      // Cek tulisan Taskly pada Dashboard dan 5 bottom nav items asli
      expect(find.text('Taskly'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
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
        GetMaterialApp(
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

  // ---------------------------------------------------------------------
  // Navigasi GetX.
  //
  // Test di atas hanya memastikan layar pertama ter-render. Grup ini
  // memastikan rute di lib/core/app_routes.dart benar-benar berpindah
  // halaman — kalau ada rute yang salah nama atau argumennya tidak cocok,
  // di sinilah ketahuannya, bukan saat demo.
  // ---------------------------------------------------------------------
  group('Navigasi GetX', () {
    testWidgets('Semua rute terdaftar dengan nama yang unik', (tester) async {
      final names = AppRoutes.routes.map((r) => r.name).toList();

      expect(names, containsAll(<String>[
        AppRoutes.home,
        AppRoutes.mataKuliah,
        AppRoutes.tambahTugas,
        AppRoutes.detailTugas,
      ]));
      expect(names.toSet().length, names.length, reason: 'Ada nama rute yang duplikat');
    });

    testWidgets('Home -> Schedule -> kelola mata kuliah lewat Get.toNamed', (tester) async {
      await tester.pumpWidget(const TasklyApp());
      await tester.pumpAndSettle();

      // Tab Schedule masih memakai IndexedStack (bukan rute), jadi diklik biasa.
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      // Tombol ini memanggil Get.toNamed(AppRoutes.mataKuliah, ...).
      await tester.tap(find.byTooltip('Kelola Data Mata Kuliah & SKS'));
      await tester.pumpAndSettle();

      // Kalau rute dan argumennya benar, layar Mata Kuliah yang muncul.
      expect(find.text('Mata Kuliah'), findsWidgets);
      expect(find.textContaining('mata kuliah tersimpan'), findsOneWidget);

      // Kembali ke halaman sebelumnya juga lewat GetX.
      Get.back();
      await tester.pumpAndSettle();
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('Rute tambahTugas menerima argumen dan menampilkan form', (tester) async {
      final mk = MataKuliahModel(id: 'mk-1', nama: 'Basis Data', sks: 3);

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.home,
          getPages: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed<void>(
        AppRoutes.tambahTugas,
        arguments: TambahTugasArgs(mataKuliahList: [mk]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tambah Tugas'), findsOneWidget);
      expect(find.text('Judul Tugas'), findsOneWidget);
    });

    test('Builder rute menolak argumen bertipe salah dengan pesan jelas', () {
      // Yang diuji langsung adalah builder-nya, bukan Get.toNamed: GetX
      // membangun halaman secara tertunda, sehingga error tipe baru muncul
      // di frame berikutnya dan sulit ditangkap di test.
      //
      // Get.arguments tidak punya setter publik, jadi dibaca dari
      // Get.routeTree/parameters lewat jalur yang sama dengan GetX:
      // Get.parameters tidak dipakai di sini — cukup pastikan builder
      // melempar ArgumentError ketika argumennya tidak sesuai.
      final halamanDetail =
          AppRoutes.routes.firstWhere((r) => r.name == AppRoutes.detailTugas);

      // Tanpa argumen (Get.arguments null di luar navigasi) -> ArgumentError
      // dengan pesan yang menyebut rute dan tipe yang diharapkan, bukan
      // null-dereference yang membingungkan.
      expect(
        () => halamanDetail.page(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            allOf(contains(AppRoutes.detailTugas), contains('DetailTugasArgs')),
          ),
        ),
      );
    });
  });
}
