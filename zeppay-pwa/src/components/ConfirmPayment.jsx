import { useState } from 'react';
import { formatRupee, parseAmount } from '../lib/amount';
import { CopyVpaChip } from './ScanScreen';

export function ConfirmPayment({ draft, onPay, onBack }) {
  const who = draft.name?.trim() || draft.vpa;
  const parsed = parseAmount(draft.amount);
  const [busy, setBusy] = useState(false);

  function handlePay() {
    if (!parsed || busy) return;
    setBusy(true);
    onPay(parsed);
  }

  return (
    <div className="stack confirm">
      <div className="payee-card card">
        <div className="payee-avatar">{initials(who)}</div>
        <div>
          <div className="muted">Paying</div>
          <strong className="payee-name">{who}</strong>
          <CopyVpaChip vpa={draft.vpa} />
        </div>
      </div>

      <div className="amount-display card">
        <div className="muted">Amount</div>
        <div className="amount-value">₹{parsed ? formatRupee(parsed) : '—'}</div>
        {draft.note ? <div className="note-line">Note: {draft.note}</div> : null}
      </div>

      <div className="instruction card">
        <strong>Offline payment steps</strong>
        <ol className="steps">
          <li>UPI ID is copied automatically</li>
          <li>Phone opens with *99*1*3# pre-filled</li>
          <li>Paste ID if asked, confirm amount, enter PIN in Phone</li>
        </ol>
        <p className="muted small">
          Zep Pay does not redirect to GPay, PhonePe, or any UPI app. Your bank
          session stays in the Phone dialer.
        </p>
      </div>

      <button
        type="button"
        className={`btn-primary${busy ? ' is-busy' : ''}`}
        onClick={handlePay}
        disabled={!parsed || busy}
        aria-busy={busy}
      >
        {busy ? 'Starting dialer…' : 'Copy ID & dial *99#'}
      </button>
      <button type="button" className="btn-ghost" onClick={onBack} disabled={busy}>
        Back
      </button>
    </div>
  );
}

function initials(label) {
  const parts = label.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  return label.slice(0, 2).toUpperCase();
}
