export function History({ items }) {
  if (!items.length) {
    return <p className="muted">No payments yet. Attempts are stored on this device only.</p>;
  }
  return (
    <div className="stack">
      {items.map((item) => (
        <div key={item.at + item.vpa} className="card">
          <strong>₹{Number(item.amount).toFixed(2)} → {item.name || item.vpa}</strong>
          <div className="muted">{item.status} · {new Date(item.at).toLocaleString()}</div>
        </div>
      ))}
    </div>
  );
}
