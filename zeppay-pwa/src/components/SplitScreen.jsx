import { useState } from 'react';
import { formatRupee, parseAmount } from '../lib/amount';

export function SplitScreen({ groups, expenses, prefill, onCreateGroup, onSplit }) {
  const [title, setTitle] = useState(prefill?.note || prefill?.name || '');
  const [amount, setAmount] = useState(prefill?.amount ? String(prefill.amount) : '');
  const [groupId, setGroupId] = useState(groups[0]?.id || '');

  return (
    <div className="stack">
      <button type="button" className="btn-secondary" onClick={onCreateGroup}>
        New group
      </button>

      {groups.length === 0 ? (
        <p className="muted">Create a group to split bills after payments.</p>
      ) : (
        <div className="card stack">
          <label className="field-label">
            Group
            <select
              className="field"
              value={groupId}
              onChange={(e) => setGroupId(e.target.value)}
            >
              {groups.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.name} ({g.members.length} people)
                </option>
              ))}
            </select>
          </label>
          <label className="field-label">
            Title
            <input className="field" value={title} onChange={(e) => setTitle(e.target.value)} />
          </label>
          <label className="field-label">
            Total (₹)
            <input
              className="field"
              inputMode="decimal"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
          </label>
          <button
            type="button"
            className="btn-primary"
            onClick={() => {
              const parsed = parseAmount(amount);
              if (!parsed || !title.trim() || !groupId) return;
              onSplit({ groupId, title: title.trim(), amount: parsed });
              setTitle('');
              setAmount('');
            }}
          >
            Split equally
          </button>
        </div>
      )}

      <section>
        <div className="section-head">
          <strong>Recent splits</strong>
        </div>
        {expenses.length === 0 ? (
          <p className="muted">No split expenses yet.</p>
        ) : (
          <div className="stack">
            {expenses.slice(0, 8).map((e) => (
              <div key={e.id} className="card row-card">
                <strong>{e.title}</strong>
                <span className="muted">
                  ₹{formatRupee(e.amount)} · {e.perPerson} each · {e.groupName}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

export function SplitPrompt({ payment, onSplit, onSkip }) {
  if (!payment) return null;
  return (
    <div className="card stack split-prompt">
      <strong>Split this payment?</strong>
      <p className="muted">
        ₹{formatRupee(payment.amount)} to {payment.name || payment.vpa} succeeded — add to a
        group split?
      </p>
      <button type="button" className="btn-primary" onClick={onSplit}>
        Split bill
      </button>
      <button type="button" className="btn-ghost" onClick={onSkip}>
        Skip
      </button>
    </div>
  );
}
