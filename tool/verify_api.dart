// Verifikasi ApiService terhadap server sungguhan.
//
// Jalankan dari root proyek:
//   dart run tool/verify_api.dart
//
// Script ini sengaja TIDAK memakai Flutter (hanya Dart murni), supaya bisa
// dijalankan cepat lewat CLI tanpa emulator. Semua method ApiService dipanggil
// berurutan seperti yang nanti dipakai aplikasi, lalu hasilnya dicetak.
// Di akhir, semua data uji dihapus kembali.

import 'dart:io';

import 'package:taskly/models/task_model.dart';
import 'package:taskly/services/api_exception.dart';
import 'package:taskly/services/api_service.dart';

var _lulus = 0;
var _gagal = 0;

void cek(String label, bool kondisi, [String? detail]) {
  if (kondisi) {
    _lulus++;
    print('  ok   $label');
  } else {
    _gagal++;
    print('  GAGAL $label${detail == null ? '' : ' -> $detail'}');
  }
}

Future<void> main() async {
  final api = ApiService();

  print('Server: ${api.runtimeType}');
  print('');

  // --- 0. Health -----------------------------------------------------------
  print('[0] health');
  final sehat = await api.checkHealth();
  cek('API + database hidup', sehat);
  if (!sehat) {
    print('\nServer tidak sehat, sisa tes dibatalkan.');
    exit(1);
  }

  // --- 1. Mata kuliah: create ---------------------------------------------
  print('[1] createMataKuliah');
  final mk = await api.createMataKuliah(nama: 'Verifikasi Dart', sks: 3);
  cek('id terisi server', mk.id.isNotEmpty, mk.id);
  cek('nama sesuai', mk.nama == 'Verifikasi Dart');
  cek('sks sesuai', mk.sks == 3);

  // --- 2. Mata kuliah: read -------------------------------------------------
  print('[2] getMataKuliah');
  final daftarMk = await api.getMataKuliah();
  cek('matkul baru ada di daftar', daftarMk.any((m) => m.id == mk.id));
  cek('jumlahTugas terisi (0)', daftarMk.firstWhere((m) => m.id == mk.id).jumlahTugas == 0);

  // --- 3. Mata kuliah: update ----------------------------------------------
  print('[3] updateMataKuliah');
  final mkEdit = await api.updateMataKuliah(mk.copyWith(nama: 'Verifikasi Dart 2', sks: 4));
  cek('nama berubah', mkEdit.nama == 'Verifikasi Dart 2');
  cek('sks berubah', mkEdit.sks == 4);

  // --- 4. Tugas: create ----------------------------------------------------
  print('[4] createTugas');
  final tugas = await api.createTugas(
    TaskModel(
      id: '',
      title: 'Tugas verifikasi',
      mataKuliah: mkEdit,
      deadline: DateTime.now().add(const Duration(days: 2)),
      description: 'Dibuat oleh tool/verify_api.dart',
      pemahaman: 2,
    ),
  );
  cek('id terisi server', tugas.id.isNotEmpty);
  cek('mataKuliah bersarang lengkap', tugas.mataKuliah.nama == 'Verifikasi Dart 2');
  cek('sks ikut terbaca', tugas.mataKuliah.sks == 4);
  cek('pemahaman tersimpan', tugas.pemahaman == 2);
  cek('status default todo', tugas.status == TaskStatus.todo);
  cek('skorPrioritas bisa dihitung', tugas.skorPrioritas > 0,
      'skor=${tugas.skorPrioritas}');
  cek('urgensi bisa ditentukan', tugas.urgensi.name.isNotEmpty);

  // --- 5. Tugas: read + filter --------------------------------------------
  print('[5] getTugas');
  final semua = await api.getTugas();
  cek('tugas ada di daftar', semua.any((t) => t.id == tugas.id));

  final perMatkul = await api.getTugas(mataKuliahId: mk.id);
  cek('filter mataKuliahId bekerja', perMatkul.length == 1 && perMatkul.first.id == tugas.id);

  final dicari = await api.getTugas(search: 'verifikasi');
  cek('filter search bekerja', dicari.any((t) => t.id == tugas.id));

  final satu = await api.getTugasById(tugas.id);
  cek('getTugasById bekerja', satu.id == tugas.id);

  // --- 6. Tugas: patch (checklist) -----------------------------------------
  print('[6] patchTugas');
  final selesai = await api.patchTugas(tugas.id, status: 'completed');
  cek('status jadi completed', selesai.status == TaskStatus.completed);

  final paham = await api.patchTugas(tugas.id, pemahaman: 5);
  cek('pemahaman jadi 5', paham.pemahaman == 5);
  cek('field lain tidak ikut berubah', paham.title == tugas.title);

  // --- 7. Tugas: update penuh ---------------------------------------------
  print('[7] updateTugas');
  final ubah = await api.updateTugas(
    paham.copyWith(title: 'Tugas verifikasi (revisi)', status: TaskStatus.inProgress),
  );
  cek('judul berubah', ubah.title == 'Tugas verifikasi (revisi)');
  cek('status inProgress', ubah.status == TaskStatus.inProgress);

  // --- 8. Stats ------------------------------------------------------------
  print('[8] getStats');
  final stats = await api.getStats();
  cek('total minimal 1', stats.total >= 1, 'total=${stats.total}');
  cek('inProgress minimal 1', stats.inProgress >= 1);

  // --- 9. Penanganan error -------------------------------------------------
  print('[9] penanganan error');
  try {
    await api.getTugasById('00000000-0000-0000-0000-000000000000');
    cek('404 melempar ApiException', false);
  } on ApiException catch (e) {
    cek('404 melempar ApiException', e.statusCode == 404, e.message);
    cek('isNotFound true', e.isNotFound);
  }

  try {
    await api.createMataKuliah(nama: 'Verifikasi Dart 2', sks: 3);
    cek('duplikat ditolak', false);
  } on ApiException catch (e) {
    cek('duplikat ditolak', e.statusCode == 400, e.message);
  }

  try {
    await api.patchTugas(tugas.id);
    cek('patch kosong ditolak lokal', false);
  } on ApiException catch (e) {
    cek('patch kosong ditolak lokal', e.message.contains('Tidak ada field'));
  }

  // --- 10. Bersihkan -------------------------------------------------------
  print('[10] cleanup');
  await api.deleteTugas(tugas.id);
  final sisaTugas = await api.getTugas(mataKuliahId: mk.id);
  cek('tugas terhapus', sisaTugas.isEmpty);

  final jumlahTerhapus = await api.deleteMataKuliah(mk.id);
  cek('deleteMataKuliah balikin jumlah tugas terhapus', jumlahTerhapus == 0,
      'terhapus=$jumlahTerhapus');

  api.close();

  print('');
  print('HASIL: $_lulus lulus, $_gagal gagal');
  exit(_gagal == 0 ? 0 : 1);
}
