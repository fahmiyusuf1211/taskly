# Backend Taskly — REST API + PostgreSQL

Backend untuk aplikasi Flutter Taskly (UAS Praktikum Mobile Programming, Kelompok 4).
Node.js + Express + PostgreSQL, dijalankan di satu VM Lightsail bersama nginx.

## Kenapa satu VM, bukan RDS

Postgres, API, dan nginx berada di satu mesin:

```
Internet → nginx :80
              ├── /        → /var/www/taskly   (file statis `flutter build web`)
              └── /api/    → 127.0.0.1:3000    (Node/Express)
                                   ↓
                              PostgreSQL 17 (127.0.0.1:5432)
```

- Postgres **hanya** listen di `127.0.0.1`, tidak pernah terbuka ke internet.
- Web dan API satu origin → tidak ada masalah CORS.
- Biaya satu instance. RDS terpisah akan menambah sekitar $15/bulan untuk
  database yang isinya beberapa kilobyte.

## Bentuk data

Skema mengikuti model Dart di `lib/models/` apa adanya:

| Dart | Kolom database |
|---|---|
| `MataKuliahModel { id, nama, sks }` | tabel `mata_kuliah` |
| `TaskModel { id, title, mataKuliah, deadline, description, pemahaman, status }` | tabel `tugas` |

**Tidak ada kolom `priority`.** Prioritas dihitung di Flutter
(`TaskModel.skorPrioritas`):

```
skor = (sks × (6 − pemahaman)) / sisa_hari
```

yang dibutuhkan rumus itu hanya `sks` (dari mata kuliah) dan `pemahaman`
(1–5). Server mengirim data mentahnya; kalau skor ikut disimpan, nilainya
akan basi setiap kali tanggal berganti.

## Endpoint

Semua respons dibungkus `{ "data": ... }`, error `{ "error": "..." }`.

### Mata kuliah

| Method | Path | Keterangan |
|---|---|---|
| GET | `/api/mata-kuliah` | daftar + `jumlahTugas` tiap matkul |
| GET | `/api/mata-kuliah/:id` | satu matkul |
| POST | `/api/mata-kuliah` | `{ nama, sks }` — nama unik, tidak peduli besar/kecil |
| PUT | `/api/mata-kuliah/:id` | `{ nama, sks }` |
| DELETE | `/api/mata-kuliah/:id` | ikut menghapus tugasnya; balikan `tugasTerhapus` |

### Tugas

| Method | Path | Keterangan |
|---|---|---|
| GET | `/api/tugas` | filter `status`, `mata_kuliah_id`, `search`; sort `deadline`, `-deadline`, `created`, `pemahaman`, `title` |
| GET | `/api/tugas/:id` | satu tugas, `mataKuliah` bersarang |
| GET | `/api/tugas/stats/summary` | hitungan untuk halaman statistik |
| POST | `/api/tugas` | `{ title, mataKuliahId, deadline, description?, pemahaman?, status? }` |
| PUT | `/api/tugas/:id` | ganti seluruh field |
| PATCH | `/api/tugas/:id` | ubah sebagian (dipakai checklist status) |
| DELETE | `/api/tugas/:id` | hapus |

### Lain-lain

| Method | Path | Keterangan |
|---|---|---|
| GET | `/api/health` | cek API + koneksi database |

Contoh:

```bash
curl http://<ip>/api/tugas

curl -X POST http://<ip>/api/tugas \
  -H 'Content-Type: application/json' \
  -d '{"title":"Laporan praktikum","mataKuliahId":"<uuid>",
       "deadline":"2026-11-25T15:00:00Z","pemahaman":2}'
```

## Yang perlu disiapkan di sisi Flutter

Sudah tersedia di repo ini (bagian "Fondasi & Data Layer"):

| File | Isi |
|---|---|
| `lib/core/config.dart` | Base URL API di satu tempat |
| `lib/services/api_service.dart` | Semua HTTP call |
| `lib/services/api_exception.dart` | Error yang pesannya siap ditampilkan |
| `lib/models/mata_kuliah_model.dart` | + `fromJson` / `toJson` |
| `lib/models/task_model.dart` | + `fromJson` / `toJson` / `toRequestJson` |

> **Menyambungkan ke halaman:** lihat [`backend/README-MIGRASI.md`](backend/README-MIGRASI.md) —
> panduan lengkap mengganti data contoh di `main_shell.dart` dengan data API,
> termasuk 7 handler yang harus diubah, tiga keadaan UI (memuat/gagal/kosong),
> dan jebakan yang sering kena.

Yang **belum** dan jadi tugas berikutnya:

1. Ganti data contoh di `main_shell.dart` dengan hasil fetch (`TugasController`).
2. Sambungkan form `add_task_screen.dart` dan `mata_kuliah_screen.dart` ke `ApiService`.

### Contoh pemakaian ApiService

```dart
import '../services/api_service.dart';
import '../services/api_exception.dart';

final api = ApiService();

// --- Baca semua data -------------------------------------------------------
try {
  final daftarMatkul = await api.getMataKuliah();
  final daftarTugas  = await api.getTugas();        // urut deadline terdekat
  final statistik    = await api.getStats();        // total/completed/overdue
} on ApiException catch (e) {
  // e.message sudah berbahasa Indonesia dari server, siap ditampilkan
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
}

// --- Buat tugas (dari form) ------------------------------------------------
final baru = await api.createTugas(
  TaskModel(
    id: '',                                          // diisi server
    title: 'Laporan praktikum Modul 13',
    mataKuliah: daftarMatkul.first,
    deadline: DateTime.now().add(const Duration(days: 3)),
    pemahaman: 2,                                    // 1-5, lihat pemahaman.dart
  ),
);

// --- Checklist: ubah status saja ------------------------------------------
final selesai = await api.patchTugas(baru.id, status: 'completed');

// --- Filter ---------------------------------------------------------------
final tugasBasisData = await api.getTugas(mataKuliahId: daftarMatkul[1].id);
final belumSelesai   = await api.getTugas(status: 'todo');

// --- Hapus ----------------------------------------------------------------
await api.deleteTugas(baru.id);

// Mata kuliah: menghapus matkul ikut menghapus tugasnya.
// Nilai baliknya = jumlah tugas yang ikut terhapus, tampilkan di konfirmasi.
final jumlahTerhapus = await api.deleteMataKuliah(matkul.id);
```

### Dua hal yang mudah salah

**1. `toJson()` berbeda dari `toRequestJson()`.**

| Method | Bentuk | Dipakai untuk |
|---|---|---|
| `toJson()` | `mataKuliah` bersarang | cache lokal / kirim objek utuh |
| `toRequestJson()` | `mataKuliahId` datar | body POST/PUT ke server |

Server menolak `mataKuliah` berupa objek, dan `fromJson` butuh objek bersarang untuk mengisi `.nama` dan `.sks`. Karena itu keduanya dipisah.

**2. Tidak ada sort prioritas di server.**

Skor prioritas = `(sks × (6 − pemahaman)) / sisaHari` bergantung pada tanggal hari ini. Mengurutkannya di SQL berarti nilainya basi besok. Server mengirim data mentah; urutkan di aplikasi:

```dart
daftarTugas.sort((a, b) => b.skorPrioritas.compareTo(a.skorPrioritas));
```

### Mengganti alamat server tanpa mengedit kode

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.100.5:3000
flutter build web --release --dart-define=API_BASE_URL=https://taskly.example.com
```

### Menguji ApiService

```bash
dart run tool/verify_api.dart
```

Menembak API sungguhan: CRUD mata kuliah + tugas, filter, patch, stats,
penanganan error, lalu membersihkan data ujinya. Cetak `32 lulus, 0 gagal`
kalau semua beres.

### Mengisi data awal (seed)

```bash
dart run tool/seed.dart            # isi kalau database masih kosong
dart run tool/seed.dart --force    # hapus semua data dulu, lalu isi ulang
```

Isinya 4 mata kuliah (Pemrograman Mobile 3 SKS, Basis Data 3, RPL 2,
Kecerdasan Buatan 4) dan 3 tugas dengan deadline **relatif terhadap hari ini**:

| Tugas | Pemahaman | Deadline | Prioritas |
|---|---|---|---|
| Membuat laporan praktikum Modul 13 | 2 (masih bingung) | +1 hari | KRITIS |
| Perancangan ERD dan Skema Tabel | 3 (paham konsep) | +3 hari | DEKAT |
| Membaca modul Neural Network | 4 (perlu contekan) | +7 hari | SANTAI |

Deadline relatif dipakai supaya badge urgensi tetap masuk akal kapan pun
dijalankan — kalau tanggalnya dipatok mati, seminggu kemudian semua tugas
jadi "terlambat".

Seed ini **idempoten**: kalau database sudah berisi, script berhenti tanpa
mengubah apa pun (supaya data uji Fahmi/Nailul tidak hilang). Pakai `--force`
kalau memang mau reset.

Seed masuk **lewat API**, bukan `INSERT` langsung ke Postgres — jadi sekalian
menguji rantai lengkap: model Dart → `toRequestJson` → HTTP → Express →
validasi → Postgres → `fromJson`. Di akhir, script membaca ulang dan
memverifikasi bahwa skor prioritas serta label urgensinya sesuai tabel di atas.

Catatan: `stats.dueThisWeek` akan bernilai **2**, bukan 3. Tugas ketiga
deadline-nya tepat 7 hari dari sekarang (jam 23:59), sedangkan query memakai
batas `< now() + 7 hari`, jadi tugas itu berada sedikit di luar batas.


## Deploy & operasi

```bash
# dari laptop, kirim kode terbaru + restart service
./backend/deploy/deploy.sh

# lihat log API
ssh taskly sudo journalctl -u taskly-api -f
```

### Build web

Build Flutter web **di laptop**, bukan di server — VM hanya punya 442 MB RAM
dan compiler Dart butuh jauh lebih besar dari itu.

```bash
flutter build web --release
tar -C build/web -czf - . | ssh taskly \
  'sudo rm -rf /var/www/taskly/* && sudo tar -C /var/www/taskly -xzf - && sudo chown -R www-data:www-data /var/www/taskly'
```

## Berkas deployment

| File | Tujuan di server |
|---|---|
| `deploy/postgres-99-taskly.conf` | `/etc/postgresql/17/main/conf.d/99-taskly.conf` |
| `deploy/taskly-api.service` | `/etc/systemd/system/taskly-api.service` |
| `deploy/nginx-taskly.conf` | `/etc/nginx/sites-available/taskly` |
| `deploy/certbot-renew.service` | `/etc/systemd/system/certbot-renew.service` |
| `deploy/certbot-renew.timer` | `/etc/systemd/system/certbot-renew.timer` |
| `deploy/deploy.sh` | dijalankan dari laptop |
