import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/app_store.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/otp_screen.dart';
import '../../presentation/screens/home/home_shell.dart';
import '../../presentation/screens/pay/autopay_screen.dart';
import '../../presentation/screens/pay/confirm_screen.dart';
import '../../presentation/screens/pay/connecting_screen.dart';
import '../../presentation/screens/pay/face_confirm_screen.dart';
import '../../presentation/screens/pay/history_screen.dart';
import '../../presentation/screens/pay/pay_friends_screen.dart';
import '../../presentation/screens/pay/requests_screen.dart';
import '../../presentation/screens/pay/scan_screen.dart';
import '../../presentation/screens/split/add_expense_screen.dart';
import '../../presentation/screens/split/group_detail_screen.dart';
import '../../presentation/screens/split/split_home_screen.dart';
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
      final authFlow = loc == '/login' || loc == '/otp' || loc == '/splash';
      if (!authed && !authFlow && loc != '/onboarding') return '/login';
      if (authed && !onboarded && loc != '/onboarding' && loc != '/splash') {
        return '/onboarding';
      }
      if (authed && onboarded && (loc == '/login' || loc == '/otp')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
      GoRoute(path: '/face', builder: (_, __) => const FaceConfirmScreen()),
      GoRoute(path: '/connecting', builder: (_, __) => const ConnectingScreen()),
      GoRoute(path: '/confirm', builder: (_, __) => const ConfirmScreen()),
      GoRoute(path: '/pay-friends', builder: (_, __) => const PayFriendsScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/requests', builder: (_, __) => const RequestsScreen()),
      GoRoute(path: '/autopay', builder: (_, __) => const AutopayScreen()),
      GoRoute(path: '/split', builder: (_, __) => const SplitHomeScreen()),
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
