/**
 * Twilio Verify proxy — keep the Auth Token off-device.
 *
 *   npm i
 *   TWILIO_ACCOUNT_SID=ACxx TWILIO_AUTH_TOKEN=xx TWILIO_VERIFY_SID=VAxx node server.js
 *
 * Then in the app: Settings → Verify URL → http://YOUR_LAN_IP:8787
 * or  flutter run --dart-define=TWILIO_VERIFY_URL=http://YOUR_LAN_IP:8787
 */
const express = require('express');
const twilio = require('twilio');

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

const sid = process.env.TWILIO_ACCOUNT_SID || '';
const token = process.env.TWILIO_AUTH_TOKEN || '';
const service = process.env.TWILIO_VERIFY_SID || '';
const live = Boolean(sid && token && service);
const client = live ? twilio(sid, token) : null;

app.get('/health', (_req, res) => {
  res.json({ ok: true, twilio: live });
});

app.post('/verify/start', async (req, res) => {
  try {
    const phone = e164(req.body.phone);
    if (!phone) return res.status(400).json({ error: 'phone required' });
    if (!live) return res.json({ ok: true, dev: true, hint: '123456' });
    await client.verify.v2.services(service).verifications.create({ to: phone, channel: 'sms' });
    res.json({ ok: true });
  } catch (e) {
    res.status(400).json({ error: String(e) });
  }
});

app.post('/verify/check', async (req, res) => {
  try {
    const phone = e164(req.body.phone);
    const code = String(req.body.code || '');
    if (!live) return res.json({ approved: code === '123456', status: code === '123456' ? 'approved' : 'pending' });
    const check = await client.verify.v2.services(service).verificationChecks.create({
      to: phone,
      code,
    });
    res.json({ approved: check.status === 'approved', status: check.status });
  } catch (e) {
    res.status(400).json({ error: String(e) });
  }
});

app.listen(process.env.PORT || 8787, '0.0.0.0', () => console.log('Zep Pay verify proxy on :8787'));
