import { useEffect, useState } from 'react';

export function PaymentHandoff({
  link,
  mode = 'upi',
  vpa,
  amount,
  onFallback,
  onDone,
  onReturn,
}) {
  const [status, setStatus] = useState('launching');
  const [phase, setPhase] = useState(1);

  useEffect(() => {
    let returned = false;
    const onShow = () => {
      if (document.visibilityState !== 'visible' || returned) return;
      returned = true;
      setStatus('returned');
      onReturn?.();
    };
    document.addEventListener('visibilitychange', onShow);

    if (mode === 'ussd' && vpa) {
      navigator.clipboard?.writeText(vpa).catch(() => {});
    }

    window.location.href = link;

    const timer = setTimeout(() => {
      if (!returned && mode === 'upi') {
        setStatus('no-app');
        onFallback();
      }
    }, 1500);

    const phaseTimer = setTimeout(() => setPhase(2), 1200);

    return () => {
      clearTimeout(timer);
      clearTimeout(phaseTimer);
      document.removeEventListener('visibilitychange', onShow);
    };
  }, [link, mode, vpa, onFallback, onReturn]);

  return (
    <div className="card stack handoff">
      {mode === 'ussd' ? (
        <>
          <p className="handoff-phase">
            {phase === 1
              ? `Step 1: Dialing *99# — amount ₹${amount}`
              : 'Step 2: Paste VPA if asked (copied), then enter your PIN in Phone.'}
          </p>
          <p className="handoff-note">
            iOS offline-rail support has a lower ceiling than Android — the OS owns
            the whole USSD session with no return-path API.
          </p>
        </>
      ) : (
        <p>{status === 'launching' ? 'Opening your UPI app…' : 'Complete payment in your UPI app.'}</p>
      )}
      {status === 'returned' && (
        <p>Welcome back — tell us how the payment went on the next screen.</p>
      )}
      {status === 'no-app' && mode === 'upi' && (
        <>
          <p>No UPI app opened. Install GPay, PhonePe, or BHIM, or copy the payment details.</p>
          <button type="button" className="btn-ghost" onClick={onFallback}>
            Copy payment details
          </button>
        </>
      )}
    </div>
  );
}
