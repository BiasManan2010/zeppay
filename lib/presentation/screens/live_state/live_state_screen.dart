import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/services/live_state_provider.dart';
import '../../../data/services/semiconductor_repository.dart';
import '../../../data/services/user_card_repository.dart';

class LiveStateScreen extends ConsumerWidget {
  const LiveStateScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(liveStateProvider);
    ref.invalidate(userCardProvider);
    final chipId = await ref.read(userCardChipIdProvider.future);
    if (chipId != null) {
      ref.invalidate(chipDetailProvider(chipId));
      ref.invalidate(chipTransactionsProvider(chipId));
    }
    await ref.read(liveStateProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStateProvider);
    final fmt = DateFormat('d MMM yyyy, h:mm:ss a');

    return ZepPage(
      title: 'My Live State',
      subtitle:
          'Every value below was fetched at the timestamp shown — no cached fallbacks.',
      child: live.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () => ref.invalidate(liveStateProvider),
        ),
        data: (snapshot) {
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _refresh(ref),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh now'),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.hero.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.hero.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'As of ${fmt.format(snapshot.asOf)}',
                    style: const TextStyle(
                      color: AppColors.hero,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LiveRow(
                  label: 'Completed transactions',
                  value: '${snapshot.completedTxCount}',
                  hint: 'Successful payments in local ledger',
                ),
                _LiveRow(
                  label: 'ZepCoins balance',
                  value: '${snapshot.zepCoinBalance}',
                  hint: 'From coins ledger on this device',
                ),
                _LiveRow(
                  label: 'Pending requests',
                  value: '${snapshot.pendingRequestsCount}',
                  hint: 'Open payment requests awaiting action',
                ),
                if (snapshot.hasZepCard) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Zep Card chip (Supabase)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.supabaseFetchError != null)
                    _ErrorBody(
                      message: snapshot.supabaseFetchError!,
                      onRetry: () => ref.invalidate(liveStateProvider),
                    )
                  else ...[
                    _LiveRow(
                      label: 'Chip risk level',
                      value: snapshot.chipRiskLevel ?? '—',
                      hint: 'Live from semiconductors table',
                    ),
                    _LiveRow(
                      label: 'Chip transaction count',
                      value: '${snapshot.chipTransactionCount ?? 0}',
                      hint: 'Rows in inventory_transactions for your chip',
                    ),
                  ],
                ] else if (snapshot.supabaseConfigured)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No Zep Card linked — chip fields omitted.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Supabase not configured — chip fields omitted.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textOnCreamMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textOnCream,
                ),
          ),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
