import { formatRupee } from '../lib/amount';
import { loadRedemptions } from '../lib/localStore';

export function CoinsScreen({ balance, ledger, onShop }) {
  const redemptions = loadRedemptions();
  return (
    <div className="stack">
      <div className="hero-balance card">
        <div className="muted">Your balance</div>
        <div className="coin-balance">{balance}</div>
        <div className="coin-label">ZepCoins</div>
        <p className="muted small">Earn 1 coin for every ₹10 you confirm as paid.</p>
      </div>

      <button type="button" className="btn-primary" onClick={onShop}>
        Redeem in Shop
      </button>

      <section className="card">
        <strong>Ways to earn</strong>
        <ul className="plain-list muted">
          <li>Confirm offline *99# payments</li>
          <li>1 coin per ₹10 spent (honest confirmations only)</li>
        </ul>
      </section>

      <section>
        <div className="section-head">
          <strong>Ledger</strong>
        </div>
        {ledger.length === 0 ? (
          <p className="muted">No coins yet — complete a payment first.</p>
        ) : (
          <div className="stack">
            {ledger.map((row) => (
              <div key={row.paymentId} className="card row-card">
                <strong>+{row.coinsEarned} coins</strong>
                <span className="muted">
                  ₹{formatRupee(row.amount)} · {new Date(row.at).toLocaleString()}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>

      {redemptions.length > 0 ? (
        <section>
          <div className="section-head">
            <strong>Redemptions</strong>
          </div>
          <div className="stack">
            {redemptions.slice(0, 5).map((r) => (
              <div key={r.id} className="card row-card">
                <strong>{r.brandName}</strong>
                <span className="muted mono">{r.voucherCode}</span>
              </div>
            ))}
          </div>
        </section>
      ) : null}
    </div>
  );
}
