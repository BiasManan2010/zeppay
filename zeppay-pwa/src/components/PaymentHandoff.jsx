import { useEffect, useRef, useState } from 'react';
import { copyText } from '../lib/clipboard';
import { buildPaymentSummary } from '../lib/upiLink';
import { CopyVpaChip } from './ScanScreen';

const HANDOFF_TIMEOUT_MS = 2 * 60 * 1000;

export function PaymentHandoff({ telLink, draft, onConfirmed, onPendingTimeout }) {
  const [phase, setPhase] = useState('launching');
  const [copied, setCopied] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const launchedRef = useRef(false);
  const seenAwayRef = useRef(false);
  const confirmShownRef = useRef(false);
  const onConfirmedRef = useRef(onConfirmed);
  const onPendingTimeoutRef = useRef(onPendingTimeout);

  useEffect(() => {
    onConfirmedRef.current = onConfirmed;
  }, [onConfirmed]);

  useEffect(() => {
    onPendingTimeoutRef.current = onPendingTimeout;
  }, [onPendingTimeout]);

  useEffect(() => {
    if (launchedRef.current) return;
    launchedRef.current = true;

    let cancelled = false;

    async function launch() {
      const ok = await copyText(draft.vpa);
      if (cancelled) return;
      setCopied(ok);
      setPhase('dialing');
      window.setTimeout(() => {
        if (cancelled) return;
        window.location.href = telLink;
        setPhase('away');
      }, 450);
    }

    launch();

    function showConfirm() {
      if (confirmShownRef.current || cancelled) return;
      confirmShownRef.current = true;
      setPhase('confirm');
    }

    const onVis = () => {
      if (document.visibilityState === 'hidden') {
        seenAwayRef.current = true;
        return;
      }
      if (seenAwayRef.current) showConfirm();
    };

    const onPageShow = () => {
      if (seenAwayRef.current) showConfirm();
    };

    const onFocus = () => {
      if (seenAwayRef.current) showConfirm();
    };

    document.addEventListener('visibilitychange', onVis);
    window.addEventListener('pageshow', onPageShow);
    window.addEventListener('focus', onFocus);

    const timeout = window.setTimeout(() => {
      if (!confirmShownRef.current && !cancelled) {
        onPendingTimeoutRef.current?.();
      }
    }, HANDOFF_TIMEOUT_MS);

    return () => {
      cancelled = true;
      document.removeEventListener('visibilitychange', onVis);
      window.removeEventListener('pageshow', onPageShow);
      window.removeEventListener('focus', onFocus);
      window.clearTimeout(timeout);
    };
  }, [telLink, draft.vpa]);

  async function confirm(status) {
    if (submitting) return;
    setSubmitting(true);
    try {
      await onConfirmedRef.current?.(status);
    } finally {
      setSubmitting(false);
    }
  }

  if (phase === 'confirm' || submitting) {
    return (
      <div className="return-confirm stack" role="dialog" aria-modal="true">
        <h2>Did the payment go through?</h2>
        <p className="muted">
          Zep Pay cannot read the Phone dialer. Tap what actually happened — we
          never guess.
        </p>
        <div className="amount-display card compact">
          <div className="muted">₹{draft.amount} → {draft.name || draft.vpa}</div>
        </div>
        <button
          type="button"
          className={`btn-primary btn-large${submitting ? ' is-busy' : ''}`}
          disabled={submitting}
          onClick={() => confirm('success-user')}
        >
          {submitting ? 'Saving…' : 'Yes, it succeeded'}
        </button>
        <button
          type="button"
          className="btn-danger btn-large"
          disabled={submitting}
          onClick={() => confirm('failed-user')}
        >
          No, it failed
        </button>
      </div>
    );
  }

  async function copySummary() {
    await copyText(buildPaymentSummary(draft));
  }

  function openPhone() {
    seenAwayRef.current = true;
    window.location.href = telLink;
  }

  return (
    <div className="card stack handoff">
      <div className="handoff-status">
        <span className="pulse-dot" aria-hidden />
        <strong>{phase === 'away' ? 'Complete payment in Phone…' : 'Opening Phone…'}</strong>
      </div>

      <CopyVpaChip vpa={draft.vpa} />

      <div className="step-list">
        <Step done={copied} active label="UPI ID copied to clipboard" />
        <Step
          done={phase === 'away'}
          active={phase !== 'launching'}
          label={`Dialing *99*1*3# for ₹${draft.amount}`}
        />
        <Step active={phase === 'away'} label="Paste ID if asked, enter PIN in Phone" />
      </div>

      <p className="muted small">
        When you return here, we will ask once if the payment succeeded.
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
