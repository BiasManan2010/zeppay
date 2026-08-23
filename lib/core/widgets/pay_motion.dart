import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

class PaymentSuccessBurst extends StatelessWidget {
  const PaymentSuccessBurst({super.key, this.size = 168});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final i in [0, 1, 2])
            Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35 - i * 0.08),
                      width: 2,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.55, 0.55),
                  end: const Offset(1.25, 1.25),
                  duration: 1400.ms,
                  delay: (i * 180).ms,
                  curve: Curves.easeOut,
                )
                .fade(begin: 0.7, end: 0, duration: 1400.ms, delay: (i * 180).ms),
          Container(
                width: size * 0.62,
                height: size * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.45),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.white,
                  size: size * 0.34,
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.2, 0.2),
                duration: 520.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 180.ms),
        ],
      ),
    );
  }
}

class PaymentFailMark extends StatelessWidget {
  const PaymentFailMark({super.key, this.size = 148});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: 0.18),
            border: Border.all(color: AppColors.danger, width: 3),
          ),
          child: Icon(
            Icons.close_rounded,
            color: AppColors.danger,
            size: size * 0.46,
          ),
        )
        .animate()
        .scale(begin: const Offset(0.6, 0.6), duration: 380.ms, curve: Curves.easeOutBack)
        .then()
        .shake(hz: 4, duration: 320.ms);
  }
}

class PaymentPendingMark extends StatelessWidget {
  const PaymentPendingMark({super.key, this.size = 148});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.warning,
              backgroundColor: AppColors.warning.withValues(alpha: 0.15),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1800.ms),
          Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.warning,
            size: size * 0.38,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.55, end: 1),
        ],
      ),
    );
  }
}

class ConfettiBurst extends StatelessWidget {
  const ConfettiBurst({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(painter: _ConfettiPainter())
            .animate()
            .fadeIn(duration: 200.ms)
            .then(delay: 900.ms)
            .fadeOut(duration: 700.ms),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final colors = [
      AppColors.success,
      AppColors.hero,
      AppColors.heroSoft,
      AppColors.warning,
      AppColors.white,
    ];
    for (var i = 0; i < 42; i++) {
      final p = Paint()..color = colors[i % colors.length];
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final w = 4.0 + rnd.nextDouble() * 6;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.4),
          const Radius.circular(1),
        ),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
