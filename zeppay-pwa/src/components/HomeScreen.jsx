export function HomeScreen({ onPay, recents }) {
  return (
    <div className="stack">
      <p className="muted">Prepare a payment, then open your UPI app. Zep Pay never collects a PIN.</p>
      <button type="button" className="btn-primary" onClick={onPay}>
        Pay
      </button>
      {recents.length > 0 && (
        <div className="card">
          <strong>Recent</strong>
          <ul className="stack" style={{ marginTop: 12, paddingLeft: 18 }}>
            {recents.map((r) => (
              <li key={r.vpa}>
                {r.name || r.vpa}
                <div className="muted">{r.vpa}</div>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
