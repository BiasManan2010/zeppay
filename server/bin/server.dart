import 'dart:convert';
import 'dart:io';

/// Twilio Verify proxy + JSON sync store.
///
///   set TWILIO_ACCOUNT_SID=...
///   set TWILIO_AUTH_TOKEN=...
///   set TWILIO_VERIFY_SID=...
///   dart run server/bin/server.dart
///
/// Then run the app with:
///   flutter run --dart-define=TWILIO_VERIFY_URL=http://YOUR_LAN_IP:8787
Future<void> main() async {
  final sid = Platform.environment['TWILIO_ACCOUNT_SID'] ?? '';
  final token = Platform.environment['TWILIO_AUTH_TOKEN'] ?? '';
  final service = Platform.environment['TWILIO_VERIFY_SID'] ?? '';
  final store = <String, Map<String, dynamic>>{};

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8787);
  stdout.writeln('Zep Pay API on http://${server.address.address}:${server.port}');

  await for (final req in server) {
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
        _json(req, {'ok': true, 'twilio': sid.isNotEmpty});
      } else if (req.method == 'POST' && path == '/verify/start') {
        final body = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
        final phone = body['phone'] as String? ?? '';
        if (sid.isEmpty) {
          _json(req, {'dev': true, 'hint': '123456'});
          continue;
        }
        final auth = base64Encode(utf8.encode('$sid:$token'));
        final client = HttpClient();
        final twilio = await client.postUrl(
          Uri.parse('https://verify.twilio.com/v2/Services/$service/Verifications'),
        );
        twilio.headers.set(HttpHeaders.authorizationHeader, 'Basic $auth');
        twilio.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
        twilio.write('To=${Uri.encodeQueryComponent(phone)}&Channel=sms');
        final res = await twilio.close();
        _json(req, {'status': res.statusCode});
        client.close();
      } else if (req.method == 'POST' && path == '/verify/check') {
        final body = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
        final phone = body['phone'] as String? ?? '';
        final code = body['code'] as String? ?? '';
        if (sid.isEmpty) {
          _json(req, {'approved': code == '123456'});
          continue;
        }
        final auth = base64Encode(utf8.encode('$sid:$token'));
        final client = HttpClient();
        final twilio = await client.postUrl(
          Uri.parse('https://verify.twilio.com/v2/Services/$service/VerificationCheck'),
        );
        twilio.headers.set(HttpHeaders.authorizationHeader, 'Basic $auth');
        twilio.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
        twilio.write(
          'To=${Uri.encodeQueryComponent(phone)}&Code=${Uri.encodeQueryComponent(code)}',
        );
        final res = await twilio.close();
        final text = await utf8.decodeStream(res);
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        _json(req, {'approved': parsed['status'] == 'approved'});
        client.close();
      } else if (req.method == 'POST' && path.startsWith('/sync/')) {
        final phone = path.split('/').last;
        store[phone] = jsonDecode(await utf8.decodeStream(req)) as Map<String, dynamic>;
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

void _json(HttpRequest req, Object body) {
  req.response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Headers', 'Content-Type')
    ..contentType = ContentType.json;
  req.response.write(jsonEncode(body));
  req.response.close();
}
