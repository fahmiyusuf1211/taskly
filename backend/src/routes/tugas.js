import { Router } from 'express';
import { query } from '../db.js';
import { TASK_SELECT, toTask } from '../lib/serialize.js';
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
const JOIN = 'FROM tugas t JOIN mata_kuliah mk ON mk.id = t.mata_kuliah_id';

// GET /api/tugas?status=&mata_kuliah_id=&search=&sort=&limit=&offset=
//
// Catatan: tidak ada parameter `sort=prioritas` di sini dengan sengaja.
// Skor prioritas = (sks * (6 - pemahaman)) / sisa_hari bergantung pada
// tanggal hari ini, jadi perhitungannya ada di sisi Flutter
// (TaskModel.skorPrioritas). Server cukup mengirim data mentahnya.
router.get(
  '/',
  asyncRoute(async (req, res) => {
    const conditions = [];
    const values = [];

    if (req.query.status) {
      values.push(requireEnum(req.query.status, 'status', STATUSES));
      conditions.push(`t.status = $${values.length}`);
    }

    if (req.query.mata_kuliah_id) {
      values.push(requireString(req.query.mata_kuliah_id, 'mata_kuliah_id', { max: 64 }));
      conditions.push(`t.mata_kuliah_id = $${values.length}`);
    }

    if (req.query.search) {
      values.push(`%${requireString(req.query.search, 'search', { max: 100 })}%`);
      conditions.push(`(t.title ILIKE $${values.length} OR t.description ILIKE $${values.length})`);
    }

    // Whitelist: nama kolom tidak boleh datang dari input user.
    const sortMap = {
      deadline: 't.deadline ASC',
      '-deadline': 't.deadline DESC',
      created: 't.created_at DESC',
      pemahaman: 't.pemahaman ASC',
      title: 'lower(t.title) ASC',
    };
    const sortKey = req.query.sort ?? 'deadline';
    const sort = sortMap[sortKey];
    if (!sort) {
      throw badRequest(`sort harus salah satu dari: ${Object.keys(sortMap).join(', ')}`);
    }

    const limit = Math.min(Number(req.query.limit ?? 100) || 100, 200);
    const offset = Math.max(Number(req.query.offset ?? 0) || 0, 0);
    values.push(limit, offset);

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
    const { rows } = await query(
      `SELECT ${TASK_SELECT} ${JOIN} ${where}
       ORDER BY ${sort}, t.id
       LIMIT $${values.length - 1} OFFSET $${values.length}`,
      values,
    );

    res.json({ data: rows.map(toTask), limit, offset });
  }),
);

// GET /api/tugas/stats/summary
// WAJIB di atas /:id — kalau tidak, Express menangkap "stats" sebagai id
// dan endpoint ini tidak pernah tercapai.
router.get(
  '/stats/summary',
  asyncRoute(async (_req, res) => {
    const { rows } = await query(
      `SELECT
         count(*)::int                                                          AS total,
         count(*) FILTER (WHERE status = 'todo')::int                           AS todo,
         count(*) FILTER (WHERE status = 'inProgress')::int                     AS in_progress,
         count(*) FILTER (WHERE status = 'completed')::int                      AS completed,
         count(*) FILTER (WHERE status <> 'completed' AND deadline < now())::int AS overdue,
         count(*) FILTER (WHERE status <> 'completed'
                            AND deadline >= now()
                            AND deadline < now() + interval '7 days')::int      AS due_this_week
       FROM tugas`,
    );

    const row = rows[0];
    res.json({
      data: {
        total: row.total,
        todo: row.todo,
        inProgress: row.in_progress,
        completed: row.completed,
        overdue: row.overdue,
        dueThisWeek: row.due_this_week,
      },
    });
  }),
);

// GET /api/tugas/:id
router.get(
  '/:id',
  asyncRoute(async (req, res) => {
    const { rows } = await query(`SELECT ${TASK_SELECT} ${JOIN} WHERE t.id = $1`, [
      req.params.id,
    ]);
    if (!rows[0]) throw notFound('Tugas tidak ditemukan');
    res.json({ data: toTask(rows[0]) });
  }),
);

// POST /api/tugas
router.post(
  '/',
  asyncRoute(async (req, res) => {
    const body = req.body ?? {};
    const title = requireString(body.title, 'title', { max: 200 });
    const mataKuliahId = requireString(body.mataKuliahId, 'mataKuliahId', { max: 64 });
    const description = optionalString(body.description, 'description');
    const deadline = requireDate(body.deadline, 'deadline');
    const pemahaman = requireInt(body.pemahaman ?? 3, 'pemahaman', { min: 1, max: 5 });
    const status = requireEnum(body.status ?? 'todo', 'status', STATUSES);

    let inserted;
    try {
      ({ rows: [inserted] } = await query(
        `INSERT INTO tugas (title, mata_kuliah_id, description, deadline, pemahaman, status)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id`,
        [title, mataKuliahId, description, deadline, pemahaman, status],
      ));
    } catch (err) {
      // 23503 = foreign_key_violation: mata kuliah yang dirujuk tidak ada.
      if (err.code === '23503') throw badRequest('Mata kuliah tidak ditemukan');
      throw err;
    }

    // Baca ulang dengan JOIN supaya bentuk responsnya sama dengan GET.
    const { rows } = await query(`SELECT ${TASK_SELECT} ${JOIN} WHERE t.id = $1`, [inserted.id]);
    res.status(201).json({ data: toTask(rows[0]) });
  }),
);

// PUT /api/tugas/:id — ganti seluruh field yang bisa diubah
router.put(
  '/:id',
  asyncRoute(async (req, res) => {
    const body = req.body ?? {};
    const title = requireString(body.title, 'title', { max: 200 });
    const mataKuliahId = requireString(body.mataKuliahId, 'mataKuliahId', { max: 64 });
    const description = optionalString(body.description, 'description');
    const deadline = requireDate(body.deadline, 'deadline');
    const pemahaman = requireInt(body.pemahaman ?? 3, 'pemahaman', { min: 1, max: 5 });
    const status = requireEnum(body.status ?? 'todo', 'status', STATUSES);

    let updated;
    try {
      ({ rows: [updated] } = await query(
        `UPDATE tugas
         SET title = $1, mata_kuliah_id = $2, description = $3,
             deadline = $4, pemahaman = $5, status = $6
         WHERE id = $7
         RETURNING id`,
        [title, mataKuliahId, description, deadline, pemahaman, status, req.params.id],
      ));
    } catch (err) {
      if (err.code === '23503') throw badRequest('Mata kuliah tidak ditemukan');
      throw err;
    }
    if (!updated) throw notFound('Tugas tidak ditemukan');

    const { rows } = await query(`SELECT ${TASK_SELECT} ${JOIN} WHERE t.id = $1`, [updated.id]);
    res.json({ data: toTask(rows[0]) });
  }),
);

// PATCH /api/tugas/:id — ubah sebagian field (dipakai tombol checklist status)
router.patch(
  '/:id',
  asyncRoute(async (req, res) => {
    const body = req.body ?? {};
    const fields = [];
    const values = [];

    if (body.title !== undefined) {
      values.push(requireString(body.title, 'title', { max: 200 }));
      fields.push(`title = $${values.length}`);
    }
    if (body.mataKuliahId !== undefined) {
      values.push(requireString(body.mataKuliahId, 'mataKuliahId', { max: 64 }));
      fields.push(`mata_kuliah_id = $${values.length}`);
    }
    if (body.description !== undefined) {
      values.push(optionalString(body.description, 'description'));
      fields.push(`description = $${values.length}`);
    }
    if (body.deadline !== undefined) {
      values.push(requireDate(body.deadline, 'deadline'));
      fields.push(`deadline = $${values.length}`);
    }
    if (body.pemahaman !== undefined) {
      values.push(requireInt(body.pemahaman, 'pemahaman', { min: 1, max: 5 }));
      fields.push(`pemahaman = $${values.length}`);
    }
    if (body.status !== undefined) {
      values.push(requireEnum(body.status, 'status', STATUSES));
      fields.push(`status = $${values.length}`);
    }

    if (fields.length === 0) throw badRequest('Tidak ada field yang diubah');

    values.push(req.params.id);
    let updated;
    try {
      ({ rows: [updated] } = await query(
        `UPDATE tugas SET ${fields.join(', ')} WHERE id = $${values.length} RETURNING id`,
        values,
      ));
    } catch (err) {
      if (err.code === '23503') throw badRequest('Mata kuliah tidak ditemukan');
      throw err;
    }
    if (!updated) throw notFound('Tugas tidak ditemukan');

    const { rows } = await query(`SELECT ${TASK_SELECT} ${JOIN} WHERE t.id = $1`, [updated.id]);
    res.json({ data: toTask(rows[0]) });
  }),
);

// DELETE /api/tugas/:id
router.delete(
  '/:id',
  asyncRoute(async (req, res) => {
    const { rowCount } = await query('DELETE FROM tugas WHERE id = $1', [req.params.id]);
    if (rowCount === 0) throw notFound('Tugas tidak ditemukan');
    res.status(204).end();
  }),
);

export default router;
