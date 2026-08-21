export function AmountEntry({ amount, note, onAmount, onNote, onNext, onBack }) {
  return (
    <div className="stack">
      <label>
        Amount (₹)
        <input
          className="field"
          inputMode="decimal"
          placeholder="0"
          value={amount}
          onChange={(e) => onAmount(e.target.value)}
        />
      </label>
      <label>
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
        Review
      </button>
      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}
