export function RecipientEntry({ value, onChange, onNext, onBack }) {
  return (
    <div className="stack">
      <label>
        UPI ID
        <input
          className="field"
          placeholder="name@upi"
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
      </label>
      <button type="button" className="btn-primary" onClick={onNext} disabled={!value.trim()}>
        Continue
      </button>
      <button type="button" className="btn-ghost" onClick={onBack}>
        Back
      </button>
    </div>
  );
}
