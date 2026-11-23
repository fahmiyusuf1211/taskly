/// Konfigurasi terpusat untuk koneksi ke REST API Taskly.
///
/// Base URL sengaja hanya ada di satu tempat ini, supaya saat pindah server
/// (atau ganti ke domain sendiri) tidak perlu menyisir seluruh kode.
///
/// Cara mengganti tanpa mengedit file:
///   flutter run --dart-define=API_BASE_URL=http://192.168.100.5:3000
///   flutter build web --dart-define=API_BASE_URL=https://taskly.example.com
class ApiConfig {
  const ApiConfig._();

  /// Alamat backend. Default menunjuk ke VM Lightsail tempat API berjalan.
  ///
  /// WAJIB https:// — server mengalihkan (301) semua permintaan http:// ke
  /// https://. Redirect itu tidak diikuti untuk POST/PUT/PATCH, sehingga
  /// respons yang diterima berupa HTML dan gagal di-parse sebagai JSON.
  ///
  /// Nilai diambil dari --dart-define kalau ada. Perhatikan: untuk web,
  /// nilai ini di-*bake* saat build, bukan dibaca saat runtime.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://16.78.104.237',
  );

  /// Batas waktu satu request. 10 detik cukup longgar untuk koneksi
  /// seluler lambat, tapi tetap cepat gagal kalau server mati.
  static const Duration timeout = Duration(seconds: 10);
}
