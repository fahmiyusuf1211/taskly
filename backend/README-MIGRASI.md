# Menyambungkan ApiService ke halaman

Panduan migrasi: mengganti data contoh (`main_shell.dart`) dengan data dari REST API.

`ApiService` dan modelnya **sudah siap** (lihat `lib/services/api_service.dart`).
Yang tersisa adalah pekerjaan UI/state — dan itu **bukan** pekerjaan sepele,
karena semua handler di `main_shell.dart` saat ini berjalan **sinkron dan
instan**, sedangkan API bisa **lambat dan gagal**.

Dokumen ini memetakan persis apa yang harus berubah, supaya bisa dikerjakan
tanpa menebak.

---

## Ringkasan yang berubah

| Saat ini | Setelah migrasi |
|---|---|
| Data di `main_shell.dart` ditulis manual | Diambil dari `api.getTugas()` saat aplikasi dibuka |
| `void _addTask(...)` — selesai instan | `Future<void>` — menunggu server, bisa gagal |
| `setState` langsung mengubah list | `setState` setelah server membalas |
| Tidak ada indikator memuat | Perlu `isLoading` |
| Tidak ada penanganan gagal | Perlu pesan error + tombol coba lagi |
| List kosong = tidak mungkin | List kosong = keadaan normal (perlu empty state) |

**Konsekuensi yang harus diterima:** tampilan **akan** berubah. Menambah
loading spinner, banner error, dan empty state berarti ada elemen baru di
layar. Ini tidak bisa dihindari — aplikasi yang memakai jaringan harus
mengomunikasikan tiga keadaan itu ke pengguna.

---

## 1. Tujuh handler yang harus berubah

Semuanya ada di `lib/screens/main_shell.dart`. Kolom "pemanggil" menunjukkan
file lain yang ikut terkena kalau signature-nya berubah.

| Handler | Baris | Signature sekarang | Pemanggil lain |
|---|---|---|---|
| `_addMataKuliah` | 60 | `void f(MataKuliahModel)` | `mata_kuliah_screen.dart:137` |
| `_updateMataKuliah` | 64 | `void f(MataKuliahModel)` | `mata_kuliah_screen.dart:130` |
| `_deleteMataKuliah` | 78 | `void f(String)` | `mata_kuliah_screen.dart:227` |
| `_addTask` | 86 | `void f(TaskModel)` | `tasks_screen.dart:45` |
| `_updateTask` | 90 | `void f(TaskModel)` | `detail_task_screen.dart:44,75` |
| `_deleteTask` | 99 | `void f(String)` | `detail_task_screen.dart:71,107` |
| `_toggleTaskStatus` | 103 | `void f(TaskModel)` | `dashboard_screen.dart:145` |

Perhatikan `_toggleTaskStatus`: dipanggil dari **dashboard** dan **detail**.
Kalau signature-nya jadi `Future<void>`, tipe `ValueChanged<TaskModel>` di
`dashboard_screen.dart:17` juga harus jadi `Future<void> Function(TaskModel)`.

---

## 2. Pola dasar: sebelum dan sesudah

### Contoh: `_toggleTaskStatus` (paling sering dipakai)

**Sebelum** — `main_shell.dart:103`

```dart
void _toggleTaskStatus(TaskModel task) {
  setState(() {
    task.status = task.status == TaskStatus.completed
        ? TaskStatus.todo
        : TaskStatus.completed;
  });
}
```

**Sesudah**

```dart
Future<void> _toggleTaskStatus(TaskModel task) async {
  final statusBaru = task.status == TaskStatus.completed ? 'todo' : 'completed';

  // Optimistic update: UI langsung berubah, jadi terasa responsif.
  // Kalau server menolak, perubahan dikembalikan di blok catch.
  final statusLama = task.status;
  setState(() => task.status = TaskStatus.values.byName(statusBaru));

  try {
    final terbaru = await _api.patchTugas(task.id, status: statusBaru);
    setState(() {
      final i = _tasks.indexWhere((t) => t.id == terbaru.id);
      if (i != -1) _tasks[i] = terbaru;   // pakai versi dari server
    });
  } on ApiException catch (e) {
    setState(() => task.status = statusLama);   // kembalikan
    _tampilkanError(e.message);
  }
}
```

**Kenapa optimistic:** checklist yang terasa lambat 1 detik itu mengganggu.
Tapi kalau kamu pilih **tunggu server dulu** (lebih sederhana, lebih aman),
cukup hilangkan baris optimistic-nya — tetap benar, hanya terasa lebih lambat.

### Contoh: `_deleteTask`

**Sebelum** — `main_shell.dart:99`

```dart
void _deleteTask(String id) {
  setState(() => _tasks.removeWhere((t) => t.id == id));
}
```

**Sesudah**

```dart
Future<void> _deleteTask(String id) async {
  try {
    await _api.deleteTugas(id);
    setState(() => _tasks.removeWhere((t) => t.id == id));
  } on ApiException catch (e) {
    // Penting: JANGAN hapus dari list kalau server gagal.
    // Kalau dihapus duluan lalu gagal, data di layar berbeda dengan database.
    _tampilkanError(e.message);
  }
}
```

### Contoh: `_addTask`

**Sebelum** — `main_shell.dart:86`

```dart
void _addTask(TaskModel task) {
  setState(() => _tasks.insert(0, task));
}
```

**Sesudah**

```dart
Future<void> _addTask(TaskModel task) async {
  try {
    // Server yang membuat id. Objek dari form masih punya id sementara,
    // jadi yang dimasukkan ke list harus hasil balikan server.
    final baru = await _api.createTugas(task);
    setState(() => _tasks.insert(0, baru));
  } on ApiException catch (e) {
    _tampilkanError(e.message);
    rethrow;   // biar pemanggil (form) tahu submit-nya gagal
  }
}
```

### Contoh: `_deleteMataKuliah`

Ini spesial: menghapus mata kuliah **ikut menghapus tugasnya** di database
(`ON DELETE CASCADE`). `deleteMataKuliah()` mengembalikan jumlah tugas yang
ikut terhapus — pakai angka itu untuk konfirmasi yang jujur.

```dart
Future<void> _deleteMataKuliah(String id) async {
  try {
    final jumlahTugas = await _api.deleteMataKuliah(id);
    setState(() {
      _mataKuliahList.removeWhere((mk) => mk.id == id);
      _tasks.removeWhere((t) => t.mataKuliah.id == id);
    });
    if (jumlahTugas > 0) {
      _tampilkanInfo('$jumlahTugas tugas ikut terhapus.');
    }
  } on ApiException catch (e) {
    _tampilkanError(e.message);
  }
}
```

---

## 3. Mengambil data saat aplikasi dibuka

Di `main_shell.dart`, ganti data contoh dengan pemuatan awal.

```dart
class _MainShellState extends State<MainShell> {
  final ApiService _api = ApiService();

  List<MataKuliahModel> _mataKuliahList = [];
  List<TaskModel> _tasks = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _api.close();     // tutup HTTP client, jangan lupa
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Jalankan berbarengan, jangan berurutan — dua request sekaligus
      // jauh lebih cepat daripada satu lalu satu lagi.
      final hasil = await Future.wait([
        _api.getMataKuliah(),
        _api.getTugas(),
      ]);

      if (!mounted) return;   // widget bisa sudah dibuang saat request jalan
      setState(() {
        _mataKuliahList = hasil[0] as List<MataKuliahModel>;
        _tasks = hasil[1] as List<TaskModel>;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }
}
```

**Penting:** mata kuliah harus dimuat **sebelum atau bersamaan** tugas, karena
form tambah tugas butuh daftar mata kuliah untuk dropdown. Kalau kosong,
form tidak bisa disimpan.

---

## 4. Tiga keadaan yang wajib ditangani di UI

Ini bagian yang **pasti** mengubah tampilan. Tidak ada jalan menghindarinya:
aplikasi yang bergantung pada jaringan harus memberi tahu pengguna ketika
sedang memuat, gagal, atau tidak ada data.

### a. Sedang memuat

```dart
if (_isLoading) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}
```

Lebih baik lagi: **skeleton loader** yang menyerupai bentuk kartu, bukan
spinner di tengah layar kosong.

### b. Gagal memuat

```dart
if (_error != null) {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _muatData,          // coba lagi
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### c. Kosong (berhasil, tapi belum ada data)

```dart
if (_tasks.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.task_alt, size: 48, color: AppColors.muted),
        const SizedBox(height: 12),
        const Text('Belum ada tugas.'),
        const SizedBox(height: 8),
        Text(
          'Tekan tombol Tambah untuk membuat yang pertama.',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
```

Bedakan **"gagal memuat"** dari **"kosong"** — pesannya berbeda, dan
menampilkan "belum ada tugas" padahal servernya mati itu menyesatkan.

---

## 5. Menampilkan pesan error

Tambahkan satu helper di `_MainShellState`:

```dart
void _tampilkanError(String pesan) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(pesan),
      backgroundColor: AppColors.ink,
      action: SnackBarAction(
        label: 'Tutup',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}
```

Pesan dari server sudah berbahasa Indonesia dan siap tampil — tidak perlu
diterjemahkan ulang. Contoh yang mungkin muncul:

| Situasi | Pesan dari server |
|---|---|
| Nama matkul sudah ada | `Mata kuliah "Basis Data" sudah ada` |
| Judul kosong | `title minimal 1 karakter` |
| Pemahaman di luar 1–5 | `pemahaman harus antara 1 dan 5` |
| Data sudah dihapus orang lain | `Tugas tidak ditemukan` |
| Server mati | `Gagal menghubungi server: ...` |

---

## 6. Tiga jebakan yang paling sering kena

### a. `mounted` — widget bisa hilang saat request masih jalan

```dart
final data = await _api.getTugas();
if (!mounted) return;        // WAJIB sebelum setState
setState(() => _tasks = data);
```

Tanpa ini, aplikasi crash kalau pengguna pindah tab sebelum data datang.

### b. `toJson()` vs `toRequestJson()`

| Method | Bentuk | Untuk |
|---|---|---|
| `toJson()` | `mataKuliah` bersarang | simpan lokal / kirim objek utuh |
| `toRequestJson()` | `mataKuliahId` datar | body POST/PUT ke server |

`ApiService` sudah memakai yang benar. Jangan panggil `toJson()` untuk body
request — server akan menolak.

### c. Jangan pakai `TaskStatus.values.byName()` untuk data dari server

`byName()` melempar `ArgumentError` yang tidak informatif kalau server
mengirim nilai baru. `TaskModel.fromJson` sudah memakai `switch` eksplisit
dengan pesan jelas. Kalau kamu menambah nilai enum baru, **tambahkan juga di
`_statusFromString` dan `_statusToString`** di `lib/models/task_model.dart`,
dan di `CHECK` constraint `backend/db/schema.sql`.

---

## 7. Kalau memakai GetX controller

`jobdesk.md` menugaskan `TugasController` dengan `.obs`/`Obx`. Pola yang sama,
hanya pembungkusnya berbeda:

```dart
class TugasController extends GetxController {
  final _api = ApiService();

  final tugas = <TaskModel>[].obs;
  final mataKuliah = <MataKuliahModel>[].obs;
  final isLoading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    muat();
  }

  @override
  void onClose() {
    _api.close();
    super.onClose();
  }

  Future<void> muat() async {
    isLoading.value = true;
    error.value = null;
    try {
      final hasil = await Future.wait([_api.getMataKuliah(), _api.getTugas()]);
      mataKuliah.assignAll(hasil[0] as List<MataKuliahModel>);
      tugas.assignAll(hasil[1] as List<TaskModel>);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> ubahStatus(TaskModel t) async {
    final baru = t.status == TaskStatus.completed ? 'todo' : 'completed';
    try {
      final hasil = await _api.patchTugas(t.id, status: baru);
      final i = tugas.indexWhere((x) => x.id == hasil.id);
      if (i != -1) tugas[i] = hasil;
    } on ApiException catch (e) {
      error.value = e.message;
    }
  }
}
```

Lalu di layar:

```dart
final c = Get.find<TugasController>();

Obx(() {
  if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
  if (c.error.value != null) return ErrorView(pesan: c.error.value!, onRetry: c.muat);
  if (c.tugas.isEmpty) return const EmptyView();
  return ListView(children: c.tugas.map(...).toList());
})
```

Catatan: `main_shell.dart` saat ini memakai `setState`, bukan GetX. Kalau
pindah ke `TugasController`, `Get.put(TugasController())` harus dipanggil
sekali di `main.dart` atau di `MainShell.initState`.

---

## 8. Urutan pengerjaan yang disarankan

1. **`_muatData()` + tiga keadaan UI** — ini dulu, karena tanpa ini tidak ada
   data yang bisa ditampilkan.
2. **`_toggleTaskStatus`** — paling sering dipakai, dan paling terasa kalau salah.
3. **`_addTask` + `_updateTask`** — menyentuh form, koordinasi dengan Nailul.
4. **`_deleteTask`** — sederhana setelah pola di atas terbentuk.
5. **Tiga handler mata kuliah** — terakhir, karena paling jarang dipakai.

Kerjakan satu per satu dan uji tiap langkah. Jangan mengubah ketujuhnya
sekaligus — kalau ada yang salah, sulit dilacak.

---

## 9. Cara menguji tanpa merusak data

Server dev berisi data seed (4 mata kuliah, 3 tugas). Beberapa hal yang
berguna:

```bash
# isi ulang data seed kapan saja
dart run tool/seed.dart --force

# uji seluruh endpoint tanpa menyentuh aplikasi
dart run tool/verify_api.dart

# lihat log API langsung (dari laptop)
ssh taskly sudo journalctl -u taskly-api -f
```

Kalau ingin menguji keadaan gagal: matikan API sebentar
(`ssh taskly sudo systemctl stop taskly-api`), buka aplikasi, pastikan layar
error muncul dengan tombol "Coba lagi", lalu nyalakan lagi dan tekan tombolnya.
**Jangan lupa dinyalakan kembali.**

---

## 10. Referensi cepat method `ApiService`

| Method | Mengembalikan |
|---|---|
| `getMataKuliah()` | `List<MataKuliahModel>` (+ `jumlahTugas`) |
| `getMataKuliahById(id)` | `MataKuliahModel` |
| `createMataKuliah(nama:, sks:)` | `MataKuliahModel` |
| `updateMataKuliah(matkul)` | `MataKuliahModel` |
| `deleteMataKuliah(id)` | `int` — jumlah tugas yang ikut terhapus |
| `getTugas({status, mataKuliahId, search, sort, limit, offset})` | `List<TaskModel>` |
| `getTugasById(id)` | `TaskModel` |
| `createTugas(tugas)` | `TaskModel` (id dari server) |
| `updateTugas(tugas)` | `TaskModel` |
| `patchTugas(id, {status, pemahaman, title, ...})` | `TaskModel` |
| `deleteTugas(id)` | `void` |
| `getStats()` | `TugasStats` (total/todo/inProgress/completed/overdue/dueThisWeek) |
| `checkHealth()` | `bool` |
| `close()` | tutup HTTP client |

Semua method melempar `ApiException` dengan `message` berbahasa Indonesia
dan `statusCode`. Gunakan `e.isNetworkError` untuk membedakan masalah jaringan
dari kesalahan validasi.
