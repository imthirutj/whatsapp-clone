import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    final message = body is Map ? (body['message']?.toString() ?? 'Request failed') : 'Request failed';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> get(String path) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$kBaseUrl$path'),
      headers: headers,
    );
    _handleResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$kBaseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    _handleResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http.put(
      Uri.parse('$kBaseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    _handleResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final headers = await _headers();
    final response = await http.patch(
      Uri.parse('$kBaseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    _handleResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  // Upload media bytes cross-platform (web + mobile), returns mediaId
  Future<String> uploadMedia(Uint8List bytes, String filename, String mimeType) async {
    final token = await _storage.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/media'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Upload failed', statusCode: response.statusCode);
    }
    final body = jsonDecode(response.body);
    return body['mediaId'] as String;
  }

  // Fetch raw media bytes for a given mediaId
  Future<List<int>> fetchMediaBytes(String mediaId) async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('$kBaseUrl/media/$mediaId'),
      headers: { if (token != null) 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Failed to load media', statusCode: response.statusCode);
    }
    return response.bodyBytes;
  }

  Future<dynamic> delete(String path) async {
    final headers = await _headers();
    final response = await http.delete(
      Uri.parse('$kBaseUrl$path'),
      headers: headers,
    );
    _handleResponse(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
