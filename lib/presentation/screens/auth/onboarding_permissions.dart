import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/services/providers.dart';
import '../../../data/services/ussd_bridge.dart';

class OnboardingPermissionsPanel extends ConsumerStatefulWidget {
  const OnboardingPermissionsPanel({
    super.key,
    required this.onReadyChanged,
  });

  final ValueChanged<bool> onReadyChanged;

  @override
  ConsumerState<OnboardingPermissionsPanel> createState() =>
      _OnboardingPermissionsPanelState();
}

class _OnboardingPermissionsPanelState
    extends ConsumerState<OnboardingPermissionsPanel> {
  var _camera = false;
  var _phone = false;
  var _notifications = false;
  var _autoReady = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (isAndroidDevice) {
      final cam = await Permission.camera.isGranted;
      final tel = ref.read(telephonyServiceProvider);
      final phone = await tel.hasCallPermission();
      final notif = await Permission.notification.isGranted;
      final auto = await UssdBridge.isAutoReady();
      if (!mounted) return;
      setState(() {
        _camera = cam;
        _phone = phone;
        _notifications = notif;
        _autoReady = auto;
      });
    } else if (isWebApp) {
      setState(() => _camera = true);
    } else {
      final cam = await Permission.camera.isGranted;
      if (!mounted) return;
      setState(() => _camera = cam);
    }
    _emitReady();
  }

  void _emitReady() {
    if (isAndroidDevice) {
      widget.onReadyChanged(_camera && _phone);
    } else {
      widget.onReadyChanged(_camera);
    }
  }

  Future<void> _grantCamera() async {
    setState(() => _busy = true);
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _camera = status.isGranted;
        _busy = false;
      });
      _emitReady();
    }
  }

  Future<void> _grantPhone() async {
    setState(() => _busy = true);
    final tel = ref.read(telephonyServiceProvider);
    await tel.requestPermissions();
    final ok = await tel.hasCallPermission();
    if (mounted) {
      setState(() {
        _phone = ok;
        _busy = false;
      });
      _emitReady();
    }
  }

  Future<void> _grantNotifications() async {
    setState(() => _busy = true);
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() {
        _notifications = status.isGranted;
        _busy = false;
      });
    }
  }

  Future<void> _openAutoSetup() async {
    await UssdBridge.openAccessibilitySettings();
    await UssdBridge.openOverlaySettings();
    final ready = await UssdBridge.isAutoReady();
    if (mounted) setState(() => _autoReady = ready);
  }

  @override
  Widget build(BuildContext context) {
    if (isIosWeb) {
      return const GlassPanel(
        child: Text(
          'On iPhone, use the Zep Pay website (Add to Home Screen). '
          'Payments open GPay / PhonePe — Jio included.',
          style: TextStyle(color: AppColors.textPrimary, height: 1.45),
        ),
      );
    }

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAndroidDevice
                ? 'Grant these before your first payment. Jio uses 123PAY IVR; other SIMs use *99#.'
                : 'Allow camera so you can scan QR codes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          if (isAndroidDevice) ...[
            _PermTile(
              title: 'Camera',
              subtitle: 'Scan UPI QR codes',
              granted: _camera,
              onGrant: _busy ? null : _grantCamera,
            ),
            _PermTile(
              title: 'Phone',
              subtitle: 'Dial *99# USSD or 123PAY on Jio',
              granted: _phone,
              onGrant: _busy ? null : _grantPhone,
            ),
            _PermTile(
              title: 'Notifications',
              subtitle: 'Autopay reminders (optional)',
              granted: _notifications,
              optional: true,
              onGrant: _busy ? null : _grantNotifications,
            ),
            _PermTile(
              title: 'Auto USSD overlay',
              subtitle: _autoReady
                  ? 'Ready — works on Jio (IVR) and other carriers (USSD)'
                  : 'Optional: Accessibility + overlay in Settings',
              granted: _autoReady,
              optional: true,
              onGrant: _busy ? null : _openAutoSetup,
              actionLabel: 'OPEN SETTINGS',
            ),
          ] else
            _PermTile(
              title: 'Camera',
              subtitle: 'Scan UPI QR codes',
              granted: _camera,
              onGrant: _busy ? null : _grantCamera,
            ),
        ],
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  const _PermTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onGrant,
    this.optional = false,
    this.actionLabel = 'ALLOW',
  });

  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback? onGrant;
  final bool optional;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: granted ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  optional ? '$title (optional)' : title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          if (!granted && onGrant != null)
            TextButton(onPressed: onGrant, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
