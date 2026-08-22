import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/app_motion.dart';
import '../../core/platform.dart';
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
import '../../presentation/screens/coins/coins_screen.dart';
import '../../presentation/screens/shop/shop_screen.dart';
import '../../presentation/screens/pay/bills_recharge_screen.dart';
import '../../presentation/screens/pay/saved_contacts_screen.dart';
import '../../presentation/screens/pay/payment_services_hub.dart';
import '../../presentation/screens/pay/money_pages.dart';
import '../../presentation/screens/pay/extra_pages.dart';
import '../../presentation/screens/pay/outcome_screen.dart';
import '../../presentation/screens/pay/receive_screen.dart';
import '../../presentation/screens/pay/requests_screen.dart';
import '../../presentation/screens/pay/request_money_screen.dart';
import '../../presentation/screens/pay/scan_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/split/add_expense_screen.dart';
import '../../presentation/screens/split/group_detail_screen.dart';
import '../../presentation/screens/split/split_home_screen.dart';
import '../../presentation/screens/split/split_pages.dart';
import '../../presentation/screens/nfc/merchant_mode_screen.dart';
import '../../presentation/screens/nfc/zep_card_profile_screen.dart';
import '../../presentation/screens/nfc/zep_card_setup_screen.dart';

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
          loc == '/verify-setup' ||
          loc.startsWith('/nfc/profile');
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
      if (isWebApp) {
        if (loc == '/offline') return '/help';
        if (loc == '/pay/contacts') return '/pay/upi';
        if (loc == '/face') return '/connecting';
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
      fadeRoute('/pay/saved-contacts', () => const SavedContactsScreen()),
      fadeRoute('/pay/self', () => const SelfTransferScreen()),
      fadeRoute('/pay/donate', () => const DonateScreen()),
      fadeRoute('/bills-recharge', () => const BillsRechargeHubScreen()),
      fadeRoute('/request-money', () => const RequestMoneyScreen()),
      fadeRouteState(
        '/bills-recharge/:categoryId',
        (s) => BillRechargeFormScreen(
          categoryId: s.pathParameters['categoryId']!,
        ),
      ),
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
      fadeRoute('/coins', () => const CoinsScreen()),
      fadeRoute('/shop', () => const ShopScreen()),
      fadeRoute('/payment-hub', () => const PaymentServicesHubScreen()),
      fadeRoute('/zep-card-setup', () => const ZepCardSetupScreen()),
      fadeRoute('/merchant-mode', () => const MerchantModeScreen()),
      fadeRouteState(
        '/nfc/profile',
        (s) => ZepCardProfileScreen(
          vpa: Uri.decodeComponent(s.uri.queryParameters['vpa'] ?? ''),
          name: Uri.decodeComponent(s.uri.queryParameters['name'] ?? ''),
          fromNfcTap: true,
        ),
      ),
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
