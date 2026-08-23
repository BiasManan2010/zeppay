import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'qr_scan_transition.dart';

/// Paytm-style scan window: pulsing glow ring, corner brackets, sweeping beam.
class ScanViewfinder extends StatelessWidget {
  const ScanViewfinder({
    super.key,
    required this.t,
    required this.locked,
    this.showBeam = true,
  });

  final double t;
  final bool locked;
  final bool showBeam;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!locked)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: kScanCyan.withValues(alpha: 0.28 + 0.42 * pulse),
                  width: 2.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kScanCyan.withValues(alpha: 0.18 + 0.38 * pulse),
                    blurRadius: 10 + 18 * pulse,
                    spreadRadius: 1 + 4 * pulse,
                  ),
                  BoxShadow(
                    color: kScanCyanSoft.withValues(alpha: 0.08 + 0.14 * pulse),
                    blurRadius: 28 + 12 * pulse,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        CustomPaint(
          painter: _ViewfinderPainter(
            t: t,
            locked: locked,
            showBeam: showBeam,
          ),
        ),
      ],
    );
  }
}

class ScanDimOverlay extends StatelessWidget {
  const ScanDimOverlay({
    super.key,
    required this.frameSize,
    this.topInset = 0,
  });

  final double frameSize;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DimPainter(
        frameSize: frameSize,
        topInset: topInset,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DimPainter extends CustomPainter {
  _DimPainter({required this.frameSize, required this.topInset});

  final double frameSize;
  final double topInset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, topInset + (size.height - topInset) / 2);
    final hole = Rect.fromCenter(
      center: center,
      width: frameSize,
      height: frameSize,
    );
    final r = RRect.fromRectAndRadius(hole, const Radius.circular(22));
    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(r)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = const Color(0xAA000000));
  }

  @override
  bool shouldRepaint(covariant _DimPainter old) =>
      old.frameSize != frameSize || old.topInset != topInset;
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({
    required this.t,
    required this.locked,
    required this.showBeam,
  });

  final double t;
  final bool locked;
  final bool showBeam;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = lerpDouble(10, 4, locked ? math.min(1, t) : 0)!;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    if (locked) {
      final glow = Paint()
        ..color = AppColors.hero.withValues(alpha: 0.2 + 0.3 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawRRect(r.inflate(5), glow);
    }

    final cornerLen = lerpDouble(34, 48, locked ? t : 0)!;
    final stroke = Paint()
      ..color = locked ? AppColors.heroSoft : kScanCyanSoft
      ..strokeWidth = locked ? 4 : 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset o, double sx, double sy) {
      canvas.drawLine(o, o.translate(sx * cornerLen, 0), stroke);
      canvas.drawLine(o, o.translate(0, sy * cornerLen), stroke);
    }

    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);
    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);

    if (!locked && showBeam) {
      final phase = (t % 1 + 1) % 1;
      final y = rect.top + rect.height * phase;
      final beam = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kScanCyan.withValues(alpha: 0),
            kScanCyanSoft.withValues(alpha: 0.95),
            kScanCyan.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(rect.left, y - 12, rect.width, 24));
      canvas.drawRect(
        Rect.fromLTWH(rect.left + 10, y - 1.5, rect.width - 20, 3),
        beam,
      );
    } else if (locked) {
      final mid = rect.center;
      final tick = Paint()
        ..color = AppColors.white
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final s = 12.0 + 6 * t;
      final path = Path()
        ..moveTo(mid.dx - s, mid.dy)
        ..lineTo(mid.dx - s * 0.25, mid.dy + s * 0.7)
        ..lineTo(mid.dx + s, mid.dy - s * 0.55);
      canvas.drawPath(path, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter old) =>
      old.t != t || old.locked != locked || old.showBeam != showBeam;
}
