import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card-specific palette — scoped to this widget only.
abstract final class _CardPalette {
  static const navy = Color(0xFF0A1628);
  static const black = Color(0xFF020408);
  static const blueGlow = Color(0xFF3BA3FF);
  static const goldLight = Color(0xFFE8C56A);
  static const goldDark = Color(0xFFB8860B);
}

/// 3D-styled Zep Card with tilt-in animation and embossed cardholder name.
class ZepPhysicalCard extends StatefulWidget {
  const ZepPhysicalCard({
    super.key,
    required this.cardholderName,
    this.animateOnMount = true,
    this.onTap,
  });

  final String cardholderName;
  final bool animateOnMount;
  final VoidCallback? onTap;

  @override
  State<ZepPhysicalCard> createState() => _ZepPhysicalCardState();
}

class _ZepPhysicalCardState extends State<ZepPhysicalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _tilt;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _tilt = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.animateOnMount) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final name = widget.cardholderName.trim().isEmpty
        ? 'CARDHOLDER'
        : widget.cardholderName.trim().toUpperCase();

    return AnimatedBuilder(
      animation: _tilt,
      builder: (context, child) {
        final t = _tilt.value;
        final pressTilt = _pressed ? 0.04 : 0.0;
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-0.12 * (1 - t) + pressTilt)
          ..rotateY(0.18 * (1 - t) - pressTilt);

        return Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _CardPalette.blueGlow.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1.586,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _CardPalette.navy,
                          _CardPalette.black,
                          Color(0xFF0D1F35),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _DiagonalSheenPainter()),
                  ),
                  Positioned(
                    right: -30,
                    top: 40,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _CardPalette.blueGlow.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'ZEP',
                                        style: TextStyle(
                                          color: _CardPalette.blueGlow,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' CARD',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap. Identify. Pay.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _CardPalette.blueGlow
                                      .withValues(alpha: 0.6),
                                ),
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'ZP',
                                style: TextStyle(
                                  color: _CardPalette.blueGlow,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _GoldChip(),
                            const Spacer(),
                            const _NfcTapGlyph(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ZEP PAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            Text(
                              'OFFLINE. SECURE. SEAMLESS.',
                              style: TextStyle(
                                color: AppColors.heroSoft.withValues(alpha: 0.85),
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
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
          ),
        ),
      ),
    );
  }
}

class _GoldChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_CardPalette.goldLight, _CardPalette.goldDark],
        ),
        boxShadow: [
          BoxShadow(
            color: _CardPalette.goldDark.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
    }
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NfcTapGlyph extends StatelessWidget {
  const _NfcTapGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _NfcRingsPainter(),
        child: const Center(
          child: Icon(
            Icons.contactless_rounded,
            color: _CardPalette.blueGlow,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _NfcRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 1; i <= 3; i++) {
      final radius = size.width * 0.18 * i;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _CardPalette.blueGlow.withValues(alpha: 0.22 + i * 0.12);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.14),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.04),
        ],
        stops: const [0.0, 0.45, 1.0],
        transform: GradientRotation(-math.pi / 5),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
