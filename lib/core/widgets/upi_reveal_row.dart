import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/zep_palette.dart';

/// Masked real UPI ID with eye toggle and copy — same VPA as Profile.
class UpiRevealRow extends StatefulWidget {
  const UpiRevealRow({
    super.key,
    required this.upiId,
    this.dense = false,
  });

  final String upiId;
  final bool dense;

  @override
  State<UpiRevealRow> createState() => _UpiRevealRowState();
}

class _UpiRevealRowState extends State<UpiRevealRow> {
  var _revealed = false;

  String get _masked {
    final vpa = widget.upiId.trim();
    if (vpa.isEmpty) return 'Add UPI ID in Profile';
    if (!_revealed) {
      final parts = vpa.split('@');
      if (parts.length != 2) return '•••••••••@upi';
      return '${'•' * parts[0].length}@${parts[1]}';
    }
    return vpa;
  }

  @override
  Widget build(BuildContext context) {
    final zep = context.zep;
    final hasVpa = widget.upiId.contains('@');
    final textStyle = TextStyle(
      color: widget.dense ? zep.textPrimary : AppColors.heroSoft,
      fontSize: widget.dense ? 13 : 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.dense ? 0 : 20,
        vertical: widget.dense ? 4 : 8,
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_rounded,
            size: 18,
            color: widget.dense ? zep.textMuted : AppColors.heroSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _masked,
              style: textStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasVpa) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: zep.textMuted,
              ),
              onPressed: () => setState(() => _revealed = !_revealed),
            ),
            if (_revealed)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.copy_rounded, size: 18, color: zep.textMuted),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.upiId.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UPI ID copied')),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}
