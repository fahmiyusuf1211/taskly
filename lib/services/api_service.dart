import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/mata_kuliah_model.dart';
import '../models/task_model.dart';
import 'api_exception.dart';

/// Satu pintu untuk semua komunikasi HTTP ke backend Taskly.
///
/// Pemakaian dasar:
///
///   final api = ApiService();
///   final matkul = await api.getMataKuliah();
///   final tugas  = await api.getTugas();
///
///   final baru = await api.createTugas(
///     TaskModel(id: '', title: 'Laporan', mataKuliah: matkul.first,
///               deadline: DateTime.now().add(const Duration(days: 3))),
///   );
///
/// Semua method melempar [ApiException] (bukan Exception generik), dan
/// pesannya sudah berbahasa Indonesia dari server — siap ditampilkan
/// langsung di SnackBar/dialog tanpa dipetakan ulang.
///
/// Catatan untuk pengujian: [client] bisa diisi `MockClient` dari
/// package:http/testing.dart, jadi tidak perlu server sungguhan saat unit test.
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Dipanggil sekali saat aplikasi selesai (mis. di dispose controller).
  void close() => _client.close();

  // ==========================================================================
  // MATA KULIAH
  // ==========================================================================

  /// GET /api/mata-kuliah — semua mata kuliah, urut nama, plus jumlah tugasnya.
  Future<List<MataKuliahModel>> getMataKuliah() async {
    final json = await _send('GET', '/api/mata-kuliah');
    final list = json['data'] as List<dynamic>;
    return list
        .map((item) => MataKuliahModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/mata-kuliah/:id
  Future<MataKuliahModel> getMataKuliahById(String id) async {
    final json = await _send('GET', '/api/mata-kuliah/$id');
    return MataKuliahModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// POST /api/mata-kuliah
  ///
  /// `id` pada objek yang dikembalikan diisi server; `jumlahTugas` = 0.
  Future<MataKuliahModel> createMataKuliah({
    required String nama,
    required int sks,
  }) async {
    final json = await _send(
      'POST',
      '/api/mata-kuliah',
      body: {'nama': nama, 'sks': sks},
    );
    return MataKuliahModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// PUT /api/mata-kuliah/:id
  Future<MataKuliahModel> updateMataKuliah(MataKuliahModel mataKuliah) async {
    final json = await _send(
      'PUT',
      '/api/mata-kuliah/${mataKuliah.id}',
      body: mataKuliah.toJson(),
    );
    return MataKuliahModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/mata-kuliah/:id
  ///
  /// Menghapus mata kuliah ikut menghapus semua tugasnya (ON DELETE CASCADE).
  /// Nilai balik = jumlah tugas yang ikut terhapus, supaya UI bisa
  /// menampilkan konfirmasi yang jujur ke pengguna.
  Future<int> deleteMataKuliah(String id) async {
    final json = await _send('DELETE', '/api/mata-kuliah/$id');
    final data = json['data'] as Map<String, dynamic>;
    return (data['tugasTerhapus'] as num?)?.toInt() ?? 0;
  }

  // ==========================================================================
  // TUGAS
  // ==========================================================================

  /// GET /api/tugas — daftar tugas, default urut deadline terdekat.
  ///
  /// Parameter opsional diteruskan ke server apa adanya:
  ///   status          : 'todo' | 'inProgress' | 'completed'
  ///   mataKuliahId    : hanya tugas dari mata kuliah tertentu
  ///   search          : cari di judul dan deskripsi
  ///   sort            : 'deadline' | '-deadline' | 'created' | 'pemahaman' | 'title'
  ///
  /// Tidak ada sort berdasarkan prioritas: skor prioritas bergantung pada
  /// tanggal hari ini, jadi pengurutannya dilakukan di sisi aplikasi lewat
  /// `TaskModel.skorPrioritas`.
  Future<List<TaskModel>> getTugas({
    String? status,
    String? mataKuliahId,
    String? search,
    String? sort,
    int? limit,
    int? offset,
  }) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (mataKuliahId != null) query['mata_kuliah_id'] = mataKuliahId;
    if (search != null) query['search'] = search;
    if (sort != null) query['sort'] = sort;
    if (limit != null) query['limit'] = '$limit';
    if (offset != null) query['offset'] = '$offset';

    final json = await _send('GET', '/api/tugas', query: query);
    final list = json['data'] as List<dynamic>;
    return list
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/tugas/:id
  Future<TaskModel> getTugasById(String id) async {
    final json = await _send('GET', '/api/tugas/$id');
    return TaskModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// GET /api/tugas/stats/summary — angka untuk dashboard & halaman statistik.
  Future<TugasStats> getStats() async {
    final json = await _send('GET', '/api/tugas/stats/summary');
    return TugasStats.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// POST /api/tugas
  ///
  /// `id` pada objek yang dikirim diabaikan server — id dibuat database.
  Future<TaskModel> createTugas(TaskModel tugas) async {
    final json = await _send('POST', '/api/tugas', body: tugas.toRequestJson());
    return TaskModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// PUT /api/tugas/:id — ganti seluruh field.
  Future<TaskModel> updateTugas(TaskModel tugas) async {
    final json = await _send(
      'PUT',
      '/api/tugas/${tugas.id}',
      body: tugas.toRequestJson(),
    );
    return TaskModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/tugas/:id — ubah sebagian field saja.
  ///
  /// Paling sering dipakai untuk tombol checklist:
  ///   await api.patchTugas(tugas.id, status: 'completed');
  Future<TaskModel> patchTugas(
    String id, {
    String? title,
    String? mataKuliahId,
    String? description,
    DateTime? deadline,
    int? pemahaman,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (mataKuliahId != null) body['mataKuliahId'] = mataKuliahId;
    if (description != null) body['description'] = description;
    if (deadline != null) body['deadline'] = deadline.toUtc().toIso8601String();
    if (pemahaman != null) body['pemahaman'] = pemahaman;
    if (status != null) body['status'] = status;

    if (body.isEmpty) {
      throw const ApiException('Tidak ada field yang diubah');
    }

    final json = await _send('PATCH', '/api/tugas/$id', body: body);
    return TaskModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/tugas/:id
  Future<void> deleteTugas(String id) async {
    await _send('DELETE', '/api/tugas/$id');
  }

  /// GET /api/health — berguna untuk menampilkan status server di UI
  /// atau saat memeriksa kenapa data tidak mau muncul.
  Future<bool> checkHealth() async {
    try {
      final json = await _send('GET', '/api/health');
      return json['status'] == 'ok';
    } on ApiException {
      return false;
    }
  }

  // ==========================================================================
  // INTI: satu tempat untuk menyusun request & menerjemahkan respons
  // ==========================================================================

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );

    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed = await _client.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
        'Server tidak merespons dalam ${ApiConfig.timeout.inSeconds} detik. '
        'Periksa koneksi lalu coba lagi.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Gagal menghubungi server: ${e.message}');
    }

    // DELETE membalas 204 tanpa body.
    if (response.statusCode == 204 || response.body.isEmpty) {
      if (response.statusCode >= 400) {
        throw ApiException(_pesanDefault(response.statusCode),
            statusCode: response.statusCode);
      }
      return const {};
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(
        'Respons server tidak dapat dibaca (bukan JSON).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      // Server selalu mengirim { "error": "..." } untuk kegagalan.
      final pesan = json['error'] as String? ?? _pesanDefault(response.statusCode);
      throw ApiException(pesan, statusCode: response.statusCode);
    }

    return json;
  }

  String _pesanDefault(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Data yang dikirim tidak valid.';
      case 404:
        return 'Data tidak ditemukan.';
      case 500:
        return 'Terjadi kesalahan di server.';
      default:
        return 'Permintaan gagal (HTTP $statusCode).';
    }
  }
}

/// Ringkasan angka tugas, dipakai halaman Statistik dan kartu progres.
class TugasStats {
  const TugasStats({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.completed,
    required this.overdue,
    required this.dueThisWeek,
  });

  final int total;
  final int todo;
  final int inProgress;
  final int completed;
  final int overdue;
  final int dueThisWeek;

  factory TugasStats.fromJson(Map<String, dynamic> json) {
    return TugasStats(
      total: (json['total'] as num).toInt(),
      todo: (json['todo'] as num).toInt(),
      inProgress: (json['inProgress'] as num).toInt(),
      completed: (json['completed'] as num).toInt(),
      overdue: (json['overdue'] as num).toInt(),
      dueThisWeek: (json['dueThisWeek'] as num).toInt(),
    );
  }
}
