import { useEffect, useRef, useState } from 'react';
import { copyText } from '../lib/clipboard';

function buildUpiQrText(vpa, name) {
  const params = new URLSearchParams({ pa: vpa });
  if (name?.trim()) params.set('pn', name.trim());
  return `upi://pay?${params.toString()}`;
}

/** Minimal deterministic QR-like pattern for demo (not full QR spec). */
function drawSimpleQr(canvas, text) {
  const ctx = canvas.getContext('2d');
  const size = canvas.width;
  ctx.fillStyle = '#fff8f2';
  ctx.fillRect(0, 0, size, size);
  const cells = 21;
  const cell = Math.floor(size / cells);
  let hash = 0;
  for (let i = 0; i < text.length; i++) hash = (hash * 31 + text.charCodeAt(i)) >>> 0;
  ctx.fillStyle = '#1a1a1a';
  for (let y = 0; y < cells; y++) {
    for (let x = 0; x < cells; x++) {
      const bit = (hash + x * 17 + y * 31) % 5;
      if (bit === 0 || (x < 7 && y < 7) || (x > cells - 8 && y < 7) || (x < 7 && y > cells - 8)) {
        ctx.fillRect(x * cell, y * cell, cell - 1, cell - 1);
      }
    }
  }
}

export function ProfileScreen({ profile, onSave }) {
  const canvasRef = useRef(null);
  const [name, setName] = useState(profile.name || '');
  const [vpa, setVpa] = useState(profile.vpa || '');
  const [saved, setSaved] = useState('');

  useEffect(() => {
    setName(profile.name || '');
    setVpa(profile.vpa || '');
  }, [profile]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !vpa.includes('@')) return;
    drawSimpleQr(canvas, buildUpiQrText(vpa, name));
  }, [vpa, name]);

  function handleSave() {
    onSave({ name: name.trim(), vpa: vpa.trim(), phone: profile.phone || '' });
    setSaved('Profile saved on this device.');
  }

  return (
    <div className="stack">
      <div className="card stack profile-card">
        <label className="field-label">
          Display name
          <input className="field" value={name} onChange={(e) => setName(e.target.value)} />
        </label>
        <label className="field-label">
          Your UPI ID
          <input className="field mono" value={vpa} onChange={(e) => setVpa(e.target.value)} />
        </label>
        <button type="button" className="btn-primary" onClick={handleSave}>
          Save profile
        </button>
        {saved ? <p className="banner-note">{saved}</p> : null}
      </div>

      {vpa.includes('@') ? (
        <div className="card stack qr-card">
          <strong>Receive payments</strong>
          <p className="muted small">Share your UPI ID or QR — offline peers can scan in Zep Pay.</p>
          <canvas ref={canvasRef} className="qr-canvas" width={200} height={200} aria-label="UPI QR" />
          <button type="button" className="btn-secondary" onClick={() => copyText(vpa)}>
            Copy UPI ID
          </button>
        </div>
      ) : (
        <p className="muted">Add a valid UPI ID to show your receive QR.</p>
      )}
    </div>
  );
}
