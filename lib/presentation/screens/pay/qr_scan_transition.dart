import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cyan used only for scan lock / shatter (Paytm-like, not a screen wash).
const Color kScanCyan = Color(0xFF22D3EE);
const Color kScanCyanSoft = Color(0xFF00D9FF);

class ScanIdleFrame extends StatelessWidget {
  const ScanIdleFrame({super.key, this.size = 268});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IdleFramePainter(frameSize: size),
      child: const SizedBox.expand(),
    );
  }
}

class _IdleFramePainter extends CustomPainter {
  _IdleFramePainter({required this.frameSize});
  final double frameSize;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );
    final r = RRect.fromRectAndRadius(hole, const Radius.circular(22));
    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(r)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = const Color(0x99000000));

    const l = 28.0;
    final p = Paint()
      ..color = kScanCyanSoft
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void corner(Offset o, double sx, double sy) {
      canvas.drawLine(o, o.translate(sx * l, 0), p);
      canvas.drawLine(o, o.translate(0, sy * l), p);
    }

    corner(hole.topLeft, 1, 1);
    corner(hole.topRight, -1, 1);
    corner(hole.bottomLeft, 1, -1);
    corner(hole.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _IdleFramePainter old) =>
      old.frameSize != frameSize;
}

class _TileSpec {
  _TileSpec({
    required this.nx,
    required this.ny,
    required this.w,
    required this.h,
    required this.delay,
  });
  final double nx;
  final double ny;
  final double w;
  final double h;
  final double delay;
}

/// Lock-on glow → mosaic shatter → whiteout → fade out. Then [onComplete].
///
/// [onReveal] fires when the screen is fully white so the payment screen can
/// mount underneath before the white overlay fades away.
class QrScanTransition extends StatefulWidget {
  const QrScanTransition({
    super.key,
    required this.onComplete,
    this.onReveal,
    this.brand = 'Zep Pay',
    this.reducedMotion = false,
    this.frameSize = 284,
  });

  final VoidCallback onComplete;
  final VoidCallback? onReveal;
  final String brand;
  final bool reducedMotion;
  final double frameSize;

  @override
  State<QrScanTransition> createState() => _QrScanTransitionState();
}

class _QrScanTransitionState extends State<QrScanTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_TileSpec> _tiles;
  var _done = false;
  var _revealed = false;

  static const _lockEnd = 0.15;
  static const _shatterEnd = 0.74;
  static const _holdEnd = 0.84;
  static const _tileCount = 45;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(7);
    _tiles = List.generate(_tileCount, (_) {
      final nx = 0.06 + rng.nextDouble() * 0.88;
      final ny = 0.06 + rng.nextDouble() * 0.88;
      final dx = nx - 0.5;
      final dy = ny - 0.5;
      final dist = math.sqrt(dx * dx + dy * dy);
      return _TileSpec(
        nx: nx,
        ny: ny,
        w: 20 + rng.nextDouble() * 70,
        h: 20 + rng.nextDouble() * 70,
        delay: _lockEnd + dist * 0.42 + rng.nextDouble() * 0.06,
      );
    });
    _c = AnimationController(
      vsync: this,
      duration: widget.reducedMotion
          ? const Duration(milliseconds: 320)
          : const Duration(milliseconds: 1320),
    )..addListener(_onTick)..addStatusListener((s) {
        if (s == AnimationStatus.completed && !_done) {
          _done = true;
          widget.onComplete();
        }
      });
    _c.forward();
  }

  void _onTick() {
    if (_revealed || widget.onReveal == null) return;
    final threshold = widget.reducedMotion ? 0.35 : _shatterEnd;
    if (_c.value >= threshold) {
      _revealed = true;
      widget.onReveal!();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onTick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final rm = widget.reducedMotion;

        final glow = rm
            ? 1.0
            : Curves.easeOut.transform((t / _lockEnd).clamp(0.0, 1.0));
        final pulse = rm
            ? 1.0
            : 1 +
                0.02 *
                    math.sin(
                      (t / _lockEnd).clamp(0.0, 1.0) * math.pi,
                    );

        final brandT = rm
            ? t
            : ((t - 0.22) / 0.48).clamp(0.0, 1.0);

        final whiteOpacity = rm
            ? (t < 0.55
                ? Curves.easeOut.transform(t / 0.55)
                : 1 - Curves.easeIn.transform(((t - 0.55) / 0.45).clamp(0.0, 1.0)))
            : _whiteOpacity(t);

        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: widget.frameSize + 8,
                    height: widget.frameSize + 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: kScanCyan.withValues(alpha: 0.35 + 0.65 * glow),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kScanCyan.withValues(alpha: 0.55 * glow),
                          blurRadius: 12 + 24 * glow,
                          spreadRadius: 2 + 4 * glow,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: brandT,
                child: Transform.scale(
                  scale: 0.92 + 0.08 * brandT,
                  child: Center(
                    child: Text(
                      widget.brand,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!rm)
                ..._tiles.map((tile) {
                  final local = ((t - tile.delay) / 0.30).clamp(0.0, 1.0);
                  final appear = Curves.easeOut.transform(local);
                  return Positioned(
                    left: MediaQuery.sizeOf(context).width * tile.nx - tile.w / 2,
                    top: MediaQuery.sizeOf(context).height * tile.ny - tile.h / 2,
                    child: Opacity(
                      opacity: appear,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * appear,
                        child: Container(
                          width: tile.w,
                          height: tile.h,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: whiteOpacity),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _whiteOpacity(double t) {
    if (t < _shatterEnd) {
      return ((t - 0.58) / 0.22).clamp(0.0, 1.0);
    }
    if (t < _holdEnd) return 1;
    return 1 -
        Curves.easeInOut.transform(
          ((t - _holdEnd) / (1 - _holdEnd)).clamp(0.0, 1.0),
        );
  }
}
