class NetworkInfo {
  const NetworkInfo({
    required this.operator,
    required this.isJio,
    required this.networkType,
    required this.recommendedRail,
    required this.ussdSupported,
    required this.platform,
    this.manufacturer = '',
  });

  final String operator;
  final bool isJio;
  final String networkType;
  final String recommendedRail;
  final bool ussdSupported;
  final String platform;
  final String manufacturer;

  factory NetworkInfo.unknown() => const NetworkInfo(
        operator: 'unknown',
        isJio: false,
        networkType: 'unknown',
        recommendedRail: 'ivr',
        ussdSupported: false,
        platform: 'unknown',
      );

  factory NetworkInfo.fromMap(Map<dynamic, dynamic> m) => NetworkInfo(
        operator: m['operator'] as String? ?? '',
        isJio: m['isJio'] as bool? ?? false,
        networkType: m['networkType'] as String? ?? 'unknown',
        recommendedRail: m['recommendedRail'] as String? ?? 'ivr',
        ussdSupported: m['ussdSupported'] as bool? ?? false,
        platform: m['platform'] as String? ?? 'android',
        manufacturer: m['manufacturer'] as String? ?? '',
      );
}
