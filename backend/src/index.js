import express from 'express';
import { pool } from './db.js';
import mataKuliahRoutes from './routes/mata-kuliah.js';
import tugasRoutes from './routes/tugas.js';
import { HttpError } from './lib/validate.js';

const app = express();

// Di belakang nginx semua request datang dari 127.0.0.1; tanpa trust proxy
// req.ip selalu localhost dan log tidak berguna.
app.set('trust proxy', 'loopback');
app.disable('x-powered-by');

app.use(express.json({ limit: '256kb' }));

// Log ringkas, sengaja tanpa morgan supaya dependency tetap sedikit.
app.use((req, res, next) => {
  const startedAt = process.hrtime.bigint();
  res.on('finish', () => {
    const ms = Number(process.hrtime.bigint() - startedAt) / 1e6;
    console.log(`${req.method} ${req.originalUrl} ${res.statusCode} ${ms.toFixed(1)}ms`);
  });
  next();
});

// Health check: dipakai untuk memastikan API + Postgres hidup.
app.get('/api/health', async (_req, res) => {
  try {
    const { rows } = await pool.query('SELECT now() AS now');
    res.json({ status: 'ok', db: 'ok', time: rows[0].now });
  } catch (err) {
    res.status(503).json({ status: 'degraded', db: 'error', message: err.message });
  }
});

app.use('/api/mata-kuliah', mataKuliahRoutes);
app.use('/api/tugas', tugasRoutes);

app.use((req, res) => {
  res.status(404).json({ error: `Endpoint ${req.method} ${req.originalUrl} tidak ada` });
});

// Error handler terakhir: HttpError jadi JSON rapi, sisanya 500
// dan detailnya hanya masuk log server (tidak dibocorkan ke client).
app.use((err, _req, res, _next) => {
  if (err instanceof HttpError) {
    return res.status(err.status).json({ error: err.message, details: err.details });
  }
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Body bukan JSON yang valid' });
  }
  if (err.code === '22P02') {
    // invalid_text_representation: biasanya id bukan UUID yang valid
    return res.status(400).json({ error: 'Format id tidak valid' });
  }
  console.error('[error]', err);
  res.status(500).json({ error: 'Terjadi kesalahan di server' });
});

const port = Number(process.env.PORT ?? 3000);
const server = app.listen(port, '127.0.0.1', () => {
  console.log(`taskly-api listening on http://127.0.0.1:${port}`);
});

// Matikan dengan rapi agar koneksi Postgres tidak menggantung saat restart.
for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => {
    console.log(`${signal} diterima, menutup server...`);
    server.close(() => pool.end().then(() => process.exit(0)));
  });
}
