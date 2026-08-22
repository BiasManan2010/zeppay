export function HomeScreen({ onScan, onPayUpi, onBalance, onHistory, recents, onRecent }) {
  return (
    <div className="home">
      <section className="hero-card card">
        <p className="eyebrow">Offline UPI</p>
        <h1 className="hero-title">Pay without data</h1>
        <p className="muted">
          Scan a QR, copy the UPI ID, then complete payment in Phone via *99#.
          Zep Pay never opens GPay or PhonePe.
        </p>
      </section>

      <div className="action-grid">
        <button type="button" className="action-tile action-tile-primary" onClick={onScan}>
          <span className="action-icon" aria-hidden>
            ▣
          </span>
          <span className="action-label">Scan QR</span>
          <span className="action-hint">Merchant &amp; person codes</span>
        </button>
        <button type="button" className="action-tile" onClick={onPayUpi}>
          <span className="action-icon" aria-hidden>
            @
          </span>
          <span className="action-label">Pay UPI ID</span>
          <span className="action-hint">Type or paste handle</span>
        </button>
        <button type="button" className="action-tile" onClick={onBalance}>
          <span className="action-icon" aria-hidden>
            ₹
          </span>
          <span className="action-label">Balance</span>
          <span className="action-hint">Dial *99*3#</span>
        </button>
        <button type="button" className="action-tile" onClick={onHistory}>
          <span className="action-icon" aria-hidden>
            ↺
          </span>
          <span className="action-label">History</span>
          <span className="action-hint">This device only</span>
        </button>
      </div>

      {recents.length > 0 ? (
        <section className="card recents">
          <div className="section-head">
            <strong>Recent</strong>
            <span className="muted">Tap to pay again</span>
          </div>
          <ul className="recent-list">
            {recents.map((r) => (
              <li key={r.vpa}>
                <button type="button" className="recent-row" onClick={() => onRecent(r)}>
                  <span className="avatar">{initials(r.name || r.vpa)}</span>
                  <span className="recent-meta">
                    <span className="recent-name">{r.name || r.vpa}</span>
                    <span className="recent-vpa">{r.vpa}</span>
                  </span>
                  <span className="chevron" aria-hidden>
                    ›
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}

function initials(label) {
  const parts = label.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  if (parts.length === 1 && parts[0].includes('@')) {
    return parts[0].split('@')[0].slice(0, 2).toUpperCase();
  }
  return (parts[0] || 'Z').slice(0, 2).toUpperCase();
}
