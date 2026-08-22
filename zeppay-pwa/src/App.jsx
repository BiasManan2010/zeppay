import { useMemo, useState } from 'react';
import { HomeScreen } from './components/HomeScreen';
import { RecipientEntry } from './components/RecipientEntry';
import { AmountEntry } from './components/AmountEntry';
import { ConfirmPayment } from './components/ConfirmPayment';
import { PaymentHandoff } from './components/PaymentHandoff';
import { History } from './components/History';
import { buildUpiLink, buildUssdTelLink } from './lib/upiLink';
import { loadHistory, loadRecents, logPayment, saveRecent } from './lib/localStore';

const SCREENS = {
  home: 'home',
  recipient: 'recipient',
  amount: 'amount',
  confirm: 'confirm',
  handoff: 'handoff',
  outcome: 'outcome',
  history: 'history',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.home);
  const [vpa, setVpa] = useState('');
  const [name, setName] = useState('');
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [rail, setRail] = useState('ussd');
  const [history, setHistory] = useState(() => loadHistory());
  const recents = useMemo(() => loadRecents(), [history, screen]);

  const draft = { vpa, name, amount, note };
  const upiLink = buildUpiLink(draft);
  const ussdLink = buildUssdTelLink({ vpa, amount });

  const titles = {
    [SCREENS.home]: 'Zep Pay',
    [SCREENS.recipient]: 'Recipient',
    [SCREENS.amount]: 'Amount',
    [SCREENS.confirm]: 'Confirm',
    [SCREENS.handoff]: 'Handoff',
    [SCREENS.outcome]: 'Outcome',
    [SCREENS.history]: 'History',
  };

  function recordPayment(status) {
    saveRecent({ vpa, name: name || vpa });
    logPayment({ vpa, name, amount, note, status, rail });
    setHistory(loadHistory());
  }

  function goHome() {
    setScreen(SCREENS.home);
  }

  async function copyFallback() {
    const text = `Pay ₹${amount} to ${vpa}${note ? ` (${note})` : ''}`;
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      /* ignore */
    }
    finishHandoff('initiated-copy');
    setScreen(SCREENS.home);
  }

  return (
    <div className="app-shell">
      <header className="brand">{titles[screen]}</header>
      {screen === SCREENS.home && (
        <>
          <HomeScreen
            recents={recents}
            onPay={() => setScreen(SCREENS.recipient)}
          />
          <div className="spacer" />
          <button type="button" className="btn-ghost" onClick={() => setScreen(SCREENS.history)}>
            History
          </button>
        </>
      )}
      {screen === SCREENS.recipient && (
        <RecipientEntry
          value={vpa}
          onChange={(v) => {
            setVpa(v);
            navigator.clipboard?.writeText(v).catch(() => {});
          }}
          onNext={() => setScreen(SCREENS.amount)}
          onBack={() => setScreen(SCREENS.home)}
        />
      )}
      {screen === SCREENS.amount && (
        <AmountEntry
          amount={amount}
          note={note}
          onAmount={setAmount}
          onNote={setNote}
          onNext={() => setScreen(SCREENS.confirm)}
          onBack={() => setScreen(SCREENS.recipient)}
        />
      )}
      {screen === SCREENS.confirm && (
        <ConfirmPayment
          draft={draft}
          rail={rail}
          onRail={setRail}
          onPay={() => setScreen(SCREENS.handoff)}
          onBack={() => setScreen(SCREENS.amount)}
        />
      )}
      {screen === SCREENS.handoff && (
        <PaymentHandoff
          link={rail === 'ussd' ? ussdLink : upiLink}
          mode={rail}
          vpa={vpa}
          amount={amount}
          onFallback={copyFallback}
          onDone={() => setScreen(SCREENS.outcome)}
          onReturn={() => setScreen(SCREENS.outcome)}
        />
      )}
      {screen === SCREENS.outcome && (
        <div className="card stack">
          <h2>How did it go?</h2>
          <p>Zep Pay cannot read the dialer — only you know if it landed.</p>
          <button type="button" className="btn-primary" onClick={() => { recordPayment('success-user'); goHome(); }}>
            Payment succeeded
          </button>
          <button type="button" className="btn-ghost" onClick={() => { recordPayment('failed-user'); goHome(); }}>
            Failed or cancelled
          </button>
          <button type="button" className="btn-ghost" onClick={goHome}>
            Home
          </button>
        </div>
      )}
      {screen === SCREENS.history && (
        <>
          <History items={history} />
          <button type="button" className="btn-ghost" onClick={() => setScreen(SCREENS.home)}>
            Back home
          </button>
        </>
      )}
    </div>
  );
}
