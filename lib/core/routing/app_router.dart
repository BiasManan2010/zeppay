import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/app_motion.dart';
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
          (loc == '/login' ||
              loc == '/otp' ||
              loc == '/welcome' ||
              loc == '/onboarding')) {
        return '/home';
      }
      return null;
    },
    routes: [
      fadeRoute('/splash', () => const SplashScreen()),
      fadeRoute('/welcome', () => const WelcomeScreen()),
      fadeRoute('/login', () => const LoginScreen()),
      fadeRoute('/otp', () => const OtpScreen()),
      fadeRoute('/verify-setup', () => const SettingsScreen()),
      fadeRoute('/onboarding', () => const OnboardingScreen()),
      fadeRoute('/home', () => const HomeShell()),
      fadeRoute('/scan', () => const ScanScreen()),
      fadeRoute('/face', () => const FaceConfirmScreen()),
      fadeRoute('/connecting', () => const ConnectingScreen()),
      fadeRoute('/outcome', () => const OutcomeScreen()),
      fadeRoute('/confirm', () => const ConfirmScreen()),
      fadeRoute('/failed', () => const FailedScreen()),
      fadeRoute('/pending', () => const PendingScreen()),
      fadeRoute('/pay/amount', () => const AmountScreen()),
      fadeRoute('/receive', () => const ReceiveScreen()),
      fadeRoute('/pay/mobile', () => const PayMobileScreen()),
      fadeRoute('/pay/upi', () => const PayUpiScreen()),
      fadeRoute('/pay/contacts', () => const PayContactsScreen()),
      fadeRoute('/pay/bank', () => const PayBankScreen()),
      fadeRoute('/history', () => const HistoryScreen()),
      fadeRoute('/requests', () => const RequestsScreen()),
      fadeRoute('/autopay', () => const AutopayScreen()),
      fadeRoute('/balance', () => const BalanceScreen()),
      fadeRoute('/offline', () => const OfflineRailsScreen()),
      fadeRoute('/settings', () => const SettingsScreen()),
      fadeRoute('/analytics', () => const AnalyticsScreen()),
      fadeRoute('/inbox', () => const InboxScreen()),
      fadeRoute('/split', () => const SplitHomeScreen()),
      fadeRoute('/split-bill', () => const SplitBillScreen()),
      fadeRoute('/settle', () => const SettleHubScreen()),
      fadeRoute('/split-activity', () => const SplitActivityScreen()),
      fadeRoute('/help', () => const HelpScreen()),
      fadeRoute('/search', () => const SearchScreen()),
      fadeRoute('/categories', () => const CategorySpendScreen()),
      fadeRouteState(
        '/history/:id',
        (s) => TxDetailScreen(txId: s.pathParameters['id']!),
      ),
      fadeRouteState(
        '/split/:id/expense/:eid',
        (s) => ExpenseDetailScreen(
          groupId: s.pathParameters['id']!,
          expenseId: s.pathParameters['eid']!,
        ),
      ),
      fadeRouteState(
        '/split/:id',
        (s) => GroupDetailScreen(groupId: s.pathParameters['id']!),
      ),
      fadeRouteState(
        '/split/:id/add',
        (s) => AddExpenseScreen(groupId: s.pathParameters['id']!),
      ),
    ],
  );
});
