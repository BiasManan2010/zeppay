import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../core/widgets/zep_components.dart';
import '../../../core/widgets/zep_physical_card.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/user_card.dart';
import '../../../data/services/nfc_card_service.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/supabase_service.dart';
import '../../../data/services/user_card_repository.dart';

class GetZepCardScreen extends ConsumerStatefulWidget {
  const GetZepCardScreen({super.key});

  @override
  ConsumerState<GetZepCardScreen> createState() => _GetZepCardScreenState();
}

class _GetZepCardScreenState extends ConsumerState<GetZepCardScreen> {
  final _nfcId = TextEditingController();
  final _cardName = TextEditingController();
  var _busy = false;
  var _nfcListening = false;
  String _status = '';
  var _nfcOk = false;

  @override
  void initState() {
    super.initState();
    final name = ref.read(appStoreProvider).profile?.name ?? '';
    _cardName.text = name;
    _checkNfc();
  }

  @override
  void dispose() {
    _nfcId.dispose();
    _cardName.dispose();
    NfcCardService.instance.stopListening();
    super.dispose();
  }

  Future<void> _checkNfc() async {
    final ok = await NfcCardService.instance.isAvailable();
    if (mounted) setState(() => _nfcOk = ok);
  }

  Future<void> _buyNewCard() async {
    if (!SupabaseService.instance.isReady) {
      setState(() => _status = 'Supabase must be configured before ordering a card.');
      return;
    }
    final existing = await ref.read(userCardProvider.future);
    if (existing != null) {
      if (!mounted) return;
      context.go('/my-zep-card');
      return;
    }
    startPayment(
      ref,
      vpa: kZepCardOrderVpa,
      amountPaise: kZepCardPricePaise,
      payeeName: 'Zep Card Store',
      note: 'Zep Card — New Card',
      source: 'zep_card',
      category: 'shopping',
      zepCardPurchase: true,
    );
    if (!mounted) return;
    context.push('/pay/amount');
  }

  Future<void> _claimExisting() async {
    if (!SupabaseService.instance.isReady) {
      setState(() => _status = 'Supabase must be configured to claim a card.');
      return;
    }
    final id = _nfcId.text.trim().toUpperCase();
    if (id.isEmpty) {
      setState(() => _status = 'Enter the NFC ID printed on your card.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Linking card…';
    });
    try {
      final phone = ref.read(appStoreProvider).sessionPhone;
      if (phone == null || phone.isEmpty) {
        throw StateError('Sign in first.');
      }
      final name = _cardName.text.trim().isNotEmpty
          ? _cardName.text.trim()
          : (ref.read(appStoreProvider).profile?.name ?? 'Cardholder');
      await UserCardRepository.instance.claimCard(
        phone: phone,
        nfcId: id,
        cardName: name,
      );
      ref.invalidate(userCardProvider);
      if (!mounted) return;
      context.go('/my-zep-card');
    } catch (e) {
      if (mounted) setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleNfcRead() async {
    if (_nfcListening) {
      await NfcCardService.instance.stopListening();
      if (mounted) setState(() => _nfcListening = false);
      return;
    }
    if (!isAndroidDevice || !_nfcOk) {
      setState(() => _status = 'NFC read is available on Android with NFC enabled.');
      return;
    }
    setState(() {
      _nfcListening = true;
      _status = 'Hold your Zep Card to the back of this phone…';
    });
    await NfcCardService.instance.startChipListening(
      (nfcId) async {
        await NfcCardService.instance.stopListening();
        if (!mounted) return;
        setState(() {
          _nfcListening = false;
          _nfcId.text = nfcId;
          _status = 'Read $nfcId — tap Link card to continue.';
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _nfcListening = false;
          _status = e.toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(appStoreProvider).profile;
    final previewName = _cardName.text.trim().isNotEmpty
        ? _cardName.text.trim()
        : (profile?.name ?? '');

    return ZepPage(
      title: 'Get Zep Card',
      subtitle:
          'Order a new physical card or link one you already have. Your real bank UPI ID stays on Profile — never a @zeppay handle.',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          ZepPhysicalCard(
            cardholderName: previewName,
            animateOnMount: true,
          ),
          const SizedBox(height: 8),
          ZepDarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.hero.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_card_rounded,
                        color: AppColors.hero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get a new Zep Card',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹199 — ships with a tracked NFC chip inside',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlowButton(
                  label: 'PAY ₹199 & ORDER',
                  onTap: _busy ? null : _buyNewCard,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ZepDarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.nfc_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I already have a Zep Card',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Enter or tap to read the NFC ID — no payment',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _cardName,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name on card',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nfcId,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'NFC ID (e.g. NFC004)',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 10),
                if (isAndroidDevice)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _toggleNfcRead,
                    icon: Icon(
                      _nfcListening ? Icons.stop_rounded : Icons.nfc_rounded,
                    ),
                    label: Text(_nfcListening ? 'STOP NFC READ' : 'READ VIA NFC TAP'),
                  ),
                const SizedBox(height: 10),
                GlowButton(
                  label: _busy ? 'LINKING…' : 'LINK CARD',
                  onTap: _busy ? null : _claimExisting,
                ),
              ],
            ),
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _status,
              style: TextStyle(
                color: _status.contains('success') || _status.contains('Read ')
                    ? AppColors.success
                    : AppColors.warning,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
