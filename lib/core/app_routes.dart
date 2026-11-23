import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/mata_kuliah_model.dart';
import '../models/task_model.dart';
import '../screens/add_task_screen.dart';
import '../screens/detail_task_screen.dart';
import '../screens/main_shell.dart';
import '../screens/mata_kuliah_screen.dart';

/// Seluruh aturan navigasi aplikasi ada di file ini.
///
/// Tujuan pemindahan: sebelumnya setiap layar membuat sendiri
/// `MaterialPageRoute`-nya, sehingga susunan halaman tersebar di 4 file dan
/// sulit dilihat sebagai satu kesatuan. Sekarang semua rute terdaftar di
/// [AppPages.routes], dan layar cukup memanggil `Get.toNamed(...)`.
///
/// Catatan penting: pemindahan ini TIDAK mengubah tampilan. Setiap `GetPage`
/// membangun widget yang sama persis seperti sebelumnya, dan `Navigator.pop`
/// untuk dialog tetap dipakai apa adanya (dialog bukan halaman).
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String mataKuliah = '/mata-kuliah';
  static const String tambahTugas = '/tugas/tambah';
  static const String detailTugas = '/tugas/detail';

  /// Rute yang menerima argumen berupa objek.
  ///
  /// `Get.toNamed` tidak bisa mengoper nilai lewat constructor seperti
  /// `Navigator.push`, jadi data dikirim sebagai `arguments` dan dibaca
  /// kembali di sini dengan tipe yang sudah pasti. Kalau tipe argumennya
  /// tidak sesuai, pesan errornya jelas — bukan null yang membingungkan.
  static List<GetPage<dynamic>> get routes => [
        GetPage<dynamic>(
          name: home,
          page: () => const MainShell(),
        ),
        GetPage<dynamic>(
          name: mataKuliah,
          page: () {
            final args = _args<MataKuliahArgs>(name: mataKuliah);
            return MataKuliahScreen(
              mataKuliahList: args.mataKuliahList,
              tasks: args.tasks,
              onAddMataKuliah: args.onAddMataKuliah,
              onUpdateMataKuliah: args.onUpdateMataKuliah,
              onDeleteMataKuliah: args.onDeleteMataKuliah,
            );
          },
        ),
        GetPage<dynamic>(
          name: tambahTugas,
          page: () {
            final args = _args<TambahTugasArgs>(name: tambahTugas);
            return AddTaskScreen(
              mataKuliahList: args.mataKuliahList,
              initialTask: args.initialTask,
            );
          },
        ),
        GetPage<dynamic>(
          name: detailTugas,
          page: () {
            final args = _args<DetailTugasArgs>(name: detailTugas);
            return DetailTaskScreen(
              task: args.task,
              mataKuliahList: args.mataKuliahList,
              onUpdateTask: args.onUpdateTask,
              onDeleteTask: args.onDeleteTask,
            );
          },
        ),
      ];

  static T _args<T>({required String name}) {
    final args = Get.arguments;
    if (args is! T) {
      throw ArgumentError(
        'Rute "$name" membutuhkan argumen bertipe $T, '
        'tetapi yang diterima: ${args.runtimeType}.',
      );
    }
    return args;
  }
}

/// Argumen untuk [AppRoutes.mataKuliah].
class MataKuliahArgs {
  const MataKuliahArgs({
    required this.mataKuliahList,
    required this.tasks,
    required this.onAddMataKuliah,
    required this.onUpdateMataKuliah,
    required this.onDeleteMataKuliah,
  });

  final List<MataKuliahModel> mataKuliahList;
  final List<TaskModel> tasks;
  final ValueChanged<MataKuliahModel> onAddMataKuliah;
  final ValueChanged<MataKuliahModel> onUpdateMataKuliah;
  final ValueChanged<String> onDeleteMataKuliah;
}

/// Argumen untuk [AppRoutes.tambahTugas].
///
/// `initialTask` null berarti mode tambah; terisi berarti mode edit.
class TambahTugasArgs {
  const TambahTugasArgs({
    required this.mataKuliahList,
    this.initialTask,
  });

  final List<MataKuliahModel> mataKuliahList;
  final TaskModel? initialTask;
}

/// Argumen untuk [AppRoutes.detailTugas].
class DetailTugasArgs {
  const DetailTugasArgs({
    required this.task,
    required this.mataKuliahList,
    required this.onUpdateTask,
    required this.onDeleteTask,
  });

  final TaskModel task;
  final List<MataKuliahModel> mataKuliahList;
  final ValueChanged<TaskModel> onUpdateTask;
  final ValueChanged<String> onDeleteTask;
}
