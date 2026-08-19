/// Metrics from watching the browser leave for Phone and come back.
class DialSessionReport {
  const DialSessionReport({
    this.longestStint = Duration.zero,
    this.totalHidden = Duration.zero,
    this.stintCount = 0,
    this.leftAt,
    this.returnedAt,
    this.timedOut = false,
  });

  final Duration longestStint;
  final Duration totalHidden;
  final int stintCount;
  final DateTime? leftAt;
  final DateTime? returnedAt;
  final bool timedOut;

  bool get everLeftPhone => stintCount > 0 && longestStint > Duration.zero;

  DialSessionReport copyWith({
    Duration? longestStint,
    Duration? totalHidden,
    int? stintCount,
    DateTime? leftAt,
    DateTime? returnedAt,
    bool? timedOut,
  }) =>
      DialSessionReport(
        longestStint: longestStint ?? this.longestStint,
        totalHidden: totalHidden ?? this.totalHidden,
        stintCount: stintCount ?? this.stintCount,
        leftAt: leftAt ?? this.leftAt,
        returnedAt: returnedAt ?? this.returnedAt,
        timedOut: timedOut ?? this.timedOut,
      );
}
