import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/app_store.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/otp_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/home/home_shell.dart';
import '../../presentation/screens/pay/amount_screen.dart';
import '../../presentation/screens/pay/autopay_screen.dart';
import '../../presentation/screens/pay/confirm_screen.dart';
import '../../presentation/screens/pay/connecting_screen.dart';
import '../../presentation/screens/pay/face_confirm_screen.dart';
import '../../presentation/screens/pay/history_screen.dart';
import '../../presentation/screens/pay/money_pages.dart';
import '../../presentation/screens/pay/extra_pages.dart';
import '../../presentation/screens/pay/outcome_screen.dart';
import '../../presentation/screens/pay/receive_screen.dart';
import '../../presentation/screens/pay/requests_screen.dart';
import '../../presentation/screens/pay/scan_screen.dart';
import '../../presentation/screens/split/add_expense_screen.dart';
import '../../presentation/screens/split/group_detail_screen.dart';
import '../../presentation/screens/split/split_home_screen.dart';
import '../../presentation/screens/split/split_pages.dart';
import '../../presentation/screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(appStoreProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final app = ref.read(appStoreProvider);
      final loc = state.matchedLocation;
      final authed = app.sessionPhone != null;
      final onboarded = app.profile?.onboarded == true;
      final authFlow =
          loc == '/login' ||
          loc == '/otp' ||
          loc == '/splash' ||
          loc == '/welcome' ||
          loc == '/verify-setup';
      if (!authed && !authFlow && loc != '/onboarding') return '/login';
      if (authed && !onboarded && loc != '/onboarding' && loc != '/splash') {
        return '/onboarding';
      }
      if (authed &&
          onboarded &&
          (loc == '/login' || loc == '/otp' || loc == '/welcome')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      GoRoute(
        path: '/verify-setup',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
      GoRoute(path: '/face', builder: (_, __) => const FaceConfirmScreen()),
      GoRoute(
        path: '/connecting',
        builder: (_, __) => const ConnectingScreen(),
      ),
      GoRoute(path: '/outcome', builder: (_, __) => const OutcomeScreen()),
      GoRoute(path: '/confirm', builder: (_, __) => const ConfirmScreen()),
      GoRoute(path: '/failed', builder: (_, __) => const FailedScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingScreen()),
      GoRoute(path: '/pay/amount', builder: (_, __) => const AmountScreen()),
      GoRoute(path: '/receive', builder: (_, __) => const ReceiveScreen()),
      GoRoute(path: '/pay/mobile', builder: (_, __) => const PayMobileScreen()),
      GoRoute(path: '/pay/upi', builder: (_, __) => const PayUpiScreen()),
      GoRoute(
        path: '/pay/contacts',
        builder: (_, __) => const PayContactsScreen(),
      ),
      GoRoute(path: '/pay/bank', builder: (_, __) => const PayBankScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/requests', builder: (_, __) => const RequestsScreen()),
      GoRoute(path: '/autopay', builder: (_, __) => const AutopayScreen()),
      GoRoute(path: '/balance', builder: (_, __) => const BalanceScreen()),
      GoRoute(path: '/offline', builder: (_, __) => const OfflineRailsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/split', builder: (_, __) => const SplitHomeScreen()),
      GoRoute(path: '/split-bill', builder: (_, __) => const SplitBillScreen()),
      GoRoute(path: '/settle', builder: (_, __) => const SettleHubScreen()),
      GoRoute(
        path: '/split-activity',
        builder: (_, __) => const SplitActivityScreen(),
      ),
      GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/categories', builder: (_, __) => const CategorySpendScreen()),
      GoRoute(
        path: '/history/:id',
        builder: (_, s) => TxDetailScreen(txId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/split/:id/expense/:eid',
        builder: (_, s) => ExpenseDetailScreen(
          groupId: s.pathParameters['id']!,
          expenseId: s.pathParameters['eid']!,
        ),
      ),
      GoRoute(
        path: '/split/:id',
        builder: (_, s) => GroupDetailScreen(groupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/split/:id/add',
        builder: (_, s) => AddExpenseScreen(groupId: s.pathParameters['id']!),
      ),
    ],
  );
});
