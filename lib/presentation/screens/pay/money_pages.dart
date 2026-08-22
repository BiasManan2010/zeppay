import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/motion/app_motion.dart';
import '../../../core/platform.dart';
import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';
import '../../../data/local/ux_prefs.dart';
import '../../../data/services/ussd_bridge.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/local/app_store.dart';
import '../../../data/models/models.dart';
import '../../../data/services/contacts_access.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/telephony_service.dart';
import 'extra_pages.dart';

void _goPay(
  BuildContext context,
  WidgetRef ref, {
  required String vpa,
  required int amountPaise,
  required String name,
  required String source,
  String note = '',
}) {
  startPayment(
    ref,
    vpa: vpa,
    amountPaise: amountPaise,
    payeeName: name,
    source: source,
    note: note,
  );
  context.push('/pay/amount');
}

int? _paise(String raw) {
  final n = double.tryParse(raw.trim());
  if (n == null || n <= 0) return null;
  return (n * 100).round();
}

class SendHubScreen extends StatelessWidget {
  const SendHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
          children: [
            RiseIn(
              child: Text('Send', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick how the rupees should move.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _HubTile(
              icon: Icons.qr_code_2_rounded,
              title: 'Scan a QR',
              subtitle: 'Scan, enter amount, then UPI PIN',
              onTap: () => context.push('/scan'),
            ),
            _HubTile(
              icon: Icons.phone_iphone_rounded,
              title: 'Mobile number',
              subtitle: 'Pay anyone with a 10-digit number',
              onTap: () => context.push('/pay/mobile'),
            ),
            _HubTile(
              icon: Icons.alternate_email_rounded,
              title: 'UPI ID',
              subtitle: 'name@okaxis, name@ybl, and the rest',
              onTap: () => context.push('/pay/upi'),
            ),
            if (!isWebApp)
              _HubTile(
                icon: Icons.contacts_rounded,
                title: 'Phone contacts',
                subtitle: 'Pick a person, then enter amount',
                onTap: () => context.push('/pay/contacts'),
              ),
            _HubTile(
              icon: Icons.account_balance_rounded,
              title: 'Bank account',
              subtitle: 'IFSC + account number',
              onTap: () => context.push('/pay/bank'),
            ),
            _HubTile(
              icon: Icons.call_received_rounded,
              title: 'Receive money',
              subtitle: 'Your UPI QR and ID',
              onTap: () => context.push('/receive'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.hero.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: AppColors.hero),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}

class PayMobileScreen extends ConsumerStatefulWidget {
  const PayMobileScreen({super.key});

  @override
  ConsumerState<PayMobileScreen> createState() => _PayMobileScreenState();
}

class _PayMobileScreenState extends ConsumerState<PayMobileScreen> {
  final _phone = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZepPage(
      title: 'Pay to mobile',
      subtitle: isWebApp
          ? 'We append @upi if they have not shared a VPA. Then your UPI app opens.'
          : 'We append @upi if they have not shared a VPA. Same offline rails as scan.',
      footer: GlowButton(
        label: 'CONTINUE',
        onTap: () {
          final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
          if (digits.length != 10) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Need a 10-digit number')),
            );
            return;
          }
          _goPay(
            context,
            ref,
            vpa: '$digits@upi',
            amountPaise: _paise(_amount.text) ?? 0,
            name: digits,
            source: 'mobile',
          );
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'MOBILE',
              prefixText: '+91  ',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'AMOUNT (₹)'),
          ),
        ],
      ),
    );
  }
}

class PayUpiScreen extends ConsumerStatefulWidget {
  const PayUpiScreen({super.key});

  @override
  ConsumerState<PayUpiScreen> createState() => _PayUpiScreenState();
}

class _PayUpiScreenState extends ConsumerState<PayUpiScreen> {
  final _vpa = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  static const handles = ['@okaxis', '@ybl', '@paytm', '@okicici', '@oksbi'];

  @override
  void dispose() {
    _vpa.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZepPage(
      title: 'Pay to UPI ID',
      subtitle: 'Exact VPA. Nothing is typed on the USSD keypad later.',
      footer: GlowButton(
        label: 'CONTINUE',
        onTap: () {
          final vpa = _vpa.text.trim().toLowerCase();
          if (!vpa.contains('@')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Need a VPA like you@okaxis'),
              ),
            );
            return;
          }
          _goPay(
            context,
            ref,
            vpa: vpa,
            amountPaise: _paise(_amount.text) ?? 0,
            name: vpa.split('@').first,
            source: 'upi',
            note: _note.text.trim(),
          );
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          TextField(
            controller: _vpa,
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'friend@okaxis',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: handles
                .map(
                  (h) => ActionChip(
                    label: Text(h),
                    onPressed: () {
                      final name = _vpa.text.split('@').first;
                      _vpa.text = '$name$h';
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'AMOUNT (₹)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'NOTE'),
          ),
        ],
      ),
    );
  }
}

class PayContactsScreen extends ConsumerStatefulWidget {
  const PayContactsScreen({super.key});

  @override
  ConsumerState<PayContactsScreen> createState() => _PayContactsScreenState();
}

class _PayContactsScreenState extends ConsumerState<PayContactsScreen> {
  List<PhoneContact> _people = [];
  var _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (isWebApp) {
        setState(() {
          _loading = false;
          _error =
              'Safari cannot read the address book. Pay by UPI ID, or scan a QR.';
        });
        return;
      }
      if (!await ContactsAccess.request()) {
        setState(() {
          _loading = false;
          _error =
              'Contacts permission is off. Allow it, then tap Try again.';
        });
        return;
      }
      final all = await ContactsAccess.load();
      if (!mounted) return;
      ref.invalidate(phoneContactsProvider);
      setState(() {
        _people = all;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _people.where((c) {
      if (_query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return ZepPage(
      title: 'Pay a contact',
      subtitle: 'Device address book. Tap someone, then enter rupees.',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.hero),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: 16),
                    GlowButton(label: 'TRY AGAIN', onTap: _load),
                    TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('OPEN SETTINGS'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search name',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No contacts found on this phone.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final raw = c.phones.isEmpty ? '' : c.phones.first;
                      final last10 = ContactsAccess.last10(raw);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          c.displayName.isEmpty ? last10 : c.displayName,
                        ),
                        subtitle: Text(
                          last10.isEmpty ? 'No phone number' : '+91 $last10',
                        ),
                        enabled: last10.length >= 10,
                        onTap: last10.length < 10
                            ? null
                            : () => _goPay(
                                context,
                                ref,
                                vpa: '$last10@upi',
                                amountPaise: 0,
                                name: c.displayName,
                                source: 'contact',
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class PayBankScreen extends ConsumerStatefulWidget {
  const PayBankScreen({super.key});

  @override
  ConsumerState<PayBankScreen> createState() => _PayBankScreenState();
}

class _PayBankScreenState extends ConsumerState<PayBankScreen> {
  final _name = TextEditingController();
  final _acc = TextEditingController();
  final _ifsc = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _acc.dispose();
    _ifsc.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZepPage(
      title: 'Pay to bank account',
      subtitle:
          'IFSC + account. We route it as a UPI collect to the beneficiary name you type.',
      footer: GlowButton(
        label: 'CONTINUE',
        onTap: () {
          final ifsc = _ifsc.text.trim().toUpperCase();
          final acc = _acc.text.trim();
          final name = _name.text.trim();
          if (ifsc.length < 11 || acc.length < 6 || name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Name, 11-character IFSC, and account are required'),
              ),
            );
            return;
          }
          _goPay(
            context,
            ref,
            vpa: '${acc.toLowerCase()}@$ifsc'.replaceAll(' ', ''),
            amountPaise: _paise(_amount.text) ?? 0,
            name: name,
            source: 'bank',
          );
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'BENEFICIARY NAME'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _acc,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'ACCOUNT NUMBER'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ifsc,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'IFSC'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'AMOUNT (₹)'),
          ),
        ],
      ),
    );
  }
}

class BalanceScreen extends ConsumerWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(appStoreProvider).profile;
    return ZepPage(
      title: 'Linked balance',
      subtitle:
          'Shown from the account you typed at onboarding. Live UPI balance enquiry is a bank-app screen — we do not fake a refresh.',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.bankName ?? 'Bank',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                MoneyText(
                  p?.balancePaise ?? 0,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  'UPI  ${p?.upiId ?? '—'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '**** ${p?.accountLast4 ?? '••••'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (supportsOfflineRails) ...[
            GlowButton(
              label: 'CHECK VIA *99#',
              onTap: () => dialBalanceEnquiry(context, ref),
            ),
            const SizedBox(height: 10),
            GlowButton(
              label: 'MINI STATEMENT',
              onTap: () async {
                try {
                  final tel = ref.read(telephonyServiceProvider);
                  await tel.requestPermissions();
                  await tel.dial('*99#');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
            ),
          ] else
            Text(
              'Live UPI balance lives in GPay / PhonePe / your bank app. iPhone cannot run *99# from this PWA.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class OfflineRailsScreen extends ConsumerWidget {
  const OfflineRailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = ref.watch(networkInfoProvider);
    return ZepPage(
      title: 'Offline rails',
      subtitle:
          '*99# where the carrier still speaks USSD. 123PAY IVR on Jio and 4G-only SIMs.',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          net.when(
            data: (NetworkInfo info) => GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.operator.isEmpty ? 'Carrier unknown' : info.operator,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('Network  ${info.networkType}'),
                  Text(
                    'USSD  ${info.ussdSupported ? 'supported' : 'not supported'}',
                  ),
                  Text(
                    'Rail  ${info.recommendedRail.toUpperCase()}',
                    style: const TextStyle(color: AppColors.hero),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan any UPI QR. We build the dial string. You only enter UPI PIN in the dialer, then tell us if it landed.',
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _url = TextEditingController();
  final _name = TextEditingController();
  String _status = '';
  var _ussdAuto = false;
  var _ussdReady = false;

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(appStoreProvider).profile?.name ?? '';
    ref.read(otpServiceProvider).resolveUrl().then((v) {
      if (mounted) _url.text = v;
    });
    UxPrefs.ussdAutoMode().then((v) {
      if (mounted) setState(() => _ussdAuto = v);
    });
    if (isAndroidDevice) {
      UssdBridge.isAutoReady().then((v) {
        if (mounted) setState(() => _ussdReady = v);
      });
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZepPage(
      title: 'Settings',
      subtitle:
          'Your name, then the Twilio SMS proxy URL. Never paste an Auth Token.',
      footer: GlowButton(
        label: 'SAVE & PING',
        onTap: () async {
          final p = ref.read(appStoreProvider).profile;
          if (p != null && _name.text.trim().isNotEmpty) {
            await ref
                .read(appStoreProvider.notifier)
                .updateProfile(p.copyWith(name: _name.text.trim()));
          }
          await ref.read(otpServiceProvider).saveUrl(_url.text);
          final health = await ref.read(otpServiceProvider).health();
          ref.invalidate(otpLiveProvider);
          final users = health['users'];
          final reachable = health['ok'] == true || health['twilio'] == true;
          setState(
            () => _status = reachable
                ? 'Saved. Proxy up'
                      '${health['mode'] != null ? ' (${health['mode']})' : ''}'
                      '${health['supabase'] == true ? ', Supabase on' : ''}'
                      '${users is num ? ', $users accounts' : ''}.'
                : (_url.text.trim().isEmpty
                      ? 'Saved. Dev OTP 123456 until a URL is set.'
                      : 'Saved, but /health did not respond.'),
          );
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'DISPLAY NAME'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'OTP PROXY URL',
              hintText: 'https://zeppay.onrender.com',
            ),
          ),
          const SizedBox(height: 12),
          if (isAndroidDevice) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.nfc_rounded, color: AppColors.accent),
              title: const Text('Set up My Zep Card'),
              subtitle: const Text('Write your VPA to an NFC card (Challenge 1)'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/zep-card-setup'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.point_of_sale_rounded,
                  color: AppColors.accent),
              title: const Text('Merchant Mode'),
              subtitle: const Text('Turn this phone into a tap-to-pay terminal'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/merchant-mode'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto USSD mode'),
              subtitle: Text(
                _ussdReady
                    ? 'Overlay on carrier USSD or 123PAY IVR — Jio supported.'
                    : 'Enable Zep Pay USSD Assistant in Accessibility, then allow overlay.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _ussdAuto,
              onChanged: (v) async {
                if (v && !_ussdReady) {
                  await UssdBridge.openAccessibilitySettings();
                  return;
                }
                await UxPrefs.saveUssdAutoMode(v);
                if (mounted) setState(() => _ussdAuto = v);
              },
            ),
            if (!_ussdReady)
              TextButton(
                onPressed: () async {
                  await UssdBridge.openAccessibilitySettings();
                  await UssdBridge.openOverlaySettings();
                  final ready = await UssdBridge.isAutoReady();
                  if (mounted) setState(() => _ussdReady = ready);
                },
                child: const Text('OPEN ACCESSIBILITY & OVERLAY SETTINGS'),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Android 13+: Settings → Apps → Zep Pay → ⋮ → Allow restricted settings, then enable the USSD Assistant.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ),
          ],
          if (_status.isNotEmpty)
            Text(_status, style: const TextStyle(color: AppColors.hero)),
          const SizedBox(height: 20),
          Text(
            'Run backend/server.js with Twilio env plus SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY. Paste supabase/schema.sql in the Supabase SQL editor first. Never put those keys in the app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref
        .watch(appStoreProvider)
        .transactions
        .where((t) => t.status == TxStatus.success)
        .toList();
    final byDay = <String, double>{};
    for (final t in txs) {
      final k = DateFormat('d MMM').format(t.createdAt);
      byDay[k] = (byDay[k] ?? 0) + t.amountPaise / 100;
    }
    final spots = byDay.entries
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    final total = txs.fold<int>(0, (a, t) => a + t.amountPaise);
    return ZepPage(
      title: 'Spending',
      subtitle: 'Successful payments only, from this device.',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.forestCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.show_chart_rounded, color: Colors.white70),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('MMM yyyy').format(DateTime.now()),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${(total / 100).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    txs.isEmpty
                        ? 'No successful payments yet'
                        : '${txs.length} payments logged locally',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: 'BY CATEGORY',
              onTap: () => context.push('/categories'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: spots.length < 2
                  ? const Text('Pay a couple of times to see a chart.')
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppColors.accent,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStoreProvider.notifier).markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(appStoreProvider).notifications;
    return ZepPage(
      title: 'Inbox',
      child: notes.isEmpty
          ? const Center(child: Text('No alerts yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notes.length,
              itemBuilder: (context, i) {
                final n = notes[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    onTap: () {
                      final t = n.title.toLowerCase();
                      if (t.contains('payment succeeded') ||
                          t.contains('zepcoins')) {
                        context.push('/history');
                      } else if (t.contains('autopay')) {
                        context.push('/autopay');
                      } else if (t.contains('split')) {
                        context.push('/split-activity');
                      } else {
                        context.push('/requests');
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          n.body,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          DateFormat('d MMM, h:mm a').format(n.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class VerifySetupScreen extends ConsumerStatefulWidget {
  const VerifySetupScreen({super.key});

  @override
  ConsumerState<VerifySetupScreen> createState() => _VerifySetupScreenState();
}

class _VerifySetupScreenState extends ConsumerState<VerifySetupScreen> {
  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
