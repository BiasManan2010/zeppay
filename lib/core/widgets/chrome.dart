import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'brand.dart';

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.onTap,
    this.busy = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return HapticScale(
      onTap: busy ? null : onTap,
      enabled: !busy && onTap != null,
      child: Container(
        width: expand ? double.infinity : null,
        height: 56,
        padding: expand ? null : const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.scanOrb,
          boxShadow: [
            BoxShadow(
                color: AppColors.hero.withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 8)),
          ],
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white),
              )
            : Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
              ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return HapticScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceHigh,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          if (badge)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.hero,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.base, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action = 'View all',
    this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                '$action >',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.hero,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return HapticScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.7)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8)),
            BoxShadow(
                color: Color(0x22FFFFFF),
                blurRadius: 1,
                offset: Offset(0, -0.5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.hero.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: AppColors.hero, size: 22),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.hero,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionTileRow extends StatelessWidget {
  const ActionTileRow({super.key, required this.tiles});
  final List<ActionTile> tiles;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class ScanGlyph extends StatelessWidget {
  const ScanGlyph(
      {super.key,
      this.size = 28,
      this.color = AppColors.white,
      this.stroke = 2.4});

  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ScanGlyphPainter(color: color, stroke: stroke),
    );
  }
}

class _ScanGlyphPainter extends CustomPainter {
  _ScanGlyphPainter({required this.color, required this.stroke});
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final l = size.width * 0.28;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * l, 0), p);
      canvas.drawLine(o, o.translate(0, dy * l), p);
    }

    final inset = stroke;
    corner(Offset(inset, inset), 1, 1);
    corner(Offset(size.width - inset, inset), -1, 1);
    corner(Offset(inset, size.height - inset), 1, -1);
    corner(Offset(size.width - inset, size.height - inset), -1, -1);
  }

  @override
  bool shouldRepaint(covariant _ScanGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}

class ScanOrbButton extends StatelessWidget {
  const ScanOrbButton({super.key, this.size = 88, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.scanOrb,
        boxShadow: [
          BoxShadow(
            color: AppColors.hero.withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: ScanGlyph(
            size: size * 0.42,
            color: AppColors.white,
            stroke: size > 70 ? 2.6 : 2.2),
      ),
    );
    if (onTap == null) return orb;
    return HapticScale(onTap: onTap, child: orb);
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.name, this.size = 48});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isEmpty ? 'Z' : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.scanOrb,
        boxShadow: [
          BoxShadow(
              color: AppColors.hero.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class ScanHeroCard extends StatelessWidget {
  const ScanHeroCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w800,
        );
    return HapticScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 176),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: AppColors.scanCard,
          border: Border.all(color: AppColors.hero.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.hero.withValues(alpha: 0.28),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: WavePainter())),
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.hero.withValues(alpha: 0.35),
                      AppColors.hero.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Tap. Pay.\n', style: titleStyle),
                              TextSpan(
                                text: 'Anytime.',
                                style:
                                    titleStyle?.copyWith(color: AppColors.hero),
                              ),
                              TextSpan(text: '\nAnywhere.', style: titleStyle),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.base.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.hero.withValues(alpha: 0.28)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.signal_cellular_alt_rounded,
                                  size: 13, color: AppColors.hero),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Works offline via *99# / 123PAY',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      const ScanOrbButton(size: 86),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to scan',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Scan any UPI QR to pay instantly, even offline.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    letterSpacing: 0,
                                    height: 1.25,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.hero.withValues(alpha: 0.18);
    for (var w = 0; w < 4; w++) {
      final path = Path();
      final amp = 10.0 + w * 6;
      final y0 = size.height * (0.28 + w * 0.16);
      path.moveTo(0, y0);
      for (var x = 0.0; x <= size.width; x += 4) {
        final y = y0 + math.sin((x / size.width) * math.pi * 2 + w) * amp;
        path.lineTo(x, y);
      }
      canvas.drawPath(path,
          paint..color = AppColors.hero.withValues(alpha: 0.08 + w * 0.04));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
