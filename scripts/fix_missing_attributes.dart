import 'dart:io';
import 'dart:convert';

/// Script to add missing attributes to existing collections
const String apiKey = 'standard_a9e72453979da2e7c5ee0553abcdadad9186761f20a0f8de502bdad1f4a97629e90735783512378a59e567dd551a6fc4d1342215ec97735bbd3046bbb63a13dbd049873ffbd728d8bf3201fd629edebe24ca360d3135b7cd1a573af0de8ed56edf8c7d0121d4d16eea9fcef9d41d5886b7e341bca8e708ffc79db14f6b82c57f';
const String endpoint = 'https://fra.cloud.appwrite.io/v1';
const String projectId = '6981f623001657ab0c90';
const String databaseId = 'attendance_db';

void main() async {
  print('🔧 Fixing missing attributes...\n');

  try {
    // Fix batches collection - add subjects array attribute
    print('📋 Fixing batches collection...');
    try {
      await createStringAttribute('batches', 'subjects', 255, required: true, array: true);
      print('✅ Added subjects attribute to batches\n');
    } catch (e) {
      if (e.toString().contains('already exists') || e.toString().contains('409')) {
        print('ℹ️  subjects attribute already exists in batches\n');
      } else {
        print('⚠️  Error: $e\n');
      }
    }

    // Fix attendance collection - add float attributes
    print('📋 Fixing attendance collection...');
    try {
      await createFloatAttribute('attendance', 'latitude', required: false);
      await Future.delayed(Duration(milliseconds: 500));
      await createFloatAttribute('attendance', 'longitude', required: false);
      print('✅ Added latitude and longitude attributes to attendance\n');
    } catch (e) {
      if (e.toString().contains('already exists') || e.toString().contains('409')) {
        print('ℹ️  Float attributes already exist in attendance\n');
      } else {
        print('⚠️  Error: $e\n');
      }
    }

    print('✅ Done!');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> createStringAttribute(
  String collectionId,
  String key,
  int size, {
  required bool required,
  bool array = false,
}) async {
  await makeRequest(
    'POST',
    '/databases/$databaseId/collections/$collectionId/attributes/string',
    {
      'key': key,
      'size': size,
      'required': required,
      'array': array,
    },
  );
  await Future.delayed(Duration(milliseconds: 500));
}

Future<void> createFloatAttribute(
  String collectionId,
  String key, {
  required bool required,
}) async {
  await makeRequest(
    'POST',
    '/databases/$databaseId/collections/$collectionId/attributes/float',
    {
      'key': key,
      'required': required,
    },
  );
  await Future.delayed(Duration(milliseconds: 500));
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
