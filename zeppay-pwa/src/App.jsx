import { useEffect, useMemo, useState } from 'react';
import { HomeScreen } from './components/HomeScreen';
import { ScanScreen } from './components/ScanScreen';
import { RecipientEntry } from './components/RecipientEntry';
import { AmountEntry } from './components/AmountEntry';
import { ConfirmPayment } from './components/ConfirmPayment';
import { PaymentHandoff } from './components/PaymentHandoff';
import { History } from './components/History';
import { buildBalanceTelLink, buildUssdTelLink } from './lib/upiLink';
import { isValidVpa } from './lib/qrParser';
import { loadHistory, loadRecents, logPayment, saveRecent } from './lib/localStore';

const SCREENS = {
  home: 'home',
  scan: 'scan',
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
  const [history, setHistory] = useState(() => loadHistory());
  const recents = useMemo(() => loadRecents(), [history, screen]);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const vpaParam = params.get('vpa')?.trim() || '';
    if (!isValidVpa(vpaParam)) return;
    setVpa(vpaParam);
    setName(params.get('name')?.trim() || '');
    setNote('');
    setAmount('');
    setScreen(SCREENS.amount);
  }, []);

  const draft = { vpa, name, amount, note };
  const ussdLink = buildUssdTelLink({ vpa, amount });

  const titles = {
    [SCREENS.home]: 'Zep Pay',
    [SCREENS.scan]: 'Scan QR',
    [SCREENS.recipient]: 'Pay UPI ID',
    [SCREENS.amount]: 'Enter amount',
    [SCREENS.confirm]: 'Confirm',
    [SCREENS.handoff]: 'Dial *99#',
    [SCREENS.outcome]: 'Payment status',
    [SCREENS.history]: 'History',
  };

  function resetDraft() {
    setVpa('');
    setName('');
    setAmount('');
    setNote('');
  }

  function applyDraft(parsed) {
    setVpa(parsed.vpa);
    setName(parsed.name || '');
    setNote(parsed.note || '');
    if (parsed.amount && Number(parsed.amount) > 0) {
      setAmount(String(parsed.amount));
      setScreen(SCREENS.confirm);
    } else {
      setAmount('');
      setScreen(SCREENS.amount);
    }
  }

  function recordPayment(status) {
    saveRecent({ vpa, name: name || vpa });
    logPayment({ vpa, name, amount, note, status, rail: 'ussd' });
    setHistory(loadHistory());
  }

  function goHome() {
    resetDraft();
    setScreen(SCREENS.home);
  }

  function openBalance() {
    window.location.href = buildBalanceTelLink();
  }

  return (
    <div className="app-shell">
      <header className="top-bar">
        {screen !== SCREENS.home ? (
          <button
            type="button"
            className="icon-btn"
            aria-label="Back"
            onClick={() => {
              if (screen === SCREENS.handoff) setScreen(SCREENS.confirm);
              else if (screen === SCREENS.confirm) setScreen(SCREENS.amount);
              else if (screen === SCREENS.amount) setScreen(vpa ? SCREENS.recipient : SCREENS.scan);
              else if (screen === SCREENS.recipient || screen === SCREENS.scan) setScreen(SCREENS.home);
              else if (screen === SCREENS.history || screen === SCREENS.outcome) setScreen(SCREENS.home);
              else setScreen(SCREENS.home);
            }}
          >
            ‹
          </button>
        ) : (
          <span className="icon-btn spacer-btn" />
        )}
        <div className="brand">{titles[screen]}</div>
        <span className="icon-btn spacer-btn" />
      </header>

      <main className="main">
        {screen === SCREENS.home && (
          <HomeScreen
            recents={recents}
            onScan={() => setScreen(SCREENS.scan)}
            onPayUpi={() => setScreen(SCREENS.recipient)}
            onBalance={openBalance}
            onHistory={() => setScreen(SCREENS.history)}
            onRecent={(r) => {
              setVpa(r.vpa);
              setName(r.name || '');
              setAmount('');
              setNote('');
              setScreen(SCREENS.amount);
            }}
          />
        )}

        {screen === SCREENS.scan && (
          <ScanScreen
            onResult={applyDraft}
            onBack={() => setScreen(SCREENS.home)}
          />
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
            payee={name || vpa}
            onAmount={setAmount}
            onNote={setNote}
            onNext={() => setScreen(SCREENS.confirm)}
            onBack={() =>
              setScreen(vpa && !name ? SCREENS.recipient : SCREENS.home)
            }
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
            telLink={ussdLink}
            draft={draft}
            onReturn={() => setScreen(SCREENS.outcome)}
          />
        )}

        {screen === SCREENS.outcome && (
          <div className="card stack outcome">
            <h2>How did *99# go?</h2>
            <p className="muted">
              Zep Pay cannot read the Phone dialer. Log what you saw so your
              history stays honest.
            </p>
            <button
              type="button"
              className="btn-primary"
              onClick={() => {
                recordPayment('success-user');
                goHome();
              }}
            >
              Payment succeeded
            </button>
            <button
              type="button"
              className="btn-ghost"
              onClick={() => {
                recordPayment('failed-user');
                goHome();
              }}
            >
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
      </main>

      {screen === SCREENS.home ? (
        <footer className="offline-badge">Offline *99# only · no UPI app redirect</footer>
      ) : null}
    </div>
  );
}
