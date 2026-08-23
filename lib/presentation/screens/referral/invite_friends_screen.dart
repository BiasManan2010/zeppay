import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/services/referral_flow.dart';
import '../../../data/services/referral_service.dart';

class InviteFriendsScreen extends ConsumerStatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  ConsumerState<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends ConsumerState<InviteFriendsScreen> {
  String? _code;
  var _friends = 0;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final phone = ref.read(appStoreProvider).sessionPhone;
    if (phone == null) {
      setState(() => _loading = false);
      return;
    }
    await syncReferralRewards(ref);
    final code = await ReferralService.instance.ensureReferralCode(phone);
    final friends = code == null
        ? 0
        : await ReferralService.instance.friendCount(code);
    if (!mounted) return;
    setState(() {
      _code = code;
      _friends = friends;
      _loading = false;
    });
  }

  void _share() {
    final code = _code;
    if (code == null || code.isEmpty) return;
    Share.share(
      'Join me on Zep Pay — offline UPI when data dies. Use my code $code when you sign up to earn ZepCoins!',
      subject: 'Zep Pay invite',
    );
  }

  @override
  Widget build(BuildContext context) {
    final coinsEarned = _friends * ReferralService.coinsPerJoin;
    return ZepPage(
      title: 'Invite Friends',
      subtitle:
          'Share your code — friends join for free, you both earn ZepCoins.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (_code == null) ...[
            const Text(
              'Supabase is not configured — referral codes need cloud setup.',
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Your referral code',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _code!,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$_friends friends joined using your code',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '$coinsEarned ZepCoins earned from referrals',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.hero,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: 'SHARE INVITE',
              onTap: _share,
            ),
          ],
        ],
      ),
    );
  }
}
