/**
 * Twilio Verify proxy — keep the Auth Token off-device.
 *
 *   npm i express twilio
 *   TWILIO_ACCOUNT_SID=ACxx TWILIO_AUTH_TOKEN=xx TWILIO_VERIFY_SID=VAxx node server.js
 *
 * Then run the app with:
 *   flutter run --dart-define=TWILIO_VERIFY_URL=http://YOUR_LAN_IP:8787
 */
const express = require('express');
const twilio = require('twilio');

const app = express();
app.use(express.json());

const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
const service = process.env.TWILIO_VERIFY_SID;

app.post('/verify/start', async (req, res) => {
  try {
    const phone = req.body.phone;
    await client.verify.v2.services(service).verifications.create({ to: phone, channel: 'sms' });
    res.json({ ok: true });
  } catch (e) {
    res.status(400).json({ error: String(e) });
  }
});

app.post('/verify/check', async (req, res) => {
  try {
    const { phone, code } = req.body;
    const check = await client.verify.v2.services(service).verificationChecks.create({
      to: phone,
      code,
    });
    res.json({ approved: check.status === 'approved', status: check.status });
  } catch (e) {
    res.status(400).json({ error: String(e) });
  }
});

app.listen(process.env.PORT || 8787, () => console.log('Zep Pay verify proxy on :8787'));
