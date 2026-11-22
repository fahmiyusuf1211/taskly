/// Error yang berasal dari API Taskly.
///
/// Backend selalu membalas error dalam bentuk:
///   { "error": "pesan dalam bahasa Indonesia" }
///
/// Pesannya sengaja diteruskan apa adanya (bukan diterjemahkan ulang di sini),
/// supaya lapisan UI bisa langsung menampilkannya:
///
///   try { ... } on ApiException catch (e) {
///     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
///   }
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Pesan siap tampil ke pengguna.
  final String message;

  /// Kode HTTP (400, 404, 409, 500, ...). Null kalau gagal sebelum
  /// server menjawab — misalnya koneksi putus atau timeout.
  final int? statusCode;

  /// True kalau masalahnya di jaringan, bukan di server.
  /// Berguna untuk membedakan pesan "periksa koneksi" dari pesan validasi.
  bool get isNetworkError => statusCode == null;

  /// True kalau datanya memang tidak ada (bukan kesalahan pengguna).
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
