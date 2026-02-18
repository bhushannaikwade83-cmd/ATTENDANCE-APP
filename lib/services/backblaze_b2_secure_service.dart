import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../firebase_backend_config.dart';

class BackblazeB2SecureService {
  static Future<String> uploadFile({
    required String objectPath,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final idToken = await _getIdToken();
    final uploadAuth = await _getUploadAuthorization(
      idToken: idToken,
      objectPath: objectPath,
      contentType: contentType,
    );

    final sha1Hash = sha1.convert(bytes).toString();
    final response = await http.post(
      Uri.parse(uploadAuth.uploadUrl),
      headers: {
        'Authorization': uploadAuth.authorizationToken,
        'X-Bz-File-Name': _encodePath(uploadAuth.fileName),
        'Content-Type': contentType,
        'X-Bz-Content-Sha1': sha1Hash,
      },
      body: bytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'B2 upload failed (${response.statusCode}): ${response.body}',
      );
    }

    return objectPath;
  }

  static Future<String> getTemporaryDownloadUrl({
    required String objectPath,
    int validForSeconds = 600,
  }) async {
    final idToken = await _getIdToken();
    final endpoint =
        '${FirebaseBackendConfig.backblazeProxyBaseUrl}/b2GetDownloadUrl';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'objectPath': objectPath,
        'validForSeconds': validForSeconds,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Could not get temporary download URL (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['downloadUrl'] ?? '').toString();
  }

  static Future<_UploadAuthorization> _getUploadAuthorization({
    required String idToken,
    required String objectPath,
    required String contentType,
  }) async {
    final endpoint =
        '${FirebaseBackendConfig.backblazeProxyBaseUrl}/b2GetUploadUrl';
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'objectPath': objectPath,
        'contentType': contentType,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Could not get upload authorization (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _UploadAuthorization(
      uploadUrl: (data['uploadUrl'] ?? '').toString(),
      authorizationToken: (data['authorizationToken'] ?? '').toString(),
      fileName: (data['fileName'] ?? objectPath).toString(),
    );
  }

  static Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    // Force refresh to avoid expired/stale token causing 401 from function.
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Missing Firebase ID token');
    }
    return token;
  }

  static String _encodePath(String path) {
    return path.split('/').map(Uri.encodeComponent).join('/');
  }
}

class _UploadAuthorization {
  final String uploadUrl;
  final String authorizationToken;
  final String fileName;

  _UploadAuthorization({
    required this.uploadUrl,
    required this.authorizationToken,
    required this.fileName,
  });
}
