import { useState } from 'react';
import { isValidVpa } from '../lib/qrParser';
import { copyText } from '../lib/clipboard';

export function RecipientEntry({ value, onChange, onNext, onBack }) {
  const [copied, setCopied] = useState(false);
  const valid = isValidVpa(value.trim());

  async function copyId() {
    if (!valid) return;
    const ok = await copyText(value.trim());
    if (ok) {
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    }
  }

  return (
    <div className="stack">
      <div className="card stack">
        <label className="field-label">
          Enter UPI ID
          <input
            className="field"
            placeholder="name@okicici"
            autoCapitalize="none"
            autoCorrect="off"
            spellCheck={false}
            value={value}
            onChange={(e) => onChange(e.target.value)}
          />
        </label>
        <p className="muted small">
          We copy the ID before dialing *99# so you can paste inside Phone.
        </p>
        <button
          type="button"
          className="btn-secondary"
          onClick={copyId}
          disabled={!valid}
        >
          {copied ? 'Copied!' : 'Copy UPI ID'}
        </button>
      </div>

      <button type="button" className="btn-primary" onClick={onNext} disabled={!valid}>
        Continue
      </button>
      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}
