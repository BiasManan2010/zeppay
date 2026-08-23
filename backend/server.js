/**
 * Twilio OTP proxy + Supabase census.
 *
 *   TWILIO_ACCOUNT_SID=ACxx TWILIO_AUTH_TOKEN=xx \
 *   TWILIO_MESSAGING_SERVICE_SID=MGxx \
 *   SUPABASE_URL=https://xxxx.supabase.co \
 *   SUPABASE_SERVICE_ROLE_KEY=eyJ... \
 *   node server.js
 *
 * Render: set env vars in the dashboard; PORT is injected. App URL:
 *   https://YOUR-SERVICE.onrender.com
 * App Settings → OTP proxy URL, or --dart-define=TWILIO_VERIFY_URL=that URL
 */
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Optional local secrets file (copy backend/env.example → backend/.env).
const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = value;
  }
}

const express = require('express');
const twilio = require('twilio');
const db = require('./db');

const app = express();
app.use(express.json());
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

function e164(phone) {
  const d = String(phone || '').replace(/\D/g, '');
  if (d.length === 10) return `+91${d}`;
  if (d.startsWith('91') && d.length === 12) return `+${d}`;
  if (String(phone).startsWith('+')) return String(phone);
  return d ? `+${d}` : '';
}

function six() {
  return String(crypto.randomInt(100000, 1000000));
}

function hashCode(code) {
  return crypto.createHash('sha256').update(String(code)).digest('hex');
}

const sid = process.env.TWILIO_ACCOUNT_SID || '';
const token = process.env.TWILIO_AUTH_TOKEN || '';
const verifySid = process.env.TWILIO_VERIFY_SID || '';
const messagingSid = process.env.TWILIO_MESSAGING_SERVICE_SID || '';
const fromNumber = process.env.TWILIO_FROM || '';
const useVerify = Boolean(sid && token && verifySid);
const useSms = Boolean(sid && token && (messagingSid || fromNumber));
const live = useVerify || useSms;
const client = live ? twilio(sid, token) : null;
const memoryOtps = new Map();

async function persistOtp(phone, code) {
  const exp = new Date(Date.now() + 10 * 60 * 1000);
  const hashed = hashCode(code);
  memoryOtps.set(phone, { hash: hashed, exp: exp.getTime() });
  try {
    await db.issueOtp(phone, hashed, exp);
  } catch (e) {
    console.error('supabase issue_otp', e.message);
  }
}

async function matchOtp(phone, code) {
  const hashed = hashCode(code);
  try {
    const fromDb = await db.takeOtp(phone, hashed);
    if (fromDb === true) {
      memoryOtps.delete(phone);
      return true;
    }
    if (fromDb === false) return false;
  } catch (e) {
    console.error('supabase take_otp', e.message);
  }
  const row = memoryOtps.get(phone);
  const ok =
    Boolean(row) && Date.now() <= row.exp && row.hash === hashed;
  if (ok) memoryOtps.delete(phone);
  return ok;
}

async function rememberUser(phone) {
  try {
    await db.touchUser(phone);
  } catch (e) {
    console.error('supabase touch_app_user', e.message);
  }
}

async function healthBody() {
  let users = null;
  try {
    users = await db.userCount();
  } catch (_) {}
  return {
    ok: true,
    service: 'zeppay-otp',
    twilio: live,
    mode: useVerify ? 'verify' : useSms ? 'messaging' : 'dev',
    supabase: db.enabled(),
    users,
  };
}

app.get('/', async (_req, res) => {
  res.json(await healthBody());
});

app.get('/health', async (_req, res) => {
  res.json(await healthBody());
});

app.get('/stats/users', async (_req, res) => {
  try {
    const users = await db.userCount();
    res.json({ users: users ?? 0, supabase: db.enabled() });
  } catch (e) {
    res.status(400).json({ error: String(e) });
  }
});

app.post('/verify/start', async (req, res) => {
  try {
    const phone = e164(req.body.phone);
    if (!phone) return res.status(400).json({ error: 'phone required' });
    if (!live) {
      await persistOtp(phone, '123456');
      return res.json({ ok: true, dev: true, hint: '123456' });
    }

    if (useVerify) {
      await client.verify.v2
        .services(verifySid)
        .verifications.create({ to: phone, channel: 'sms' });
      return res.json({ ok: true, mode: 'verify', to: phone });
    }

    const code = six();
    await persistOtp(phone, code);
    const payload = {
      to: phone,
      body: `Zep Pay code ${code}. Valid 10 minutes. Do not share it.`,
    };
    if (messagingSid) payload.messagingServiceSid = messagingSid;
    else payload.from = fromNumber;
    await client.messages.create(payload);
    console.log('otp sms accepted', phone);
    res.json({ ok: true, mode: 'messaging', to: phone });
  } catch (e) {
    const code = e && e.code;
    const msg = e && e.message ? e.message : String(e);
    console.error('otp sms failed', phone, code, msg);
    let error = msg;
    if (
      code === 21608 ||
      code === 21211 ||
      /unverified/i.test(msg) ||
      /not a valid/i.test(msg)
    ) {
      error =
        `Twilio trial can only text numbers you add under Verified Caller IDs. Add ${phone} there, or upgrade the Twilio account.`;
    } else if (/permission/i.test(msg) && /geo|region|india/i.test(msg)) {
      error =
        'Twilio is blocked from sending SMS to this country. Enable India in Messaging Geographic Permissions.';
    }
    res.status(400).json({ error, to: phone, twilio: code || null });
  }
});

app.post('/verify/check', async (req, res) => {
  try {
    const phone = e164(req.body.phone);
    const code = String(req.body.code || '');
    if (!phone) return res.status(400).json({ error: 'phone required' });

    if (!live) {
      const approved = code === '123456';
      if (approved) {
        await matchOtp(phone, code);
        await rememberUser(phone);
      }
      return res.json({
        approved,
        status: approved ? 'approved' : 'pending',
      });
    }

    if (useVerify) {
      const check = await client.verify.v2
        .services(verifySid)
        .verificationChecks.create({ to: phone, code });
      const approved = check.status === 'approved';
      if (approved) await rememberUser(phone);
      return res.json({ approved, status: check.status });
    }

    const approved = await matchOtp(phone, code);
    if (approved) await rememberUser(phone);
    res.json({
      approved,
      status: approved ? 'approved' : 'pending',
    });
  } catch (e) {
    res.status(400).json({ error: String(e) });
  }
});

const port = Number(process.env.PORT) || 8787;
app.listen(port, '0.0.0.0', () =>
  console.log(
    `Zep Pay OTP proxy on :${port} (${useVerify ? 'verify' : useSms ? 'messaging' : 'dev'}; supabase ${db.enabled() ? 'on' : 'off'})`,
  ),
);
