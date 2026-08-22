import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../core/platform.dart';
import '../models/zep_card.dart';

typedef NfcTagHandler = Future<void> Function(ZepCardProfile profile);

/// Android NFC read/write for Zep Cards. Passive tags only — identity, not money.
class NfcCardService {
  NfcCardService._();
  static final instance = NfcCardService._();

  var _listening = false;

  static const _polling = {
    NfcPollingOption.iso14443,
    NfcPollingOption.iso15693,
  };

  Future<bool> isAvailable() async {
    if (!isAndroidDevice) return false;
    try {
      return await NfcManager.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<ZepCardProfile?> readProfile(NfcTag tag) async {
    final ndef = Ndef.from(tag);
    if (ndef == null) return null;
    try {
      final message = await ndef.read();
      for (final record in message.records) {
        final uri = _uriFromRecord(record);
        final profile = ZepCardCodec.parseUri(uri);
        if (profile != null) return profile;
      }
    } catch (e) {
      debugPrint('NFC read failed: $e');
    }
    return null;
  }

  Uri? _uriFromRecord(NdefRecord record) {
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
        record.type.isNotEmpty &&
        record.type[0] == 0x55 &&
        record.payload.isNotEmpty) {
      final prefixIndex = record.payload[0];
      final prefix = prefixIndex < NdefRecord.URI_PREFIX_LIST.length
          ? NdefRecord.URI_PREFIX_LIST[prefixIndex]
          : '';
      final rest = utf8.decode(record.payload.sublist(1));
      return Uri.tryParse('$prefix$rest');
    }

    final payload = record.payload;
    if (payload.isEmpty) return null;
    final text = utf8.decode(payload, allowMalformed: true);
    if (text.contains('zeppay://') || text.contains('/zeppay/profile')) {
      final start = text.contains('zeppay://')
          ? text.indexOf('zeppay://')
          : text.indexOf('https://');
      final slice = text.substring(start).split('\u0000').first.trim();
      return Uri.tryParse(slice);
    }
    return null;
  }

  /// Merchant / peer tap listener — calls [onProfile] when a Zep Card is read.
  Future<void> startListening(
    NfcTagHandler onProfile, {
    void Function(Object error)? onError,
  }) async {
    if (!isAndroidDevice || _listening) return;
    final ok = await isAvailable();
    if (!ok) {
      onError?.call(StateError('NFC not available on this device'));
      return;
    }
    _listening = true;
    await NfcManager.instance.startSession(
      pollingOptions: _polling,
      onDiscovered: (tag) async {
        try {
          final profile = await readProfile(tag);
          if (profile != null) {
            await onProfile(profile);
          }
        } catch (e) {
          onError?.call(e);
        }
      },
    );
  }

  Future<void> stopListening() async {
    if (!_listening) return;
    _listening = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  /// Write the current user's VPA + name to a blank NTAG card.
  Future<void> writeZepCard({
    required String vpa,
    required String name,
    void Function(String message)? onStatus,
  }) async {
    if (!isAndroidDevice) {
      throw UnsupportedError('Zep Card writing is Android-only');
    }
    final ok = await isAvailable();
    if (!ok) throw StateError('NFC not available');

    final completer = Completer<void>();

    await NfcManager.instance.startSession(
      pollingOptions: _polling,
      onDiscovered: (tag) async {
        try {
          onStatus?.call('Tag found — writing…');
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            throw StateError('Tag is not NDEF-compatible');
          }
          if (!ndef.isWritable) {
            throw StateError('Tag is read-only');
          }
          final message = NdefMessage([
            NdefRecord.createUri(ZepCardCodec.appUri(vpa: vpa, name: name)),
            NdefRecord.createUri(ZepCardCodec.webUri(vpa: vpa, name: name)),
          ]);
          await ndef.write(message);
          onStatus?.call('Zep Card programmed successfully');
          if (!completer.isCompleted) completer.complete();
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
    );

    onStatus?.call('Hold your Zep Card to the back of this phone…');
    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        NfcManager.instance.stopSession();
        throw TimeoutException('No tag detected — try again');
      },
    );
  }
}
