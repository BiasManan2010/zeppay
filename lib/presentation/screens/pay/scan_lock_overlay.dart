import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Paytm-style viewfinder: sweeping beam while hunting, snap + glow on lock.
class PaytmScanFrame extends StatelessWidget {
  const PaytmScanFrame({
    super.key,
    required this.locked,
    required this.t,
    this.size = 268,
  });

  final bool locked;
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FramePainter(locked: locked, t: t),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.locked, required this.t});
  final bool locked;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = lerpDouble(18, 8, locked ? math.min(1, t) : 0)!;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    final dim = Paint()..color = const Color(0x99000000);
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRRect(r);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, hole),
      dim,
    );

    if (locked) {
      final glow = Paint()
        ..color = AppColors.hero.withValues(alpha: 0.22 + 0.28 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawRRect(r.inflate(6), glow);
    }

    final cornerLen = lerpDouble(32, 46, locked ? t : 0)!;
    final stroke = Paint()
      ..color = locked ? AppColors.heroSoft : AppColors.hero
      ..strokeWidth = locked ? 4.2 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void corner(Offset o, double sx, double sy) {
      canvas.drawLine(o, o.translate(sx * cornerLen, 0), stroke);
      canvas.drawLine(o, o.translate(0, sy * cornerLen), stroke);
    }

    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);
    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);

    if (!locked) {
      final y = rect.top + (rect.height * ((t % 1 + 1) % 1));
      final beam = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.hero.withValues(alpha: 0),
            AppColors.heroSoft.withValues(alpha: 0.95),
            AppColors.hero.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(rect.left, y - 10, rect.width, 20));
      canvas.drawRect(Rect.fromLTWH(rect.left + 8, y - 1.5, rect.width - 16, 3), beam);
    } else {
      final mid = Offset(rect.center.dx, rect.center.dy);
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
  bool shouldRepaint(covariant _FramePainter old) =>
      old.locked != locked || old.t != t;
}

class MerchantLockCard extends StatelessWidget {
  const MerchantLockCard({
    super.key,
    required this.name,
    required this.vpa,
  });

  final String name;
  final String vpa;

  @override
  Widget build(BuildContext context) {
    final title = name.isEmpty ? vpa : name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: AppColors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      vpa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HintChip(icon: Icons.verified_user_outlined, label: 'Trusted UPI'),
              _HintChip(icon: Icons.credit_card_rounded, label: 'UPI / RuPay'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hero.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.heroSoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
