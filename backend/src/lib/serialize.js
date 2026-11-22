// Pemetaan baris database -> JSON yang dipakai aplikasi Flutter.
//
// Bentuk JSON sengaja mengikuti model Dart di repo nailulgh/taskly:
//
//   MataKuliahModel { id, nama, sks }
//   TaskModel { id, title, mataKuliah: {...}, deadline, description, pemahaman, status }
//
// Field `mataKuliah` dikirim sebagai objek bersarang (bukan sekadar id),
// supaya Flutter bisa langsung pakai .mataKuliah.nama dan .mataKuliah.sks
// untuk menghitung skorPrioritas tanpa perlu request tambahan.
//
// Query yang memakai mapper ini WAJIB JOIN ke mata_kuliah dan meng-alias
// kolomnya seperti di bawah — lihat TASK_SELECT di routes/tugas.js.

export const toMataKuliah = (row) => ({
  id: row.id,
  nama: row.nama,
  sks: row.sks,
});

export const toTask = (row) => ({
  id: row.id,
  title: row.title,
  mataKuliah: {
    id: row.mata_kuliah_id,
    nama: row.mata_kuliah_nama,
    sks: row.mata_kuliah_sks,
  },
  deadline: row.deadline.toISOString(),
  description: row.description,
  pemahaman: row.pemahaman,
  status: row.status,
});

// Kolom yang harus di-SELECT untuk toTask(). Dipakai di semua query tugas
// agar hasilnya konsisten dan tidak ada kolom yang lupa di-alias.
export const TASK_SELECT = `
  t.id, t.title, t.description, t.deadline, t.pemahaman, t.status,
  t.mata_kuliah_id,
  mk.nama AS mata_kuliah_nama,
  mk.sks  AS mata_kuliah_sks
`;
