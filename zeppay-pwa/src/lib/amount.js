/** Sanitize amount field input — digits and one decimal, max 2 fraction digits. */
export function sanitizeAmountInput(value) {
  let v = String(value ?? '').replace(/[^\d.]/g, '');
  const dot = v.indexOf('.');
  if (dot !== -1) {
    const head = v.slice(0, dot + 1);
    const tail = v.slice(dot + 1).replace(/\./g, '').slice(0, 2);
    v = head + tail;
  }
  return v;
}

/** Parse rupee amount from user input — null when empty or invalid. */
export function parseAmount(raw) {
  const cleaned = sanitizeAmountInput(raw).trim();
  if (!cleaned || cleaned === '.') return null;
  if (!/^\d+(\.\d{1,2})?$/.test(cleaned)) return null;
  const n = Number(cleaned);
  if (!Number.isFinite(n) || n <= 0) return null;
  return Math.round(n * 100) / 100;
}

export function formatRupee(amount) {
  const n = Number(amount);
  if (!Number.isFinite(n)) return '0.00';
  return n.toFixed(2);
}
