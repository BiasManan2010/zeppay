const VPA_RE = /[a-z0-9][a-z0-9._-]*@[a-z0-9]+/i;

/** Decode NPCI UPI, Bharat QR, intent wrappers, and loose pay links. */
export function parseQr(raw) {
  const value = unwrap(raw);
  if (!value) return null;

  return (
    fromUpiUri(value) ||
    fromHttp(value) ||
    fromEmv(value) ||
    fromLooseQuery(value) ||
    fromBareVpa(value)
  );
}

function unwrap(raw) {
  let value = raw.trim().replace(/\r/g, '').replace(/\n/g, '');
  if (!value) return '';

  const intent = value.toLowerCase().indexOf('intent://');
  if (intent >= 0) {
    let body = value.slice(intent + 'intent://'.length);
    const hash = body.indexOf('#');
    if (hash >= 0) body = body.slice(0, hash);
    if (!body.toLowerCase().startsWith('upi:')) body = `upi://${body}`;
    return body;
  }
  return value;
}

function fromUpiUri(value) {
  const lower = value.toLowerCase();
  const upiAt = lower.indexOf('upi://');
  if (upiAt < 0) return null;

  let candidate = value.slice(upiAt);
  const end = candidate.search(/[\n\r]/);
  if (end > 0) candidate = candidate.slice(0, end);

  let uri;
  try {
    uri = new URL(candidate);
  } catch {
    return fromLooseQuery(candidate);
  }
  if (uri.protocol !== 'upi:') return fromLooseQuery(candidate);

  const pa = q(uri, 'pa');
  const vpa = pa.includes('@') ? pa : firstVpa(candidate);
  if (!vpa || !isValidVpa(vpa)) return null;

  return draft(vpa, uri);
}

function fromHttp(value) {
  let uri;
  try {
    uri = new URL(value);
  } catch {
    return null;
  }
  if (uri.protocol !== 'http:' && uri.protocol !== 'https:') return null;

  const pa = q(uri, 'pa') || q(uri, 'vpa');
  const vpa = pa.includes('@') ? pa : firstVpa(value);
  if (!vpa || !isValidVpa(vpa)) return null;

  return draft(vpa, uri);
}

function fromEmv(value) {
  if (!value.includes('000201')) return null;
  const nested = value.match(/upi:\/\/pay\?[^\s]+/i);
  if (nested) return fromUpiUri(nested[0]);
  const vpa = firstVpa(value);
  if (!vpa) return null;
  return { vpa: vpa.toLowerCase(), name: '', amount: '', note: '' };
}

function fromLooseQuery(value) {
  const vpa = firstVpa(value);
  if (!vpa || !isValidVpa(vpa)) return null;

  const am = value.match(/(?:^|[?&])am=([^&\s]+)/i)?.[1];
  const pn = decode(value.match(/(?:^|[?&])pn=([^&\s]+)/i)?.[1] || '');
  const tn = decode(value.match(/(?:^|[?&])tn=([^&\s]+)/i)?.[1] || '');

  return {
    vpa: vpa.toLowerCase(),
    name: pn,
    amount: am && Number(am) > 0 ? String(Number(am)) : '',
    note: tn,
  };
}

function fromBareVpa(value) {
  const trimmed = value.trim();
  if (!isValidVpa(trimmed)) return null;
  return { vpa: trimmed.toLowerCase(), name: '', amount: '', note: '' };
}

function draft(vpa, uri) {
  const amountRaw = q(uri, 'am');
  const amount =
    amountRaw && Number(amountRaw) > 0 ? String(Number(amountRaw)) : '';
  return {
    vpa: vpa.toLowerCase(),
    name: q(uri, 'pn'),
    amount,
    note: q(uri, 'tn') || q(uri, 'tr') || q(uri, 'purpose'),
  };
}

function q(uri, key) {
  return decode(uri.searchParams.get(key) || '');
}

function decode(value) {
  try {
    return decodeURIComponent(value.replace(/\+/g, ' '));
  } catch {
    return value;
  }
}

function firstVpa(text) {
  const match = text.match(VPA_RE);
  return match ? match[0] : null;
}

export function isValidVpa(vpa) {
  return /^[a-z0-9][a-z0-9._-]*@[a-z0-9]+$/i.test(vpa.trim());
}
