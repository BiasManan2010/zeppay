import { useEffect, useId, useRef, useState } from 'react';
import { Html5Qrcode } from 'html5-qrcode';
import { parseQr } from '../lib/qrParser';
import { copyText } from '../lib/clipboard';

export function ScanScreen({ onResult, onBack }) {
  const regionId = useId().replace(/:/g, '');
  const scannerRef = useRef(null);
  const [error, setError] = useState('');
  const [manual, setManual] = useState('');

  useEffect(() => {
    let active = true;
    const scanner = new Html5Qrcode(regionId);
    scannerRef.current = scanner;

    scanner
      .start(
        { facingMode: 'environment' },
        { fps: 10, qrbox: { width: 240, height: 240 } },
        (decoded) => {
          const draft = parseQr(decoded);
          if (!draft) return;
          scanner.stop().catch(() => {});
          onResult(draft);
        },
        () => {},
      )
      .catch((err) => {
        if (!active) return;
        setError(
          err?.message?.includes('Permission')
            ? 'Camera access is needed to scan UPI QR codes.'
            : 'Could not start camera. Paste a UPI ID instead.',
        );
      });

    return () => {
      active = false;
      scanner
        .stop()
        .catch(() => {})
        .finally(() => scanner.clear().catch(() => {}));
    };
  }, [regionId, onResult]);

  function submitManual() {
    const draft = parseQr(manual.trim());
    if (!draft) {
      setError('Enter a valid UPI ID (name@bank) or paste a UPI link.');
      return;
    }
    onResult(draft);
  }

  return (
    <div className="stack">
      <div className="scan-frame card">
        <div id={regionId} className="scan-viewport" />
        <div className="scan-overlay">
          <span>Align UPI QR inside the frame</span>
        </div>
      </div>

      {error ? <p className="error-text">{error}</p> : null}

      <div className="card stack">
        <label className="field-label">
          Or paste UPI link / ID
          <input
            className="field"
            placeholder="merchant@okicici or upi://pay?pa=…"
            value={manual}
            onChange={(e) => {
              setManual(e.target.value);
              setError('');
            }}
          />
        </label>
        <button type="button" className="btn-secondary" onClick={submitManual}>
          Use this UPI ID
        </button>
      </div>

      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}

export function CopyVpaChip({ vpa, onCopied }) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    const ok = await copyText(vpa);
    if (ok) {
      setCopied(true);
      onCopied?.();
      setTimeout(() => setCopied(false), 2000);
    }
  }

  return (
    <button type="button" className="copy-chip" onClick={copy}>
      <span className="copy-chip-label">{copied ? 'Copied!' : 'Copy UPI ID'}</span>
      <span className="copy-chip-vpa">{vpa}</span>
    </button>
  );
}
