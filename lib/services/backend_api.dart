import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendApi {
  BackendApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const configuredUrl = String.fromEnvironment('FATIGUE_API_URL');
    if (configuredUrl.isNotEmpty) {
      return configuredUrl.replaceFirst(RegExp(r'/$'), '');
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://127.0.0.1:3000/api';
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    final response = switch (method) {
      'POST' => await _client
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 5)),
      'PATCH' => await _client
          .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 5)),
      'GET' => await _client.get(uri).timeout(const Duration(seconds: 5)),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    };
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        decoded['message']?.toString() ??
            'Backend request failed (${response.statusCode}).',
        uri: uri,
      );
    }
    return decoded;
  }

  Future<String> startSession({String pilotId = 'pilot-001'}) async {
    final result = await _request(
      'POST',
      '/sessions',
      body: {'pilotId': pilotId, 'notes': 'Started by Flutter app'},
    );
    return (result['data'] as Map<String, dynamic>)['_id'].toString();
  }

  Future<void> sendReading({
    required String sessionId,
    required int blinkRatePerMinute,
    required double ear,
    required String fatigueLevel,
  }) async {
    await _request('POST', '/sessions/$sessionId/readings', body: {
      'blinkRatePerMinute': blinkRatePerMinute,
      'ear': ear.clamp(0.0, 1.0),
      'fatigueLevel': fatigueLevel,
      'source': 'flutter_app',
      'recordedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendFatigueEvent({
    required String sessionId,
    required String severity,
    required String message,
    required String fatigueLevel,
  }) async {
    await _request('POST', '/events', body: {
      'sessionId': sessionId,
      'severity': severity,
      'message': message,
      'fatigueLevel': fatigueLevel,
    });
  }

  Future<void> updateSession(
    String sessionId, {
    String? status,
    String? autopilotStatus,
  }) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    if (autopilotStatus != null) body['autopilotStatus'] = autopilotStatus;
    if (body.isNotEmpty) {
      await _request('PATCH', '/sessions/$sessionId', body: body);
    }
  }

  void close() => _client.close();
}
