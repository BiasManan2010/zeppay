import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration med = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 560);
  static const Curve out = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

class FadeSlidePage<T> extends CustomTransitionPage<T> {
  FadeSlidePage({required super.child, super.key})
    : super(
        transitionDuration: AppMotion.med,
        reverseTransitionDuration: AppMotion.fast,
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.out,
            reverseCurve: Curves.easeInCubic,
          );
          final recede = CurvedAnimation(
            parent: secondary,
            curve: AppMotion.out,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0.86).animate(recede),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 0.98).animate(recede),
                  child: child,
                ),
              ),
            ),
          );
        },
      );
}

GoRoute fadeRoute(String path, Widget Function() page) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        FadeSlidePage(key: state.pageKey, child: page()),
  );
}

GoRoute fadeRouteState(String path, Widget Function(GoRouterState) page) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        FadeSlidePage(key: state.pageKey, child: page(state)),
  );
}

/// Plays a fade + rise once when first shown. Safe across parent rebuilds.
class RiseIn extends StatefulWidget {
  const RiseIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.dy = 0.06,
  });

  final Widget child;
  final Duration delay;
  final double dy;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.med);
    Future<void>.delayed(widget.delay, () {
      if (mounted && !_started) {
        _started = true;
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.out);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.dy),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

class SoftSwitcher extends StatelessWidget {
  const SoftSwitcher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.med,
      switchInCurve: AppMotion.out,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
