import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import '../errors/exception.dart' as exceptions;
import 'cloud_storage_service.dart';
import 'storage_service.dart';

class HttpClient {
  final http.Client _client = http.Client();

  String get baseUrl => 'https://api.fed-tms.com/v1'; // TODO: Make configurable

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = null; // TODO: Implement token storage
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final body = jsonDecode(response.body);
      print('GET $endpoint: ${response.statusCode}');
      return body;
    } catch (e) {
      print('GET $endpoint error: $e');
      throw Exception('GET request failed: $e');
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      print('POST $endpoint: ${response.statusCode}');
      return body;
    } catch (e) {
      print('POST $endpoint error: $e');
      throw Exception('POST request failed: $e');
    }
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      print('PUT $endpoint: ${response.statusCode}');
      return body;
    } catch (e) {
      print('PUT $endpoint error: $e');
      throw Exception('PUT request failed: $e');
    }
  }

  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );

      final body = jsonDecode(response.body);
      print('DELETE $endpoint: ${response.statusCode}');
      return body;
    } catch (e) {
      print('DELETE $endpoint error: $e');
      throw Exception('DELETE request failed: $e');
    }
  }

  /// Upload file
  Future<Map<String, dynamic>> uploadFile(
      String endpoint, String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      final file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);
      request.headers.addAll(_headers);

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      final body = jsonDecode(response.body);
      print('UPLOAD $endpoint: ${response.statusCode}');
      return body;
    } catch (e) {
      print('UPLOAD $endpoint error: $e');
      throw Exception('File upload failed: $e');
    }
  }

  /// Download file
  Future<String> downloadFile(String url, String savePath) async {
    try {
      final response = await _client.get(Uri.parse(url));
      final file = await File(savePath).writeAsBytes(response.bodyBytes);
      print('DOWNLOAD $url: ${response.statusCode}');
      return file.path;
    } catch (e) {
      print('DOWNLOAD $url error: $e');
      throw Exception('File download failed: $e');
    }
  }

  /// Close HTTP client
  void dispose() {
    _client.close();
  }
}
