import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../media_image.dart';
import '../motion/app_motion.dart';
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
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
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
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.25, duration: 900.ms),
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
          border: Border.all(
            color: AppColors.surfaceBorder.withValues(alpha: 0.7),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x22FFFFFF),
              blurRadius: 1,
              offset: Offset(0, -0.5),
            ),
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
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
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
            Expanded(
              child: RiseIn(
                delay: Duration(milliseconds: 45 * i),
                dy: 0.08,
                child: tiles[i],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ScanGlyph extends StatelessWidget {
  const ScanGlyph({
    super.key,
    this.size = 28,
    this.color = AppColors.white,
    this.stroke = 2.4,
  });

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
          stroke: size > 70 ? 2.6 : 2.2,
        ),
      ),
    );
    if (onTap == null) return orb;
    return HapticScale(onTap: onTap, child: orb);
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoPath = '',
    this.size = 48,
    this.showEdit = false,
  });

  final String name;
  final String photoPath;
  final double size;
  final bool showEdit;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? 'Z'
        : name.trim().characters.first.toUpperCase();
    final photo = mediaImage(photoPath);
    final hasPhoto = photo != null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.scanOrb,
              boxShadow: [
                BoxShadow(
                  color: AppColors.hero.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
              image: hasPhoto
                  ? DecorationImage(
                      image: photo,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPhoto
                ? null
                : Text(
                    initial,
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.38,
                    ),
                  ),
          ),
          if (showEdit)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hero,
                  border: Border.all(color: AppColors.base, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: size * 0.16,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
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
            Positioned.fill(child: _LiveWaves()),
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
                                style: titleStyle?.copyWith(
                                  color: AppColors.hero,
                                ),
                              ),
                              TextSpan(text: '\nAnywhere.', style: titleStyle),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.base.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.hero.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.signal_cellular_alt_rounded,
                                size: 13,
                                color: AppColors.hero,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Works offline via *99# / 123PAY',
                                  style: Theme.of(context).textTheme.labelSmall
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
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 110,
                        child: Text(
                          'Scan any UPI QR to pay instantly, even offline.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(letterSpacing: 0, height: 1.25),
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
  WavePainter({this.phase = 0});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var w = 0; w < 4; w++) {
      final path = Path();
      final amp = 10.0 + w * 6;
      final y0 = size.height * (0.28 + w * 0.16);
      path.moveTo(0, y0);
      for (var x = 0.0; x <= size.width; x += 4) {
        final y =
            y0 +
            math.sin((x / size.width) * math.pi * 2 + w + phase) * amp;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        paint..color = AppColors.hero.withValues(alpha: 0.08 + w * 0.04),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _LiveWaves extends StatefulWidget {
  @override
  State<_LiveWaves> createState() => _LiveWavesState();
}

class _LiveWavesState extends State<_LiveWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) =>
          CustomPaint(painter: WavePainter(phase: _c.value * math.pi * 2)),
    );
  }
}

class ZepPage extends StatelessWidget {
  const ZepPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0),
          Expanded(
            child: RiseIn(delay: const Duration(milliseconds: 40), child: child),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: footer,
            ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08, end: 0),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 140, this.wordmark = false});

  final double size;
  final bool wordmark;

  static const markAsset = 'assets/branding/zeppay_mark.png';
  static const lockupAsset = 'assets/branding/zeppay_logo.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      wordmark ? lockupAsset : markAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.bolt_rounded, size: size * 0.55, color: AppColors.hero),
    );
  }
}

class AuthBackdrop extends StatefulWidget {
  const AuthBackdrop({super.key, required this.child, this.safe = true});

  final Widget child;
  final bool safe;

  @override
  State<AuthBackdrop> createState() => _AuthBackdropState();
}

class _AuthBackdropState extends State<AuthBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.safe ? SafeArea(child: widget.child) : widget.child;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.55),
                      radius: 1.15,
                      colors: [AppColors.homeWash, AppColors.base],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -80 + (t * 24),
                left: -40 + (t * 18),
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.hero.withValues(alpha: 0.12 + t * 0.08),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 80 - (t * 20),
                right: -60 + (t * 16),
                child: IgnorePointer(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.heroDeep.withValues(
                        alpha: 0.16 + (1 - t) * 0.1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: body),
            ],
          );
        },
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.hero.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.hero.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class StepPills extends StatelessWidget {
  const StepPills({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              height: 4,
              decoration: BoxDecoration(
                color: i <= index ? AppColors.hero : AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
