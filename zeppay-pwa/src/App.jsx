import { useMemo, useState } from 'react';
import { HomeScreen } from './components/HomeScreen';
import { RecipientEntry } from './components/RecipientEntry';
import { AmountEntry } from './components/AmountEntry';
import { ConfirmPayment } from './components/ConfirmPayment';
import { PaymentHandoff } from './components/PaymentHandoff';
import { History } from './components/History';
import { buildUpiLink } from './lib/upiLink';
import { loadHistory, loadRecents, logPayment, saveRecent } from './lib/localStore';

const SCREENS = {
  home: 'home',
  recipient: 'recipient',
  amount: 'amount',
  confirm: 'confirm',
  handoff: 'handoff',
  history: 'history',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.home);
  const [vpa, setVpa] = useState('');
  const [name, setName] = useState('');
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [history, setHistory] = useState(() => loadHistory());
  const recents = useMemo(() => loadRecents(), [history, screen]);

  const draft = { vpa, name, amount, note };
  const link = buildUpiLink(draft);

  const titles = {
    [SCREENS.home]: 'Zep Pay',
    [SCREENS.recipient]: 'Recipient',
    [SCREENS.amount]: 'Amount',
    [SCREENS.confirm]: 'Confirm',
    [SCREENS.handoff]: 'Handoff',
    [SCREENS.history]: 'History',
  };

  function finishHandoff(status) {
    saveRecent({ vpa, name: name || vpa });
    logPayment({ vpa, name, amount, note, status });
    setHistory(loadHistory());
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
          onChange={setVpa}
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
          onPay={() => setScreen(SCREENS.handoff)}
          onBack={() => setScreen(SCREENS.amount)}
        />
      )}
      {screen === SCREENS.handoff && (
        <PaymentHandoff
          link={link}
          onFallback={copyFallback}
          onDone={() => finishHandoff('initiated')}
        />
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
