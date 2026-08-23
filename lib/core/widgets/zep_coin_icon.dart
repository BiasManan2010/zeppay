import 'package:flutter/material.dart';

import '../branding_assets.dart';

/// ZepCoin image used wherever a generic coin icon would appear.
class ZepCoinIcon extends StatelessWidget {
  const ZepCoinIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandingAssets.zepCoin,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.monetization_on_rounded,
        size: size,
        color: const Color(0xFFE8B923),
      ),
    );
  }
}
