// Kumpulan helper: validasi input, tipe error, dan pembungkus async.
// Sengaja tanpa library validasi — VM hanya 442 MB RAM, tiap dependency
// menambah memori dan permukaan serang.

export class HttpError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

export const badRequest = (message, details) => new HttpError(400, message, details);
export const notFound = (message = 'Data tidak ditemukan') => new HttpError(404, message);

// Express 4 tidak menangkap rejection dari handler async secara otomatis.
export const asyncRoute = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

export function requireString(value, field, { min = 1, max = 255 } = {}) {
  if (typeof value !== 'string') throw badRequest(`${field} wajib diisi`);
  const trimmed = value.trim();
  if (trimmed.length < min) throw badRequest(`${field} minimal ${min} karakter`);
  if (trimmed.length > max) throw badRequest(`${field} maksimal ${max} karakter`);
  return trimmed;
}

export function optionalString(value, field, { max = 2000 } = {}) {
  if (value === undefined || value === null) return '';
  if (typeof value !== 'string') throw badRequest(`${field} harus berupa teks`);
  if (value.length > max) throw badRequest(`${field} maksimal ${max} karakter`);
  return value.trim();
}

export function requireEnum(value, field, allowed) {
  if (!allowed.includes(value)) {
    throw badRequest(`${field} harus salah satu dari: ${allowed.join(', ')}`);
  }
  return value;
}

export function requireInt(value, field, { min = -Infinity, max = Infinity } = {}) {
  const num = Number(value);
  if (!Number.isInteger(num)) throw badRequest(`${field} harus bilangan bulat`);
  if (num < min || num > max) throw badRequest(`${field} harus antara ${min} dan ${max}`);
  return num;
}

export function requireDate(value, field) {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw badRequest(`${field} harus tanggal valid (ISO 8601)`);
  }
  return date;
}
