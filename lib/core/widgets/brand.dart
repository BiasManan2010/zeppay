import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/zep_palette.dart';
import '../motion/app_motion.dart';

class HapticScale extends StatefulWidget {
  const HapticScale(
      {super.key, required this.child, this.onTap, this.enabled = true});

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<HapticScale> createState() => _HapticScaleState();
}

class _HapticScaleState extends State<HapticScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _scale = 0.94) : null,
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _scale,
        duration: AppMotion.fast,
        curve: AppMotion.out,
        child: widget.child,
      ),
    );
  }
}

class DottedRing extends StatelessWidget {
  const DottedRing(
      {super.key, this.size = 72, this.progress = 0.35, this.spinning = true});

  final double size;
  final double progress;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final ring = CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(progress: progress),
    );
    if (!spinning) return ring;
    return ring
        .animate(onPlay: (c) => c.repeat())
        .rotate(duration: 2400.ms, begin: 0, end: 1);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    final glow = Paint()
      ..color = AppColors.hero.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final solid = Paint()
      ..color = AppColors.hero
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        math.pi * 1.55, false, glow);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        math.pi * 1.55, false, solid);
    const dashes = 3;
    for (var i = 0; i < dashes; i++) {
      final start = math.pi * 1.05 + i * 0.22;
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r), start, 0.12, false, solid);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class SignalArcs extends StatelessWidget {
  const SignalArcs({super.key, this.size = 88});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ArcsPainter())
          .animate(onPlay: (c) => c.repeat())
          .fade(begin: 0.35, end: 1, duration: 900.ms)
          .then()
          .fade(begin: 1, end: 0.35, duration: 900.ms),
    );
  }
}

class _ArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hero
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final origin = Offset(size.width * 0.28, size.height * 0.72);
    for (var i = 1; i <= 3; i++) {
      final r = 12.0 * i;
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: r),
        -math.pi * 0.55,
        math.pi * 0.5,
        false,
        paint..color = AppColors.hero.withValues(alpha: 0.35 + i * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BoltCheck extends StatelessWidget {
  const BoltCheck({super.key, this.size = 120, this.complete = false});
  final double size;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BoltPainter(complete: complete)),
    ).animate().scale(
        begin: const Offset(0.6, 0.6),
        duration: 420.ms,
        curve: Curves.easeOutBack);
  }
}

class _BoltPainter extends CustomPainter {
  _BoltPainter({required this.complete});
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1);
    final path = Path();
    if (!complete) {
      path.moveTo(size.width * 0.62, size.height * 0.12);
      path.lineTo(size.width * 0.32, size.height * 0.52);
      path.lineTo(size.width * 0.52, size.height * 0.52);
      path.lineTo(size.width * 0.38, size.height * 0.88);
      path.lineTo(size.width * 0.72, size.height * 0.42);
      path.lineTo(size.width * 0.5, size.height * 0.42);
      path.close();
      canvas.drawPath(path, p..style = PaintingStyle.fill);
    } else {
      path.moveTo(size.width * 0.22, size.height * 0.52);
      path.lineTo(size.width * 0.42, size.height * 0.72);
      path.lineTo(size.width * 0.78, size.height * 0.28);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BoltPainter oldDelegate) =>
      oldDelegate.complete != complete;
}

class FaceGlow extends StatelessWidget {
  const FaceGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 260,
      child: CustomPaint(painter: _FacePainter())
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 0.55, end: 1, duration: 1200.ms),
    );
  }
}

class _FacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = AppColors.hero.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final line = Paint()
      ..color = AppColors.hero
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.62,
      height: size.height * 0.78,
    );
    canvas.drawOval(oval, glow);
    canvas.drawOval(oval, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanBrackets extends StatelessWidget {
  const ScanBrackets({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BracketPainter())
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.04, 1.04),
            duration: 900.ms);
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.hero
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const l = 28.0;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * l, 0), p);
      canvas.drawLine(o, o.translate(0, dy * l), p);
    }

    corner(const Offset(8, 8), 1, 1);
    corner(Offset(size.width - 8, 8), -1, 1);
    corner(Offset(8, size.height - 8), 1, -1);
    corner(Offset(size.width - 8, size.height - 8), -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding, this.onTap});
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final zep = context.zep;
    final body = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zep.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zep.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return body;
    return HapticScale(onTap: onTap, child: body);
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText(this.paise, {super.key, this.style, this.currency = '₹'});
  final int paise;
  final TextStyle? style;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final rupees = paise / 100;
    final text = rupees >= 1000
        ? '$currency${rupees.toStringAsFixed(0)}'
        : '$currency${rupees.toStringAsFixed(2)}';
    return Text(text, style: style);
  }
}
