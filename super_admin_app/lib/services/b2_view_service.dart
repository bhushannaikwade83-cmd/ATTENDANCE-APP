import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';

class B2ViewService {
  static final Map<String, ({String url, DateTime expiresAt})> _urlCache = {};

  static Future<String> getTemporaryDownloadUrl(String objectPath) async {
    final cached = _urlCache[objectPath];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Missing Firebase ID token');
    }

    final response = await http.post(
      Uri.parse('${BackendConfig.b2ProxyBaseUrl}/b2GetDownloadUrl'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'objectPath': objectPath,
        'validForSeconds': 1200,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('B2 view URL failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = (data['downloadUrl'] ?? '').toString();
    if (url.isNotEmpty) {
      _urlCache[objectPath] = (
        url: url,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );
    }
    return url;
  }
}
