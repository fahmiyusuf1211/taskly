import { Router } from 'express';
import { query } from '../db.js';
import { TASK_SELECT, toMataKuliah } from '../lib/serialize.js';
import {
  asyncRoute,
  badRequest,
  notFound,
  optionalString,
  requireDate,
  requireEnum,
  requireInt,
  requireString,
} from '../lib/validate.js';

const router = Router();

const STATUSES = ['todo', 'inProgress', 'completed'];

// GET /api/mata-kuliah — daftar mata kuliah + jumlah tugasnya
router.get(
  '/',
  asyncRoute(async (_req, res) => {
    const { rows } = await query(
      `SELECT mk.id, mk.nama, mk.sks, count(t.id)::int AS jumlah_tugas
       FROM mata_kuliah mk
       LEFT JOIN tugas t ON t.mata_kuliah_id = mk.id
       GROUP BY mk.id, mk.nama, mk.sks
       ORDER BY mk.nama ASC`,
    );
    res.json({
      data: rows.map((row) => ({ ...toMataKuliah(row), jumlahTugas: row.jumlah_tugas })),
    });
  }),
);

// GET /api/mata-kuliah/:id
router.get(
  '/:id',
  asyncRoute(async (req, res) => {
    const { rows } = await query('SELECT id, nama, sks FROM mata_kuliah WHERE id = $1', [
      req.params.id,
    ]);
    if (!rows[0]) throw notFound('Mata kuliah tidak ditemukan');
    res.json({ data: toMataKuliah(rows[0]) });
  }),
);

// POST /api/mata-kuliah
router.post(
  '/',
  asyncRoute(async (req, res) => {
    const nama = requireString(req.body?.nama, 'nama', { max: 100 });
    const sks = requireInt(req.body?.sks, 'sks', { min: 0, max: 12 });

    try {
      const { rows } = await query(
        'INSERT INTO mata_kuliah (nama, sks) VALUES ($1, $2) RETURNING id, nama, sks',
        [nama, sks],
      );
      res.status(201).json({ data: toMataKuliah(rows[0]) });
    } catch (err) {
      if (err.code === '23505') throw badRequest(`Mata kuliah "${nama}" sudah ada`);
      throw err;
    }
  }),
);

// PUT /api/mata-kuliah/:id
router.put(
  '/:id',
  asyncRoute(async (req, res) => {
    const nama = requireString(req.body?.nama, 'nama', { max: 100 });
    const sks = requireInt(req.body?.sks, 'sks', { min: 0, max: 12 });

    try {
      const { rows } = await query(
        'UPDATE mata_kuliah SET nama = $1, sks = $2 WHERE id = $3 RETURNING id, nama, sks',
        [nama, sks, req.params.id],
      );
      if (!rows[0]) throw notFound('Mata kuliah tidak ditemukan');
      res.json({ data: toMataKuliah(rows[0]) });
    } catch (err) {
      if (err.code === '23505') throw badRequest(`Mata kuliah "${nama}" sudah ada`);
      throw err;
    }
  }),
);

// DELETE /api/mata-kuliah/:id
// Menghapus mata kuliah ikut menghapus tugasnya (ON DELETE CASCADE di skema).
// Jumlah tugas yang ikut terhapus dikirim balik supaya aplikasi bisa
// menampilkan konfirmasi yang jujur ke user.
router.delete(
  '/:id',
  asyncRoute(async (req, res) => {
    const { rows } = await query(
      `WITH dihapus AS (
         DELETE FROM mata_kuliah WHERE id = $1 RETURNING id
       )
       SELECT (SELECT count(*)::int FROM dihapus)                         AS mata_kuliah,
              (SELECT count(*)::int FROM tugas WHERE mata_kuliah_id = $1) AS tugas`,
      [req.params.id],
    );
    if (rows[0].mata_kuliah === 0) throw notFound('Mata kuliah tidak ditemukan');
    res.json({ data: { id: req.params.id, tugasTerhapus: rows[0].tugas } });
  }),
);

export default router;
export { STATUSES, TASK_SELECT };
