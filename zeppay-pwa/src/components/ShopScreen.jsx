import { useState } from 'react';
import { DEMO_BADGE, PARTNER_BRANDS, PARTNER_CATEGORIES } from '../lib/partners';

export function ShopScreen({ balance, onRedeemed }) {
  const [tab, setTab] = useState('ott');
  const [message, setMessage] = useState('');
  const brands = PARTNER_BRANDS.filter((b) => b.category === tab);

  function redeem(brand) {
    if (balance < brand.coinsRequired) {
      setMessage(`Need ${brand.coinsRequired} coins — you have ${balance}.`);
      return;
    }
    const code = onRedeemed(brand);
    if (code) {
      setMessage(`Redeemed! Demo code: ${code.voucherCode}`);
    }
  }

  return (
    <div className="stack">
      <div className="card">
        <div className="muted">Spend ZepCoins</div>
        <strong>{balance} coins available</strong>
        <p className="muted small">{DEMO_BADGE} — not real partner deals.</p>
      </div>

      <div className="tab-row">
        {PARTNER_CATEGORIES.map((c) => (
          <button
            key={c.id}
            type="button"
            className={`tab-chip${tab === c.id ? ' active' : ''}`}
            onClick={() => setTab(c.id)}
          >
            {c.label}
          </button>
        ))}
      </div>

      {message ? <p className="banner-note">{message}</p> : null}

      <div className="stack">
        {brands.map((brand) => (
          <div key={brand.id} className="card offer-card">
            <div className="offer-head">
              <strong>{brand.name}</strong>
              <span className="pill">{brand.coinsRequired} coins</span>
            </div>
            <p className="muted">{brand.discountLabel}</p>
            <button type="button" className="btn-secondary" onClick={() => redeem(brand)}>
              Redeem
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
