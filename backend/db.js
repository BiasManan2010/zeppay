const crypto = require('crypto');

const url = (process.env.SUPABASE_URL || '').replace(/\/+$/, '');
const key = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const pepper = process.env.OTP_PEPPER || 'zeppay';

function enabled() {
  return Boolean(url && key);
}

function headers() {
  return {
    apikey: key,
    Authorization: `Bearer ${key}`,
    'Content-Type': 'application/json',
  };
}

function phoneHash(phone) {
  return crypto.createHash('sha256').update(`${pepper}:${phone}`).digest('hex');
}

async function rpc(name, body) {
  if (!enabled()) return null;
  const res = await fetch(`${url}/rest/v1/rpc/${name}`, {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`supabase ${name}: ${res.status} ${text}`);
  }
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function issueOtp(phone, codeHash, expiresAt) {
  if (!enabled()) return false;
  await rpc('issue_otp', {
    p_phone: phone,
    p_hash: codeHash,
    p_expires: expiresAt.toISOString(),
  });
  return true;
}

async function takeOtp(phone, codeHash) {
  if (!enabled()) return null;
  return Boolean(await rpc('take_otp', { p_phone: phone, p_hash: codeHash }));
}

async function touchUser(phone) {
  if (!enabled()) return false;
  await rpc('touch_app_user', { p_hash: phoneHash(phone) });
  return true;
}

async function userCount() {
  if (!enabled()) return null;
  const n = await rpc('app_user_count', {});
  return typeof n === 'number' ? n : Number(n);
}

module.exports = {
  enabled,
  phoneHash,
  issueOtp,
  takeOtp,
  touchUser,
  userCount,
};
