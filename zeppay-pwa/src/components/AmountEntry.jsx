import { useMemo } from 'react';
import { parseAmount, sanitizeAmountInput } from '../lib/amount';

export function AmountEntry({ amount, note, payee, onAmount, onNote, onNext, onBack }) {
  const parsed = useMemo(() => parseAmount(amount), [amount]);
  const canProceed = parsed != null;

  function handleAmountChange(e) {
    onAmount(sanitizeAmountInput(e.target.value));
  }

  function handleNext() {
    if (!canProceed) return;
    onNext(parsed);
  }

  return (
    <div className="stack">
      <div className="card payee-pill">
        <div className="muted">To</div>
        <strong>{payee}</strong>
      </div>

      <label className="field-label" htmlFor="amount-input">
        Amount (₹)
        <input
          id="amount-input"
          className="field field-amount"
          type="text"
          inputMode="decimal"
          autoComplete="off"
          autoCorrect="off"
          spellCheck={false}
          enterKeyHint="next"
          placeholder="0"
          value={amount}
          onChange={handleAmountChange}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && canProceed) {
              e.preventDefault();
              handleNext();
            }
          }}
        />
      </label>

      <label className="field-label" htmlFor="note-input">
        Note (optional)
        <input
          id="note-input"
          className="field"
          type="text"
          placeholder="Dinner, rent…"
          value={note}
          onChange={(e) => onNote(e.target.value)}
        />
      </label>

      <button
        type="button"
        className="btn-primary"
        onClick={handleNext}
        disabled={!canProceed}
        aria-disabled={!canProceed}
      >
        Review payment
      </button>
      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}
