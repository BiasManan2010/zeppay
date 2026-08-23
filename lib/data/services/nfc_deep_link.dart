import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/chip_tag_codec.dart';
import '../models/zep_card.dart';

final appLinksProvider = Provider<AppLinks>((_) => AppLinks());

/// Routes zeppay://profile and HTTPS fallback links into the app.
class NfcDeepLinkListener {
  NfcDeepLinkListener(this._router, this._links);

  final GoRouter _router;
  final AppLinks _links;
  StreamSubscription<Uri>? _sub;

  Future<void> init() async {
    try {
      final initial = await _links.getInitialLink();
      _route(initial);
      _sub = _links.uriLinkStream.listen(_route);
    } catch (e) {
      debugPrint('deep link init failed: $e');
    }
  }

  void _route(Uri? uri) {
    final chipNfcId = ChipTagCodec.parseUri(uri);
    if (chipNfcId != null) {
      _router.go(
        '/chip/nfc/${Uri.encodeComponent(chipNfcId)}',
      );
      return;
    }
    final profile = ZepCardCodec.parseUri(uri);
    if (profile == null) return;
    _router.go(
      '/nfc/profile?vpa=${Uri.encodeComponent(profile.vpa)}&name=${Uri.encodeComponent(profile.name)}',
    );
  }

  void dispose() => _sub?.cancel();
}
