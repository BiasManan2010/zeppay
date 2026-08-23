import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'zep_coin_icon.dart';

/// Reusable Zep Pay UI components (4/8px spacing scale).
class ZepHeaderBar extends StatefulWidget {
  const ZepHeaderBar({
    super.key,
    required this.name,
    required this.upiId,
    this.unreadCount = 0,
    this.onNotifications,
    this.avatarUrl,
  });

  final String name;
  final String upiId;
  final int unreadCount;
  final VoidCallback? onNotifications;
  final String? avatarUrl;

  @override
  State<ZepHeaderBar> createState() => _ZepHeaderBarState();
}

class _ZepHeaderBarState extends State<ZepHeaderBar> {
  var _maskVpa = true;

  String get _displayVpa {
    if (widget.upiId.isEmpty) return 'Add UPI ID';
    if (!_maskVpa) return widget.upiId;
    final parts = widget.upiId.split('@');
    if (parts.length != 2) return '••••@upi';
    final user = parts[0];
    final masked = user.length <= 2
        ? '••'
        : '${user.substring(0, 2)}${'•' * (user.length - 2)}';
    return '$masked@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = widget.name.isEmpty ? 'there' : widget.name.split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.cardDark,
            child: Text(
              greeting.isNotEmpty ? greeting[0].toUpperCase() : 'Z',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $greeting 👋',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _displayVpa,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _maskVpa
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textOnCreamMuted,
                      ),
                      onPressed: () => setState(() => _maskVpa = !_maskVpa),
                    ),
                    if (widget.upiId.isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        color: AppColors.textOnCreamMuted,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.upiId),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('UPI ID copied')),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textOnCream,
                onPressed: widget.onNotifications ?? () => context.push('/inbox'),
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ZepBankCard extends StatelessWidget {
  const ZepBankCard({
    super.key,
    required this.bankName,
    required this.accountLast4,
    required this.balancePaise,
  });

  final String bankName;
  final String accountLast4;
  final int balancePaise;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.forestCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bankName.isEmpty ? 'Linked bank' : bankName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.credit_card_rounded, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            accountLast4.isEmpty ? '•••• •••• ••••' : '•••• $accountLast4',
            style: const TextStyle(color: Colors.white70, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${(balancePaise / 100).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Local ledger balance',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ZepQuickAction extends StatelessWidget {
  const ZepQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tint, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textOnCream,
                  fontSize: 11,
                ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class ZepDarkCard extends StatelessWidget {
  const ZepDarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class ZepSectionHeader extends StatelessWidget {
  const ZepSectionHeader({
    super.key,
    required this.title,
    this.badge,
    this.onViewAll,
  });

  final String title;
  final int? badge;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (badge != null && badge! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
        ],
      ),
    );
  }
}

class ZepPromoBanner extends StatelessWidget {
  const ZepPromoBanner({
    super.key,
    required this.headline,
    required this.subtext,
    required this.chip,
    this.onTap,
  });

  final String headline;
  final String subtext;
  final String chip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ZepDarkCard(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtext,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}

class ZepOrangeFab extends StatelessWidget {
  const ZepOrangeFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.scanOrb,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner_rounded,
            color: Colors.white, size: 30),
      ),
    );
  }
}

/// Persistent ZepCoins balance pill — tap opens Coins screen.
class ZepCoinBalanceChip extends StatelessWidget {
  const ZepCoinBalanceChip({
    super.key,
    required this.balance,
    this.subtitle,
    this.onTap,
  });

  final int balance;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap ?? () => context.push('/coins'),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ZepCoinIcon(size: 28),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$balance ZepCoins',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textOnCreamMuted,
                            ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
