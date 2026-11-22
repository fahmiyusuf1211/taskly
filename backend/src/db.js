import pg from 'pg';

const { Pool } = pg;

// Postgres hanya listen di localhost (lihat /etc/postgresql/17/main/conf.d/99-taskly.conf),
// jadi koneksi ini tidak pernah lewat jaringan publik.
export const pool = new Pool({
  host: process.env.DB_HOST ?? '127.0.0.1',
  port: Number(process.env.DB_PORT ?? 5432),
  user: process.env.DB_USER ?? 'taskly',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME ?? 'taskly',
  max: Number(process.env.DB_POOL_MAX ?? 10),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

pool.on('error', (err) => {
  console.error('[db] idle client error:', err.message);
});

export const query = (text, params) => pool.query(text, params);
