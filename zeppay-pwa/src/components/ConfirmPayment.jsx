export function ConfirmPayment({ draft, onPay, onBack }) {
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
      <button type="button" className="btn-primary" onClick={onPay}>
        Pay via UPI app
      </button>
      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}
