/// Parsed identity from a Zep Card NFC tag or deep link.
class ZepCardProfile {
  const ZepCardProfile({required this.vpa, required this.name});

  final String vpa;
  final String name;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      final local = vpa.split('@').first;
      return local.isEmpty ? 'Z' : local.substring(0, 1).toUpperCase();
    }
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

/// Static NDEF payload: custom scheme + HTTPS fallback for phones without the app.
abstract final class ZepCardCodec {
  static const profileScheme = 'zeppay';
  static const profileHost = 'profile';
  static const webProfileBase =
      'https://biasmanan2010.github.io/zeppay/profile';

  static Uri appUri({required String vpa, required String name}) {
    return Uri(
      scheme: profileScheme,
      host: profileHost,
      queryParameters: {'vpa': vpa, 'name': name},
    );
  }

  static Uri webUri({required String vpa, required String name}) {
    return Uri.parse(webProfileBase).replace(
      queryParameters: {'vpa': vpa, 'name': name},
    );
  }

  static ZepCardProfile? parseUri(Uri? uri) {
    if (uri == null) return null;
    final vpa = uri.queryParameters['vpa']?.trim() ?? '';
    if (!vpa.contains('@')) return null;
    final name = uri.queryParameters['name']?.trim() ?? '';
    final path = uri.path;
    final isProfile = uri.host == profileHost ||
        path.endsWith('/profile') ||
        path.contains('/profile');
    final isZepScheme = uri.scheme == profileScheme;
    final isWebFallback = uri.scheme == 'https' &&
        uri.host == 'biasmanan2010.github.io' &&
        path.startsWith('/zeppay/profile');
    if (!isZepScheme && !isWebFallback && !isProfile) return null;
    return ZepCardProfile(vpa: vpa, name: name);
  }

  static ZepCardProfile? parseLink(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return parseUri(Uri.tryParse(raw.trim()));
  }
}
