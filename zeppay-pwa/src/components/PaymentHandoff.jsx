import { useEffect, useState } from 'react';

export function PaymentHandoff({ link, onFallback, onDone }) {
  const [status, setStatus] = useState('launching');

  useEffect(() => {
    let hidden = false;
    const onHide = () => {
      hidden = true;
      setStatus('handed-off');
      onDone();
    };
    document.addEventListener('visibilitychange', onHide);
    window.location.href = link;
    const timer = setTimeout(() => {
      if (!hidden) {
        setStatus('no-app');
        onFallback();
      }
    }, 1500);
    return () => {
      clearTimeout(timer);
      document.removeEventListener('visibilitychange', onHide);
    };
  }, [link, onFallback, onDone]);

  return (
    <div className="card stack">
      {status === 'launching' && <p>Opening your UPI app…</p>}
      {status === 'handed-off' && (
        <p>Payment initiated in your UPI app. Complete it there — Zep Pay cannot confirm success.</p>
      )}
      {status === 'no-app' && (
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
