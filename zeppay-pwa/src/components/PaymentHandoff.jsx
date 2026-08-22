import { useEffect, useState } from 'react';
import { copyText } from '../lib/clipboard';
import { buildPaymentSummary } from '../lib/upiLink';
import { CopyVpaChip } from './ScanScreen';

export function PaymentHandoff({ telLink, draft, onReturn }) {
  const [phase, setPhase] = useState(1);
  const [returned, setReturned] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    let seenAway = false;

    async function launch() {
      const ok = await copyText(draft.vpa);
      setCopied(ok);
      setPhase(2);
      window.setTimeout(() => {
        window.location.href = telLink;
        setPhase(3);
      }, 600);
    }

    launch();

    const onShow = () => {
      if (document.visibilityState !== 'visible') {
        seenAway = true;
        return;
      }
      if (seenAway) {
        setReturned(true);
        onReturn?.();
      }
    };
    document.addEventListener('visibilitychange', onShow);
    return () => document.removeEventListener('visibilitychange', onShow);
  }, [telLink, draft.vpa, onReturn]);

  async function copySummary() {
    await copyText(buildPaymentSummary(draft));
  }

  function openPhone() {
    window.location.href = telLink;
  }

  return (
    <div className="card stack handoff">
      <div className="handoff-status">
        <span className="pulse-dot" aria-hidden />
        <strong>{returned ? 'Welcome back' : 'Opening Phone…'}</strong>
      </div>

      <CopyVpaChip vpa={draft.vpa} />

      <div className="step-list">
        <Step done={copied} active={phase >= 1} label="UPI ID copied to clipboard" />
        <Step done={phase >= 3} active={phase >= 2} label={`Dialing *99*1*3# for ₹${draft.amount}`} />
        <Step active={phase >= 3} label="Paste ID if asked, enter PIN in Phone" />
      </div>

      <p className="muted small">
        iOS runs the full USSD menu in Phone — Zep Pay cannot read the result.
        You will confirm success on the next screen.
      </p>

      <button type="button" className="btn-secondary" onClick={openPhone}>
        Open Phone again
      </button>
      <button type="button" className="btn-ghost" onClick={copySummary}>
        Copy payment summary
      </button>
    </div>
  );
}

function Step({ label, done = false, active = false }) {
  return (
    <div className={`step-row ${active ? 'active' : ''} ${done ? 'done' : ''}`}>
      <span className="step-bullet">{done ? '✓' : '•'}</span>
      <span>{label}</span>
    </div>
  );
}
