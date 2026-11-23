// Mengisi database Taskly dengan data awal (seed) lewat REST API.
//
//   dart run tool/seed.dart            # isi kalau database masih kosong
//   dart run tool/seed.dart --force    # hapus semua data dulu, lalu isi ulang
//
// Kenapa lewat API, bukan INSERT langsung ke Postgres:
// dengan begitu rantai lengkapnya ikut teruji — model Dart -> toRequestJson ->
// HTTP -> Express -> validasi -> Postgres -> fromJson. Kalau ada yang salah di
// rantai itu, seed ini gagal dan ketahuan sebelum aplikasi dipakai.
//
// Deadline sengaja relatif terhadap hari ini (bukan tanggal mati), supaya
// badge urgensi (KRITIS/DEKAT/SANTAI) tetap masuk akal kapan pun dijalankan.

import 'dart:io';

import 'package:taskly/models/mata_kuliah_model.dart';
import 'package:taskly/models/task_model.dart';
import 'package:taskly/services/api_exception.dart';
import 'package:taskly/services/api_service.dart';

/// Satu baris rencana seed: mata kuliah + tugas-tugasnya.
class _RencanaMatkul {
  const _RencanaMatkul({required this.nama, required this.sks, required this.tugas});
  final String nama;
  final int sks;
  final List<_RencanaTugas> tugas;
}

class _RencanaTugas {
  const _RencanaTugas({
    required this.title,
    required this.description,
    required this.pemahaman,
    required this.hari,
    required this.urgensiDiharapkan,
  });

  final String title;
  final String description;
  final int pemahaman;

  /// Deadline = hari ini + sekian hari.
  final int hari;

  /// Dipakai untuk memverifikasi bahwa rumus prioritas menghasilkan
  /// label yang diharapkan. Kalau tidak cocok, seed dianggap gagal.
  final UrgencyLevel urgensiDiharapkan;
}

const _rencana = <_RencanaMatkul>[
  _RencanaMatkul(
    nama: 'Pemrograman Mobile',
    sks: 3,
    tugas: [
      _RencanaTugas(
        title: 'Membuat laporan praktikum Modul 13',
        description: 'Laporan 5 bab dan pengujian aplikasi Flutter.',
        pemahaman: 2, // masih bingung -> bobot 4
        hari: 1,
        urgensiDiharapkan: UrgencyLevel.kritis,
      ),
    ],
  ),
  _RencanaMatkul(
    nama: 'Basis Data',
    sks: 3,
    tugas: [
      _RencanaTugas(
        title: 'Perancangan ERD dan Skema Tabel',
        description: 'Normalisasi 3NF dan pembuatan foreign key.',
        pemahaman: 3, // paham konsep -> bobot 3
        hari: 3,
        urgensiDiharapkan: UrgencyLevel.dekat,
      ),
    ],
  ),
  _RencanaMatkul(
    nama: 'Rekayasa Perangkat Lunak',
    sks: 2,
    tugas: const [],
  ),
  _RencanaMatkul(
    nama: 'Kecerdasan Buatan',
    sks: 4,
    tugas: [
      _RencanaTugas(
        title: 'Membaca modul Neural Network',
        description: 'Review arsitektur Multi-Layer Perceptron.',
        pemahaman: 4, // bisa, perlu contekan -> bobot 2
        hari: 7,
        urgensiDiharapkan: UrgencyLevel.santai,
      ),
    ],
  ),
];

var _gagal = 0;

void cek(String label, bool kondisi, [String? detail]) {
  if (kondisi) {
    print('  ok    $label');
  } else {
    _gagal++;
    print('  GAGAL $label${detail == null ? '' : ' -> $detail'}');
  }
}

Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final api = ApiService();

  print('Target : ${ApiService().runtimeType}');
  print('Mode   : ${force ? 'RESET (--force)' : 'isi kalau kosong'}');
  print('');

  try {
    final sehat = await api.checkHealth();
    if (!sehat) {
      print('Server tidak sehat. Seed dibatalkan.');
      exit(1);
    }

    final matkulAda = await api.getMataKuliah();
    final tugasAda = await api.getTugas();

    // --- Putuskan apakah perlu mengisi ------------------------------------
    if (matkulAda.isNotEmpty || tugasAda.isNotEmpty) {
      if (!force) {
        print('Database sudah berisi: ${matkulAda.length} mata kuliah, '
            '${tugasAda.length} tugas.');
        print('Tidak ada yang diubah. Jalankan dengan --force untuk reset.');
        api.close();
        exit(0);
      }

      print('[reset] menghapus data lama');
      for (final t in tugasAda) {
        await api.deleteTugas(t.id);
      }
      for (final m in matkulAda) {
        await api.deleteMataKuliah(m.id);
      }
      final cekKosong = await api.getMataKuliah();
      cek('database kosong setelah reset', cekKosong.isEmpty);
    }

    // --- Isi data ---------------------------------------------------------
    print('[isi] membuat mata kuliah dan tugas');
    final dibuat = <String, MataKuliahModel>{};

    for (final rencana in _rencana) {
      final matkul = await api.createMataKuliah(nama: rencana.nama, sks: rencana.sks);
      dibuat[rencana.nama] = matkul;
      print('  + ${matkul.nama} (${matkul.sks} SKS)');

      for (final t in rencana.tugas) {
        // Deadline dihitung dari awal hari ini, supaya sisaHari di aplikasi
        // menghasilkan angka yang sama dengan yang diharapkan di sini.
        final now = DateTime.now();
        final deadline = DateTime(now.year, now.month, now.day, 23, 59)
            .add(Duration(days: t.hari));

        final tugas = await api.createTugas(
          TaskModel(
            id: '',
            title: t.title,
            mataKuliah: matkul,
            deadline: deadline,
            description: t.description,
            pemahaman: t.pemahaman,
          ),
        );
        print('      + ${tugas.title}');
      }
    }

    // --- Verifikasi hasil -------------------------------------------------
    print('');
    print('[verifikasi] membaca ulang dari server');

    final matkulBaru = await api.getMataKuliah();
    final tugasBaru = await api.getTugas();
    final stats = await api.getStats();

    cek('jumlah mata kuliah = ${_rencana.length}',
        matkulBaru.length == _rencana.length, 'dapat ${matkulBaru.length}');
    cek('jumlah tugas = 3', tugasBaru.length == 3, 'dapat ${tugasBaru.length}');

    // Cocokkan tiap tugas dengan rencana: judul, matkul, skor, dan urgensi.
    for (final rencana in _rencana) {
      for (final r in rencana.tugas) {
        final found = tugasBaru.where((t) => t.title == r.title).toList();
        if (found.isEmpty) {
          cek('tugas "${r.title}" ada', false);
          continue;
        }
        final tugas = found.first;
        cek('"${r.title}" -> matkul ${rencana.nama}',
            tugas.mataKuliah.nama == rencana.nama, tugas.mataKuliah.nama);
        cek('"${r.title}" -> sisa ${tugas.sisaHari} hari',
            tugas.sisaHari == r.hari, 'harap ${r.hari}');
        cek('"${r.title}" -> urgensi ${r.urgensiDiharapkan.name}',
            tugas.urgensi == r.urgensiDiharapkan,
            'dapat ${tugas.urgensi.name}, skor ${tugas.skorPrioritas.toStringAsFixed(2)}');
      }
    }

    cek('stats.total = 3', stats.total == 3, 'dapat ${stats.total}');
    cek('stats.completed = 0', stats.completed == 0, 'dapat ${stats.completed}');
    // dueThisWeek memakai batas "< now() + 7 hari". Tugas ketiga deadline-nya
    // tepat 7 hari dari sekarang (jam 23:59), jadi berada sedikit DI LUAR
    // batas itu dan tidak ikut dihitung. Karena itu 2, bukan 3.
    cek('stats.dueThisWeek = 2 (tugas ke-3 tepat di batas 7 hari)',
        stats.dueThisWeek == 2, 'dapat ${stats.dueThisWeek}');

    api.close();

    print('');
    if (_gagal == 0) {
      print('Seed selesai: ${matkulBaru.length} mata kuliah, ${tugasBaru.length} tugas.');
      exit(0);
    } else {
      print('Seed selesai tetapi $_gagal verifikasi gagal.');
      exit(1);
    }
  } on ApiException catch (e) {
    print('');
    print('GAGAL: ${e.message}${e.statusCode == null ? '' : ' (HTTP ${e.statusCode})'}');
    api.close();
    exit(1);
  }
}
