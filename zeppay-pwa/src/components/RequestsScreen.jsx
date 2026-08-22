import { useState } from 'react';
import { formatRupee } from '../lib/amount';

export function RequestsScreen({ requests, onCreate, onPay, onDismiss }) {
  const [tab, setTab] = useState('pending');
  const pending = requests.filter((r) => r.status === 'pending');
  const done = requests.filter((r) => r.status !== 'pending');
  const shown = tab === 'pending' ? pending : done;

  return (
    <div className="stack">
      <button type="button" className="btn-primary" onClick={onCreate}>
        Request money
      </button>

      <div className="tab-row">
        <button
          type="button"
          className={`tab-chip${tab === 'pending' ? ' active' : ''}`}
          onClick={() => setTab('pending')}
        >
          Pending {pending.length ? `(${pending.length})` : ''}
        </button>
        <button
          type="button"
          className={`tab-chip${tab === 'done' ? ' active' : ''}`}
          onClick={() => setTab('done')}
        >
          Completed
        </button>
      </div>

      {shown.length === 0 ? (
        <p className="muted">No requests here.</p>
      ) : (
        <div className="stack">
          {shown.map((r) => (
            <div key={r.id} className="card row-card">
              <strong>
                ₹{formatRupee(r.amount)} from {r.fromName}
              </strong>
              <span className="muted">{r.note || r.fromVpa}</span>
              <span className="muted small">{new Date(r.createdAt).toLocaleString()}</span>
              {r.status === 'pending' ? (
                <div className="row-actions">
                  <button type="button" className="btn-primary" onClick={() => onPay(r)}>
                    Pay
                  </button>
                  <button type="button" className="btn-ghost" onClick={() => onDismiss(r.id)}>
                    Dismiss
                  </button>
                </div>
              ) : (
                <span className="pill muted-pill">{r.status}</span>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export function RequestCompose({ onSave, onCancel }) {
  const [fromName, setFromName] = useState('');
  const [fromVpa, setFromVpa] = useState('');
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');

  return (
    <div className="stack">
      <label className="field-label">
        Their name
        <input className="field" value={fromName} onChange={(e) => setFromName(e.target.value)} />
      </label>
      <label className="field-label">
        Their UPI ID
        <input className="field" value={fromVpa} onChange={(e) => setFromVpa(e.target.value)} />
      </label>
      <label className="field-label">
        Amount (₹)
        <input
          className="field"
          inputMode="decimal"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />
      </label>
      <label className="field-label">
        Note
        <input className="field" value={note} onChange={(e) => setNote(e.target.value)} />
      </label>
      <button
        type="button"
        className="btn-primary"
        onClick={() =>
          onSave({ fromName: fromName.trim(), fromVpa: fromVpa.trim(), amount, note })
        }
      >
        Save request
      </button>
      <button type="button" className="btn-ghost" onClick={onCancel}>
        Cancel
      </button>
    </div>
  );
}
