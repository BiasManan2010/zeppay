import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/semiconductor_models.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.snapshot});

  final ChipLiveSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final label = riskLabel(snapshot);
    final color = riskColor(snapshot);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

String riskLabel(ChipLiveSnapshot snapshot) {
  return switch (snapshot.risk) {
    StockRiskLevel.high => 'HIGH',
    StockRiskLevel.medium => 'MEDIUM',
    StockRiskLevel.low => 'LOW',
    StockRiskLevel.insufficientData => 'NO DATA',
  };
}

Color riskColor(ChipLiveSnapshot snapshot) {
  return switch (snapshot.risk) {
    StockRiskLevel.high => AppColors.danger,
    StockRiskLevel.medium => AppColors.warning,
    StockRiskLevel.low => AppColors.success,
    StockRiskLevel.insufficientData => AppColors.textMuted,
  };
}
