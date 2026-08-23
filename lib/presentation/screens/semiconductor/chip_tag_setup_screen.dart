import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chrome.dart';
import '../../../data/models/chip_tag_codec.dart';
import '../../../data/services/nfc_card_service.dart';
import '../../../data/services/semiconductor_repository.dart';

class ChipTagSetupScreen extends ConsumerStatefulWidget {
  const ChipTagSetupScreen({super.key});

  @override
  ConsumerState<ChipTagSetupScreen> createState() => _ChipTagSetupScreenState();
}

class _ChipTagSetupScreenState extends ConsumerState<ChipTagSetupScreen> {
  String? _selectedNfcId;
  var _busy = false;
  var _nfcOk = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  Future<void> _checkNfc() async {
    final ok = await NfcCardService.instance.isAvailable();
    if (mounted) setState(() => _nfcOk = ok);
  }

  Future<void> _write() async {
    final nfcId = _selectedNfcId;
    if (nfcId == null) {
      setState(() => _status = 'Pick a demo batch tag first.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Ready to write…';
    });
    try {
      await NfcCardService.instance.writeChipTag(
        nfcId: nfcId,
        onStatus: (m) {
          if (mounted) setState(() => _status = m);
        },
      );
      if (mounted) {
        setState(
          () => _status = 'Tag programmed — tap it to open chip inventory.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(nfcTagsProvider);

    return ZepPage(
      title: 'Write chip batch tag',
      subtitle:
          'Same NFC flow as Zep Card setup — payload points at inventory, not a person',
      child: tags.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (list) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              if (!isAndroidDevice)
                const Text(
                  'NFC tag writing requires Android hardware.',
                  style: TextStyle(color: AppColors.warning),
                ),
              ...list.map(
                (t) => RadioListTile<String>(
                  value: t.nfcId,
                  groupValue: _selectedNfcId,
                  title: Text(
                    t.nfcId,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Chip ${t.chipId} · batch ${t.batchId}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _selectedNfcId = v),
                ),
              ),
              if (_selectedNfcId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Will write: ${ChipTagCodec.appUri(nfcId: _selectedNfcId!)}',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: !_nfcOk || _busy ? null : _write,
                icon: const Icon(Icons.nfc_rounded),
                label: Text(_busy ? 'Writing…' : 'Write to NFC tag'),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_status, style: const TextStyle(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.push('/inventory-overview'),
                child: const Text('Open inventory list'),
              ),
            ],
          );
        },
      ),
    );
  }
}
