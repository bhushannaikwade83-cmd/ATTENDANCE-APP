import 'dart:io';
import 'dart:convert';

/// Script to create Appwrite Storage Bucket
const String apiKey = 'standard_a9e72453979da2e7c5ee0553abcdadad9186761f20a0f8de502bdad1f4a97629e90735783512378a59e567dd551a6fc4d1342215ec97735bbd3046bbb63a13dbd049873ffbd728d8bf3201fd629edebe24ca360d3135b7cd1a573af0de8ed56edf8c7d0121d4d16eea9fcef9d41d5886b7e341bca8e708ffc79db14f6b82c57f';
const String endpoint = 'https://fra.cloud.appwrite.io/v1';
const String projectId = '6981f623001657ab0c90';
const String bucketId = 'photos_bucket';

void main() async {
  print('🚀 Setting up Appwrite Storage Bucket...\n');

  try {
    // Create storage bucket
    print('📦 Creating storage bucket: $bucketId');
    try {
      await makeRequest(
        'POST',
        '/storage/buckets',
        {
          'bucketId': bucketId,
          'name': 'Attendance Photos Bucket',
          'enabled': true,
          'maximumFileSize': 10485760, // 10 MB
          'allowedFileExtensions': ['jpg', 'jpeg', 'png'],
          'compression': 'none',
          'encryption': false,
          'antivirus': false,
          'fileSecurity': false,
          'permissions': [
            'read("users")',
            'create("users")',
            'update("users")',
            'delete("users")',
          ],
        },
      );
      print('✅ Storage bucket created successfully!\n');
    } catch (e) {
      if (e.toString().contains('already exists') || 
          e.toString().contains('409') ||
          e.toString().contains('maximum number')) {
        print('ℹ️  Storage bucket already exists, continuing...\n');
      } else {
        rethrow;
      }
    }

    print('📁 Storage Structure:');
    print('   institute_id/');
    print('     batch_year/');
    print('       rollNumber/');
    print('         subject/');
    print('           YYYY-MM-DD/');
    print('             photo.jpg');
    print('\n✅ Storage setup complete!');
  } catch (e) {
    print('\n❌ Error: $e');
    exit(1);
  }
}

Future<Map<String, dynamic>> makeRequest(
  String method,
  String path,
  Map<String, dynamic> body,
) async {
  final url = Uri.parse('$endpoint$path');
  final client = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;

  try {
    final request = await client.openUrl(method, url);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('X-Appwrite-Project', projectId);
    request.headers.set('X-Appwrite-Key', apiKey);

    if (method == 'POST' || method == 'PUT') {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) {
        return {};
      }
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(responseBody) as Map<String, dynamic>;
      throw Exception('HTTP ${response.statusCode}: ${error['message'] ?? responseBody}');
    }
  } finally {
    client.close();
  }
}
