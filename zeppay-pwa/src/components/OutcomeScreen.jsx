import { formatRupee } from '../lib/amount';

const STATUS_LABEL = {
  'success-user': 'Succeeded',
  success: 'Succeeded',
  'failed-user': 'Failed',
  failed: 'Failed',
  pending: 'Pending',
};

export function OutcomeScreen({ result, onHome, onSplit }) {
  const ok = result.status === 'success-user' || result.status === 'success';

  return (
    <div className="stack outcome">
      <div className={`card outcome-card ${ok ? 'ok' : 'bad'}`}>
        <h2>{ok ? 'Payment recorded' : 'Payment not completed'}</h2>
        <p className="muted">
          {STATUS_LABEL[result.status] || result.status} · ₹{formatRupee(result.amount)} →{' '}
          {result.name || result.vpa}
        </p>
        {result.status === 'pending' ? (
          <p className="muted small">
            Marked pending — you did not return within the dial window.
          </p>
        ) : null}
      </div>

      {ok ? (
        <button type="button" className="btn-secondary" onClick={onSplit}>
          Split this bill
        </button>
      ) : null}
      <button type="button" className="btn-primary" onClick={onHome}>
        Back home
      </button>
    </div>
  );
}
