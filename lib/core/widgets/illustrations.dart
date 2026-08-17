import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

enum ZepArt {
  scan,
  offline,
  split,
  otp,
  emptyPay,
  emptySplit,
  emptyRequest,
  autopay,
  history,
  receive,
}

/// Brand-colored vector scenes painted with [CustomPainter] (no extra assets).
class ZepIllustration extends StatelessWidget {
  const ZepIllustration(
    this.art, {
    super.key,
    this.size = 180,
    this.float = true,
  });

  final ZepArt art;
  final double size;
  final bool float;

  @override
  Widget build(BuildContext context) {
    final scene = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ZepArtPainter(art)),
    );
    if (!float) return scene;
    return scene
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 1800.ms, curve: Curves.easeInOut);
  }
}

class EmptyScene extends StatelessWidget {
  const EmptyScene({
    super.key,
    required this.art,
    required this.message,
    this.size = 156,
  });

  final ZepArt art;
  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZepIllustration(art, size: size),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _ZepArtPainter extends CustomPainter {
  _ZepArtPainter(this.art);
  final ZepArt art;

  @override
  void paint(Canvas canvas, Size size) {
    switch (art) {
      case ZepArt.scan:
        _scan(canvas, size);
      case ZepArt.offline:
        _offline(canvas, size);
      case ZepArt.split:
        _split(canvas, size);
      case ZepArt.otp:
        _otp(canvas, size);
      case ZepArt.emptyPay:
        _emptyPay(canvas, size);
      case ZepArt.emptySplit:
        _split(canvas, size);
      case ZepArt.emptyRequest:
        _request(canvas, size);
      case ZepArt.autopay:
        _autopay(canvas, size);
      case ZepArt.history:
        _history(canvas, size);
      case ZepArt.receive:
        _receive(canvas, size);
    }
  }

  void _blob(Canvas canvas, Size size) {
    final blob = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.hero.withValues(alpha: 0.22),
          AppColors.hero.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.48),
      size.width * 0.42,
      blob,
    );
  }

  void _scan(Canvas canvas, Size size) {
    _blob(canvas, size);
    final phone = _phoneRect(size, dx: 0.18, dy: 0.12, w: 0.46, h: 0.76);
    _drawPhone(canvas, phone, screen: () {
      _drawQr(canvas, phone.deflate(phone.width * 0.16));
      final beam = Paint()
        ..color = AppColors.hero
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final y = phone.top + phone.height * 0.52;
      canvas.drawLine(
        Offset(phone.left + 8, y),
        Offset(phone.right - 8, y),
        beam,
      );
      canvas.drawLine(
        Offset(phone.left + 8, y),
        Offset(phone.right - 8, y),
        Paint()
          ..color = AppColors.hero.withValues(alpha: 0.35)
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    });
    _drawBoltBadge(canvas, Offset(size.width * 0.78, size.height * 0.28),
        size.width * 0.22);
    _drawCorners(canvas, phone.inflate(10));
  }

  void _offline(Canvas canvas, Size size) {
    _blob(canvas, size);
    final phone = _phoneRect(size, dx: 0.28, dy: 0.18, w: 0.44, h: 0.68);
    _drawPhone(canvas, phone, screen: () {
      final tp = TextPainter(
        text: const TextSpan(
          text: '*99#',
          style: TextStyle(
            color: AppColors.hero,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          phone.center.dx - tp.width / 2,
          phone.center.dy - tp.height / 2,
        ),
      );
    });
    final origin = Offset(size.width * 0.22, size.height * 0.72);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 3; i++) {
      arc.color = AppColors.hero.withValues(alpha: 0.3 + i * 0.2);
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: 11.0 * i),
        -math.pi * 0.55,
        math.pi * 0.5,
        false,
        arc,
      );
    }
    final slash = Paint()
      ..color = AppColors.textDim
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.22),
      Offset(size.width * 0.88, size.height * 0.38),
      slash,
    );
    _wifi(canvas, Offset(size.width * 0.78, size.height * 0.28), 16);
  }

  void _split(Canvas canvas, Size size) {
    _blob(canvas, size);
    final people = [
      Offset(size.width * 0.28, size.height * 0.42),
      Offset(size.width * 0.52, size.height * 0.28),
      Offset(size.width * 0.74, size.height * 0.46),
    ];
    final line = Paint()
      ..color = AppColors.hero.withValues(alpha: 0.45)
      ..strokeWidth = 2.2;
    canvas.drawLine(people[0], people[1], line);
    canvas.drawLine(people[1], people[2], line);
    canvas.drawLine(people[0], people[2], line);
    for (var i = 0; i < people.length; i++) {
      _person(canvas, people[i], 18 + i * 1.5, i == 1);
    }
    _coin(canvas, Offset(size.width * 0.48, size.height * 0.72), 14);
    _coin(canvas, Offset(size.width * 0.62, size.height * 0.78), 10);
    _coin(canvas, Offset(size.width * 0.36, size.height * 0.8), 9);
  }

  void _otp(Canvas canvas, Size size) {
    _blob(canvas, size);
    final phone = _phoneRect(size, dx: 0.3, dy: 0.16, w: 0.4, h: 0.7);
    _drawPhone(canvas, phone, screen: () {
      final dots = Paint()..color = AppColors.hero;
      for (var i = 0; i < 6; i++) {
        canvas.drawCircle(
          Offset(
            phone.left + phone.width * (0.2 + i * 0.12),
            phone.center.dy,
          ),
          3.2,
          dots,
        );
      }
    });
    _bubble(
      canvas,
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.18,
        size.width * 0.34,
        size.height * 0.18,
      ),
      'OTP',
    );
  }

  void _emptyPay(Canvas canvas, Size size) {
    _blob(canvas, size);
    final tray = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.62),
        width: size.width * 0.62,
        height: size.height * 0.18,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      tray,
      Paint()..color = AppColors.surfaceHigh,
    );
    canvas.drawRRect(
      tray,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.hero.withValues(alpha: 0.45),
    );
    _drawQr(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.36),
        width: size.width * 0.34,
        height: size.width * 0.34,
      ),
    );
    _drawBoltBadge(
      canvas,
      Offset(size.width * 0.72, size.height * 0.28),
      size.width * 0.16,
    );
  }

  void _request(Canvas canvas, Size size) {
    _blob(canvas, size);
    final env = Path()
      ..moveTo(size.width * 0.18, size.height * 0.38)
      ..lineTo(size.width * 0.82, size.height * 0.38)
      ..lineTo(size.width * 0.82, size.height * 0.72)
      ..lineTo(size.width * 0.18, size.height * 0.72)
      ..close();
    canvas.drawPath(env, Paint()..color = AppColors.surfaceHigh);
    canvas.drawPath(
      env,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.hero,
    );
    final flap = Path()
      ..moveTo(size.width * 0.18, size.height * 0.38)
      ..lineTo(size.width * 0.5, size.height * 0.58)
      ..lineTo(size.width * 0.82, size.height * 0.38);
    canvas.drawPath(
      flap,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.heroSoft,
    );
    _coin(canvas, Offset(size.width * 0.5, size.height * 0.28), 16);
  }

  void _autopay(Canvas canvas, Size size) {
    _blob(canvas, size);
    final cal = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.22,
        size.width * 0.56,
        size.height * 0.58,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(cal, Paint()..color = AppColors.surfaceHigh);
    canvas.drawRRect(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.22,
        size.width * 0.56,
        size.height * 0.16,
      ),
      Paint()..color = AppColors.hero,
    );
    final cell = Paint()..color = AppColors.hero.withValues(alpha: 0.85);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 4; c++) {
        if (r == 1 && c == 2) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                size.width * (0.3 + c * 0.11),
                size.height * (0.46 + r * 0.1),
                size.width * 0.08,
                size.height * 0.07,
              ),
              const Radius.circular(4),
            ),
            cell,
          );
        } else {
          canvas.drawCircle(
            Offset(
              size.width * (0.34 + c * 0.11),
              size.height * (0.5 + r * 0.1),
            ),
            3,
            Paint()..color = AppColors.textDim,
          );
        }
      }
    }
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.72),
      size.width * 0.14,
      Paint()..color = AppColors.base,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.72),
      size.width * 0.14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = AppColors.hero,
    );
    final hand = Paint()
      ..color = AppColors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.72),
      Offset(size.width * 0.78, size.height * 0.64),
      hand,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.72),
      Offset(size.width * 0.86, size.height * 0.74),
      hand,
    );
  }

  void _history(Canvas canvas, Size size) {
    _blob(canvas, size);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.28 + i * 0.2);
      final card = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.16,
          y,
          size.width * 0.68,
          size.height * 0.16,
        ),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        card,
        Paint()..color = AppColors.surfaceHigh.withValues(alpha: 0.9 - i * 0.15),
      );
      canvas.drawCircle(
        Offset(size.width * 0.28, y + size.height * 0.08),
        10,
        Paint()..color = AppColors.hero.withValues(alpha: 0.7 - i * 0.15),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.38,
            y + size.height * 0.045,
            size.width * 0.36,
            7,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = AppColors.textDim.withValues(alpha: 0.55),
      );
    }
  }

  void _receive(Canvas canvas, Size size) {
    _blob(canvas, size);
    _drawQr(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.48),
        width: size.width * 0.52,
        height: size.width * 0.52,
      ),
    );
    _person(canvas, Offset(size.width * 0.78, size.height * 0.78), 16, true);
  }

  Rect _phoneRect(Size size,
      {required double dx,
      required double dy,
      required double w,
      required double h}) {
    return Rect.fromLTWH(size.width * dx, size.height * dy, size.width * w,
        size.height * h);
  }

  void _drawPhone(Canvas canvas, Rect r, {required VoidCallback screen}) {
    final body = RRect.fromRectAndRadius(r, const Radius.circular(18));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF111113));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.heroSoft.withValues(alpha: 0.7),
    );
    final inner = r.deflate(7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(12)),
      Paint()..color = AppColors.baseAlt,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(12)),
    );
    screen();
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(r.center.dx, r.top + 10),
          width: r.width * 0.28,
          height: 5,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF2A2A2E),
    );
  }

  void _drawQr(Canvas canvas, Rect box) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(8)),
      Paint()..color = AppColors.white,
    );
    final cell = box.width / 11;
    final ink = Paint()..color = const Color(0xFF1C1C1E);
    const pattern = [
      [1, 1, 1, 0, 1, 0, 1, 1, 1],
      [1, 0, 1, 0, 0, 1, 1, 0, 1],
      [1, 1, 1, 1, 0, 1, 0, 1, 1],
      [0, 0, 1, 0, 1, 0, 1, 0, 0],
      [1, 0, 0, 1, 1, 1, 0, 1, 0],
      [0, 1, 1, 0, 0, 1, 1, 0, 1],
      [1, 1, 0, 1, 0, 0, 1, 1, 1],
      [1, 0, 1, 0, 1, 1, 0, 0, 1],
      [1, 1, 1, 0, 1, 0, 1, 1, 1],
    ];
    for (var y = 0; y < 9; y++) {
      for (var x = 0; x < 9; x++) {
        if (pattern[y][x] == 0) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              box.left + cell + x * cell,
              box.top + cell + y * cell,
              cell * 0.86,
              cell * 0.86,
            ),
            const Radius.circular(1.2),
          ),
          ink,
        );
      }
    }
  }

  void _drawCorners(Canvas canvas, Rect r) {
    final p = Paint()
      ..color = AppColors.hero
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 16.0;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * l, 0), p);
      canvas.drawLine(o, o.translate(0, dy * l), p);
    }

    corner(r.topLeft, 1, 1);
    corner(r.topRight, -1, 1);
    corner(r.bottomLeft, 1, -1);
    corner(r.bottomRight, -1, -1);
  }

  void _drawBoltBadge(Canvas canvas, Offset c, double s) {
    canvas.drawCircle(c, s * 0.62, Paint()..color = AppColors.hero);
    final path = Path()
      ..moveTo(c.dx + s * 0.12, c.dy - s * 0.42)
      ..lineTo(c.dx - s * 0.18, c.dy + s * 0.02)
      ..lineTo(c.dx + s * 0.02, c.dy + s * 0.02)
      ..lineTo(c.dx - s * 0.1, c.dy + s * 0.42)
      ..lineTo(c.dx + s * 0.22, c.dy - s * 0.04)
      ..lineTo(c.dx + s * 0.02, c.dy - s * 0.04)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  void _person(Canvas canvas, Offset c, double r, bool accent) {
    final fill = Paint()..color = accent ? AppColors.hero : AppColors.surfaceHigh;
    canvas.drawCircle(c.translate(0, -r * 0.35), r * 0.42, fill);
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, r * 0.55),
        width: r * 1.5,
        height: r * 1.15,
      ),
      fill,
    );
    canvas.drawCircle(
      c.translate(0, -r * 0.35),
      r * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.heroSoft,
    );
  }

  void _coin(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF3BA3FF));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.heroSoft,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          color: AppColors.white,
          fontSize: r * 1.05,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c.translate(-tp.width / 2, -tp.height / 2));
  }

  void _wifi(Canvas canvas, Offset origin, double s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.textMuted;
    for (var i = 1; i <= 2; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: s * 0.4 * i),
        -math.pi * 0.75,
        math.pi * 0.5,
        false,
        p,
      );
    }
    canvas.drawCircle(origin, 2.2, Paint()..color = AppColors.textMuted);
  }

  void _bubble(Canvas canvas, Rect r, String label) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
    canvas.drawRRect(rr, Paint()..color = AppColors.surfaceHigh);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.hero,
    );
    final tail = Path()
      ..moveTo(r.right - 10, r.bottom - 4)
      ..lineTo(r.right + 8, r.bottom + 8)
      ..lineTo(r.right - 22, r.bottom - 4)
      ..close();
    canvas.drawPath(tail, Paint()..color = AppColors.surfaceHigh);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.hero,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ZepArtPainter oldDelegate) =>
      oldDelegate.art != art;
}
