-- Taskly — skema database (PostgreSQL 17)
-- Idempoten: aman dijalankan berulang kali.
--
-- Mengikuti model yang ada di lib/models/ pada repo nailulgh/taskly:
--
--   MataKuliahModel { id, nama, sks }
--   TaskModel { id, title, mataKuliah, deadline, description, pemahaman, status }
--
-- Catatan penting: TIDAK ada kolom priority.
-- Prioritas dihitung di sisi Flutter (TaskModel.skorPrioritas) dengan rumus
--   skor = (sks * (6 - pemahaman)) / sisa_hari
-- jadi yang perlu disimpan hanya input-nya: sks (ada di mata_kuliah) dan
-- pemahaman. Menyimpan hasil hitungan di DB akan bikin dua sumber kebenaran
-- yang bisa berbeda begitu tanggal berganti.

CREATE TABLE IF NOT EXISTS mata_kuliah (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       text        NOT NULL CHECK (length(btrim(nama)) BETWEEN 1 AND 100),
  sks        smallint    NOT NULL CHECK (sks BETWEEN 0 AND 12),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Nama mata kuliah tidak boleh kembar (dibandingkan tanpa peduli huruf besar/kecil).
CREATE UNIQUE INDEX IF NOT EXISTS mata_kuliah_nama_key ON mata_kuliah (lower(btrim(nama)));

CREATE TABLE IF NOT EXISTS tugas (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  title          text        NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 200),
  mata_kuliah_id uuid        NOT NULL REFERENCES mata_kuliah (id) ON DELETE CASCADE,
  description    text        NOT NULL DEFAULT '',
  deadline       timestamptz NOT NULL,
  -- Skala 1-5, jangkar labelnya ada di lib/models/pemahaman.dart
  pemahaman      smallint    NOT NULL DEFAULT 3 CHECK (pemahaman BETWEEN 1 AND 5),
  status         text        NOT NULL DEFAULT 'todo'
                 CHECK (status IN ('todo', 'inProgress', 'completed')),
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

-- Daftar tugas hampir selalu diambil urut deadline dan difilter per matkul.
CREATE INDEX IF NOT EXISTS tugas_deadline_idx       ON tugas (deadline);
CREATE INDEX IF NOT EXISTS tugas_mata_kuliah_idx    ON tugas (mata_kuliah_id);
CREATE INDEX IF NOT EXISTS tugas_status_idx         ON tugas (status);

-- updated_at diurus database, bukan aplikasi, supaya tidak bisa lupa di-set.
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tugas_set_updated_at ON tugas;
CREATE TRIGGER tugas_set_updated_at
  BEFORE UPDATE ON tugas
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS mata_kuliah_set_updated_at ON mata_kuliah;
CREATE TRIGGER mata_kuliah_set_updated_at
  BEFORE UPDATE ON mata_kuliah
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
