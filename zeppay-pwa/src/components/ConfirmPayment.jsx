export function ConfirmPayment({ draft, rail, onRail, onPay, onBack }) {
  return (
    <div className="stack card">
      <div>
        <div className="muted">Paying</div>
        <strong>{draft.name || draft.vpa}</strong>
        <div className="muted">{draft.vpa}</div>
      </div>
      <div>
        <div className="muted">Amount</div>
        <strong>₹{Number(draft.amount).toFixed(2)}</strong>
      </div>
      {draft.note ? (
        <div>
          <div className="muted">Note</div>
          <div>{draft.note}</div>
        </div>
      ) : null}
      <div className="rail-picker">
        <label>
          <input
            type="radio"
            name="rail"
            checked={rail === 'ussd'}
            onChange={() => onRail('ussd')}
          />
          Offline *99# (tel dial)
        </label>
        <label>
          <input
            type="radio"
            name="rail"
            checked={rail === 'upi'}
            onChange={() => onRail('upi')}
          />
          UPI app handoff
        </label>
      </div>
      <p className="muted small">
        {rail === 'ussd'
          ? 'VPA is copied. Dial *99# in Phone — paste if asked, then enter your PIN there.'
          : 'Opens GPay / PhonePe. Zep Pay cannot confirm success.'}
      </p>
      <button type="button" className="btn-primary" onClick={onPay}>
        {rail === 'ussd' ? 'Dial *99#' : 'Pay via UPI app'}
      </button>
      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}
