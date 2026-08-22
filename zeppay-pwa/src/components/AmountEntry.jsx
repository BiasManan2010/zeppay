export function AmountEntry({ amount, note, payee, onAmount, onNote, onNext, onBack }) {
  return (
    <div className="stack">
      <div className="card payee-pill">
        <div className="muted">To</div>
        <strong>{payee}</strong>
      </div>

      <label className="field-label">
        Amount (₹)
        <input
          className="field field-amount"
          inputMode="decimal"
          placeholder="0"
          value={amount}
          onChange={(e) => onAmount(e.target.value)}
        />
      </label>

      <label className="field-label">
        Note (optional)
        <input
          className="field"
          placeholder="Dinner, rent…"
          value={note}
          onChange={(e) => onNote(e.target.value)}
        />
      </label>

      <button
        type="button"
        className="btn-primary"
        onClick={onNext}
        disabled={!amount || Number(amount) <= 0}
      >
        Review payment
      </button>
      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}
