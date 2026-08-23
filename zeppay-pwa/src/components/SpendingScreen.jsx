import { formatRupee } from '../lib/amount';

export function SpendingScreen({ summary }) {
  const days = Object.entries(summary.byDay).slice(0, 7);

  return (
    <div className="stack">
      <div className="hero-balance card">
        <div className="muted">Confirmed spending</div>
        <div className="coin-balance">₹{formatRupee(summary.total)}</div>
        <p className="muted small">{summary.count} successful payments on this device</p>
      </div>

      {days.length === 0 ? (
        <p className="muted">No confirmed payments yet.</p>
      ) : (
        <div className="stack">
          {days.map(([day, total]) => (
            <div key={day} className="card row-card">
              <strong>{day}</strong>
              <span className="muted">₹{formatRupee(total)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
