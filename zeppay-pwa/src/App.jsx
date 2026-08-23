import { useCallback, useEffect, useMemo, useState } from 'react';
import { HomeScreen } from './components/HomeScreen';
import { ScanScreen } from './components/ScanScreen';
import { RecipientEntry } from './components/RecipientEntry';
import { AmountEntry } from './components/AmountEntry';
import { ConfirmPayment } from './components/ConfirmPayment';
import { PaymentHandoff } from './components/PaymentHandoff';
import { History } from './components/History';
import { CoinsScreen } from './components/CoinsScreen';
import { ShopScreen } from './components/ShopScreen';
import { RequestsScreen, RequestCompose } from './components/RequestsScreen';
import { SplitScreen } from './components/SplitScreen';
import { ProfileScreen } from './components/ProfileScreen';
import { SpendingScreen } from './components/SpendingScreen';
import { OutcomeScreen } from './components/OutcomeScreen';
import { parseAmount } from './lib/amount';
import { buildBalanceTelLink, buildUssdTelLink } from './lib/upiLink';
import { isValidVpa } from './lib/qrParser';
import {
  addExpense,
  addRequest,
  loadCoinBalance,
  loadCoinLedger,
  loadExpenses,
  loadGroups,
  loadHistory,
  loadProfile,
  loadRecents,
  loadRequests,
  logPayment,
  redeemPartner,
  saveGroup,
  saveProfile,
  saveRecent,
  spendingSummary,
  updateRequest,
} from './lib/localStore';

const SCREENS = {
  home: 'home',
  scan: 'scan',
  recipient: 'recipient',
  amount: 'amount',
  confirm: 'confirm',
  handoff: 'handoff',
  outcome: 'outcome',
  history: 'history',
  coins: 'coins',
  shop: 'shop',
  requests: 'requests',
  requestCompose: 'requestCompose',
  split: 'split',
  profile: 'profile',
  spending: 'spending',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.home);
  const [vpa, setVpa] = useState('');
  const [name, setName] = useState('');
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [history, setHistory] = useState(() => loadHistory());
  const [coinBalance, setCoinBalance] = useState(() => loadCoinBalance());
  const [coinLedger, setCoinLedger] = useState(() => loadCoinLedger());
  const [requests, setRequests] = useState(() => loadRequests());
  const [groups, setGroups] = useState(() => loadGroups());
  const [expenses, setExpenses] = useState(() => loadExpenses());
  const [profile, setProfile] = useState(() => loadProfile());
  const [outcome, setOutcome] = useState(null);
  const [splitPrefill, setSplitPrefill] = useState(null);
  const [lockedAmount, setLockedAmount] = useState(null);

  const recents = useMemo(() => loadRecents(), [history, screen]);
  const parsedAmount = useMemo(() => parseAmount(amount), [amount]);
  const activeAmount = lockedAmount ?? parsedAmount;

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

  const draft = useMemo(
    () => ({
      vpa,
      name,
      amount: activeAmount != null ? String(activeAmount) : amount,
      note,
    }),
    [vpa, name, amount, activeAmount, note],
  );

  const ussdLink = useMemo(() => {
    if (activeAmount == null || !vpa) return '';
    return buildUssdTelLink({ vpa, amount: activeAmount });
  }, [vpa, activeAmount]);

  const titles = {
    [SCREENS.home]: 'Zep Pay',
    [SCREENS.scan]: 'Scan QR',
    [SCREENS.recipient]: 'Pay UPI ID',
    [SCREENS.amount]: 'Enter amount',
    [SCREENS.confirm]: 'Confirm',
    [SCREENS.handoff]: 'Dial *99#',
    [SCREENS.outcome]: 'Payment status',
    [SCREENS.history]: 'History',
    [SCREENS.coins]: 'ZepCoins',
    [SCREENS.shop]: 'Shop',
    [SCREENS.requests]: 'Requests',
    [SCREENS.requestCompose]: 'New request',
    [SCREENS.split]: 'Split bill',
    [SCREENS.profile]: 'Profile',
    [SCREENS.spending]: 'Spending',
  };

  const refreshStore = useCallback(() => {
    setHistory(loadHistory());
    setCoinBalance(loadCoinBalance());
    setCoinLedger(loadCoinLedger());
    setRequests(loadRequests());
    setGroups(loadGroups());
    setExpenses(loadExpenses());
  }, []);

  function resetDraft() {
    setVpa('');
    setName('');
    setAmount('');
    setNote('');
    setLockedAmount(null);
  }

  function applyDraft(parsed) {
    setVpa(parsed.vpa);
    setName(parsed.name || '');
    setNote(parsed.note || '');
    if (parsed.amount && parseAmount(String(parsed.amount))) {
      setAmount(String(parsed.amount));
      setScreen(SCREENS.confirm);
    } else {
      setAmount('');
      setScreen(SCREENS.amount);
    }
  }

  const goHome = useCallback(() => {
    resetDraft();
    setOutcome(null);
    setSplitPrefill(null);
    setScreen(SCREENS.home);
  }, []);

  const recordPayment = useCallback(
    (status) => {
      saveRecent({ vpa, name: name || vpa });
      const row = logPayment({ vpa, name, amount: draft.amount, note, status, rail: 'ussd' });
      refreshStore();
      return row;
    },
    [vpa, name, draft.amount, note, refreshStore],
  );

  const handleConfirmed = useCallback(
    async (status) => {
      const row = recordPayment(status);
      setOutcome(row);
      setScreen(SCREENS.outcome);
    },
    [recordPayment],
  );

  const handlePendingTimeout = useCallback(() => {
    const row = recordPayment('pending');
    setOutcome(row);
    setScreen(SCREENS.outcome);
  }, [recordPayment]);

  const handlePayStart = useCallback((confirmedAmount) => {
    setLockedAmount(confirmedAmount);
    setAmount(String(confirmedAmount));
    setScreen(SCREENS.handoff);
  }, []);

  function openBalance() {
    window.location.href = buildBalanceTelLink();
  }

  function handleBack() {
    if (screen === SCREENS.handoff) return;
    if (screen === SCREENS.confirm) setScreen(SCREENS.amount);
    else if (screen === SCREENS.amount) setScreen(vpa ? SCREENS.recipient : SCREENS.scan);
    else if (screen === SCREENS.recipient || screen === SCREENS.scan) setScreen(SCREENS.home);
    else if (screen === SCREENS.requestCompose) setScreen(SCREENS.requests);
    else if (screen === SCREENS.shop) setScreen(SCREENS.coins);
    else goHome();
  }

  const spending = useMemo(() => spendingSummary(), [history]);

  const expenseRows = useMemo(
    () =>
      expenses.map((e) => {
        const group = groups.find((g) => g.id === e.groupId);
        const members = group?.members?.length || 1;
        return {
          ...e,
          groupName: group?.name || 'Group',
          perPerson: (Number(e.amount) / members).toFixed(2),
        };
      }),
    [expenses, groups],
  );

  return (
    <div className="app-shell">
      <header className="top-bar">
        {screen !== SCREENS.home ? (
          <button type="button" className="icon-btn" aria-label="Back" onClick={handleBack}>
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
            coinBalance={coinBalance}
            onScan={() => setScreen(SCREENS.scan)}
            onPayUpi={() => setScreen(SCREENS.recipient)}
            onBalance={openBalance}
            onHistory={() => setScreen(SCREENS.history)}
            onCoins={() => setScreen(SCREENS.coins)}
            onRequests={() => setScreen(SCREENS.requests)}
            onSplit={() => setScreen(SCREENS.split)}
            onProfile={() => setScreen(SCREENS.profile)}
            onSpending={() => setScreen(SCREENS.spending)}
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
          <ScanScreen onResult={applyDraft} onBack={() => setScreen(SCREENS.home)} />
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
            onNext={(parsed) => {
              setLockedAmount(parsed);
              setAmount(String(parsed));
              setScreen(SCREENS.confirm);
            }}
            onBack={() => setScreen(vpa && !name ? SCREENS.recipient : SCREENS.home)}
          />
        )}

        {screen === SCREENS.confirm && parsedAmount != null && (
          <ConfirmPayment
            draft={draft}
            onPay={handlePayStart}
            onBack={() => setScreen(SCREENS.amount)}
          />
        )}

        {screen === SCREENS.handoff && ussdLink && (
          <PaymentHandoff
            telLink={ussdLink}
            draft={draft}
            onConfirmed={handleConfirmed}
            onPendingTimeout={handlePendingTimeout}
          />
        )}

        {screen === SCREENS.outcome && outcome && (
          <OutcomeScreen
            result={outcome}
            onHome={goHome}
            onSplit={() => {
              setSplitPrefill(outcome);
              setScreen(SCREENS.split);
            }}
          />
        )}

        {screen === SCREENS.history && (
          <>
            <History items={history} />
            <button type="button" className="btn-ghost" onClick={goHome}>
              Back home
            </button>
          </>
        )}

        {screen === SCREENS.coins && (
          <CoinsScreen
            balance={coinBalance}
            ledger={coinLedger}
            onShop={() => setScreen(SCREENS.shop)}
          />
        )}

        {screen === SCREENS.shop && (
          <ShopScreen
            balance={coinBalance}
            onRedeemed={(brand) => {
              const code = redeemPartner(brand);
              refreshStore();
              return code;
            }}
          />
        )}

        {screen === SCREENS.requests && (
          <RequestsScreen
            requests={requests}
            onCreate={() => setScreen(SCREENS.requestCompose)}
            onPay={(r) => {
              setVpa(r.fromVpa);
              setName(r.fromName);
              setAmount(String(r.amount));
              setNote(r.note || '');
              updateRequest(r.id, 'accepted');
              refreshStore();
              setScreen(SCREENS.confirm);
            }}
            onDismiss={(id) => {
              updateRequest(id, 'dismissed');
              refreshStore();
            }}
          />
        )}

        {screen === SCREENS.requestCompose && (
          <RequestCompose
            onSave={(req) => {
              addRequest(req);
              refreshStore();
              setScreen(SCREENS.requests);
            }}
            onCancel={() => setScreen(SCREENS.requests)}
          />
        )}

        {screen === SCREENS.split && (
          <SplitScreen
            groups={groups}
            expenses={expenseRows}
            prefill={splitPrefill}
            onCreateGroup={() => {
              const group = {
                id: `g-${Date.now()}`,
                name: `Trip ${groups.length + 1}`,
                members: ['You', 'Friend A', 'Friend B'],
              };
              saveGroup(group);
              refreshStore();
            }}
            onSplit={({ groupId, title, amount: total }) => {
              const group = groups.find((g) => g.id === groupId);
              const members = group?.members?.length || 1;
              addExpense({
                groupId,
                title,
                amount: total,
                perPersonShare: (total / members).toFixed(2),
              });
              refreshStore();
              if (splitPrefill) {
                setSplitPrefill(null);
                goHome();
              }
            }}
          />
        )}

        {screen === SCREENS.profile && (
          <ProfileScreen
            profile={profile}
            onSave={(next) => {
              saveProfile(next);
              setProfile(next);
            }}
          />
        )}

        {screen === SCREENS.spending && <SpendingScreen summary={spending} />}
      </main>

      {screen === SCREENS.home ? (
        <footer className="offline-badge">Offline *99# only · no UPI app redirect</footer>
      ) : null}
    </div>
  );
}
