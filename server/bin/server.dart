import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Twilio OTP proxy (Messaging Service or Verify) + JSON sync store.
///
///   TWILIO_ACCOUNT_SID=ACxx
///   TWILIO_AUTH_TOKEN=xx
///   TWILIO_MESSAGING_SERVICE_SID=MGxx
///   dart run server/bin/server.dart
Future<void> main() async {
  final sid = Platform.environment['TWILIO_ACCOUNT_SID'] ?? '';
  final token = Platform.environment['TWILIO_AUTH_TOKEN'] ?? '';
  final verifySid = Platform.environment['TWILIO_VERIFY_SID'] ?? '';
  final messagingSid = Platform.environment['TWILIO_MESSAGING_SERVICE_SID'] ?? '';
  final fromNumber = Platform.environment['TWILIO_FROM'] ?? '';
  final useVerify = sid.isNotEmpty && token.isNotEmpty && verifySid.isNotEmpty;
  final useSms =
      sid.isNotEmpty &&
      token.isNotEmpty &&
      (messagingSid.isNotEmpty || fromNumber.isNotEmpty);
  final store = <String, Map<String, dynamic>>{};
  final otps = <String, ({String code, DateTime exp})>{};

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8787);
  stdout.writeln(
    'Zep Pay API on :${server.port} (${useVerify
        ? 'verify'
        : useSms
        ? 'messaging'
        : 'dev'})',
  );

  await for (final req in server) {
    // Add CORS headers for all responses
    req.response.headers.set('Access-Control-Allow-Origin', '*');
    req.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    req.response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
    
    // Handle preflight
    if (req.method == 'OPTIONS') {
      req.response.statusCode = 200;
      await req.response.close();
      continue;
    }
    
    try {
      final path = req.uri.path;
      if (req.method == 'OPTIONS') {
        req.response.headers
          ..set('Access-Control-Allow-Origin', '*')
          ..set('Access-Control-Allow-Headers', 'Content-Type')
          ..set('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
        req.response.statusCode = 204;
        await req.response.close();
      } else if (req.method == 'GET' && path == '/health') {
        _json(req, {
          'ok': true,
          'twilio': useVerify || useSms,
          'mode': useVerify
              ? 'verify'
              : useSms
              ? 'messaging'
              : 'dev',
        });
      } else if (req.method == 'POST' && path == '/verify/start') {
        final body =
            jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
        final phone = _e164(body['phone'] as String? ?? '');
        if (phone.isEmpty) {
          _json(req, {'error': 'phone required'}, status: 400);
          continue;
        }
        if (!useVerify && !useSms) {
          _json(req, {'ok': true, 'dev': true, 'hint': '123456'});
          continue;
        }
        final auth = base64Encode(utf8.encode('$sid:$token'));
        final client = HttpClient();
        if (useVerify) {
          final twilio = await client.postUrl(
            Uri.parse(
              'https://verify.twilio.com/v2/Services/$verifySid/Verifications',
            ),
          );
          twilio.headers.set(HttpHeaders.authorizationHeader, 'Basic $auth');
          twilio.headers.contentType = ContentType(
            'application',
            'x-www-form-urlencoded',
          );
          twilio.write(
            'To=${Uri.encodeQueryComponent(phone)}&Channel=sms',
          );
          final res = await twilio.close();
          _json(req, {'ok': res.statusCode < 400, 'status': res.statusCode});
        } else {
          final code = (100000 + Random.secure().nextInt(900000)).toString();
          otps[phone] = (code: code, exp: DateTime.now().add(const Duration(minutes: 10)));
          final twilio = await client.postUrl(
            Uri.parse(
              'https://api.twilio.com/2010-04-01/Accounts/$sid/Messages.json',
            ),
          );
          twilio.headers.set(HttpHeaders.authorizationHeader, 'Basic $auth');
          twilio.headers.contentType = ContentType(
            'application',
            'x-www-form-urlencoded',
          );
          final fields = <String>[
            'To=${Uri.encodeQueryComponent(phone)}',
            'Body=${Uri.encodeQueryComponent('Zep Pay code $code. Valid 10 minutes. Do not share it.')}',
          ];
          if (messagingSid.isNotEmpty) {
            fields.add(
              'MessagingServiceSid=${Uri.encodeQueryComponent(messagingSid)}',
            );
          } else {
            fields.add('From=${Uri.encodeQueryComponent(fromNumber)}');
          }
          twilio.write(fields.join('&'));
          final res = await twilio.close();
          final text = await utf8.decodeStream(res);
          if (res.statusCode >= 400) {
            _json(req, {'error': text}, status: res.statusCode);
          } else {
            _json(req, {'ok': true, 'mode': 'messaging'});
          }
        }
        client.close();
      } else if (req.method == 'POST' && path == '/verify/check') {
        final body =
            jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
        final phone = _e164(body['phone'] as String? ?? '');
        final code = body['code'] as String? ?? '';
        if (!useVerify && !useSms) {
          _json(req, {'approved': code == '123456'});
          continue;
        }
        if (useVerify) {
          final auth = base64Encode(utf8.encode('$sid:$token'));
          final client = HttpClient();
          final twilio = await client.postUrl(
            Uri.parse(
              'https://verify.twilio.com/v2/Services/$verifySid/VerificationCheck',
            ),
          );
          twilio.headers.set(HttpHeaders.authorizationHeader, 'Basic $auth');
          twilio.headers.contentType = ContentType(
            'application',
            'x-www-form-urlencoded',
          );
          twilio.write(
            'To=${Uri.encodeQueryComponent(phone)}&Code=${Uri.encodeQueryComponent(code)}',
          );
          final res = await twilio.close();
          final text = await utf8.decodeStream(res);
          final parsed = jsonDecode(text) as Map<String, dynamic>;
          _json(req, {'approved': parsed['status'] == 'approved'});
          client.close();
        } else {
          final row = otps[phone];
          final approved =
              row != null &&
              DateTime.now().isBefore(row.exp) &&
              row.code == code;
          if (approved) otps.remove(phone);
          _json(req, {
            'approved': approved,
            'status': approved ? 'approved' : 'pending',
          });
        }
      } else if (req.method == 'POST' && path.startsWith('/sync/')) {
        final phone = path.split('/').last;
        store[phone] =
            jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
        _json(req, {'ok': true});
      } else if (req.method == 'GET' && path.startsWith('/sync/')) {
        final phone = path.split('/').last;
        _json(req, store[phone] ?? {});
      } else {
        req.response.statusCode = 404;
        await req.response.close();
      }
    } catch (e) {
      req.response.statusCode = 500;
      req.response.write('$e');
      await req.response.close();
    }
  }
}

String _e164(String phone) {
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.length == 10) return '+91$d';
  if (d.startsWith('91') && d.length == 12) return '+$d';
  if (phone.startsWith('+')) return phone;
  return d.isEmpty ? '' : '+$d';
}

void _json(HttpRequest req, Object body, {int status = 200}) {
  req.response.statusCode = status;
  req.response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Headers', 'Content-Type')
    ..contentType = ContentType.json;
  req.response.write(jsonEncode(body));
  req.response.close();
}
