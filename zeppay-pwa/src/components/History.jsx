import { formatRupee } from '../lib/amount';

const STATUS_LABEL = {
  'success-user': 'Succeeded',
  success: 'Succeeded',
  'failed-user': 'Failed',
  failed: 'Failed',
  pending: 'Pending',
};

export function History({ items }) {
  if (!items.length) {
    return <p className="muted">No payments yet. Attempts are stored on this device only.</p>;
  }
  return (
    <div className="stack">
      {items.map((item) => (
        <div key={item.id || item.at + item.vpa} className="card row-card">
          <strong>
            ₹{formatRupee(item.amount)} → {item.name || item.vpa}
          </strong>
          <span className="muted">
            {STATUS_LABEL[item.status] || item.status} · {new Date(item.at).toLocaleString()}
          </span>
          {item.note ? <span className="muted small">{item.note}</span> : null}
        </div>
      ))}
    </div>
  );
}
