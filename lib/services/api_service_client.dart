import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_config.dart';
import 'api_exception.dart';

class ApiServiceClient {
  ApiServiceClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri uri(String path) => Uri.parse('${ApiConfig.baseUrl}/$path');

  Future<http.Response> getUri(
    Uri uri, {
    required String unavailableMessage,
  }) async {
    return send(
      () async => _client.get(uri, headers: await headers()),
      unavailableMessage: unavailableMessage,
    );
  }

  Future<Map<String, String>> headers({bool json = false}) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');

    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> send(
    Future<http.Response> Function() request, {
    required String unavailableMessage,
  }) {
    return sendApiRequest(request, unavailableMessage: unavailableMessage);
  }

  Future<http.Response> get(
    String path, {
    required String unavailableMessage,
  }) async {
    return getUri(
      uri(path),
      unavailableMessage: unavailableMessage,
    );
  }

  Future<http.Response> postJson(
    String path,
    Map<String, dynamic> body, {
    required String unavailableMessage,
    Map<String, String> additionalHeaders = const {},
  }) async {
    return send(
      () async => _client.post(
        uri(path),
        headers: {...await headers(json: true), ...additionalHeaders},
        body: jsonEncode(body),
      ),
      unavailableMessage: unavailableMessage,
    );
  }

  Future<http.Response> post(
    String path, {
    required String unavailableMessage,
  }) async {
    return send(
      () async => _client.post(uri(path), headers: await headers()),
      unavailableMessage: unavailableMessage,
    );
  }

  Future<http.Response> putJson(
    String path,
    Map<String, dynamic> body, {
    required String unavailableMessage,
    Map<String, String> additionalHeaders = const {},
  }) async {
    return send(
      () async => _client.put(
        uri(path),
        headers: {...await headers(json: true), ...additionalHeaders},
        body: jsonEncode(body),
      ),
      unavailableMessage: unavailableMessage,
    );
  }

  Future<http.Response> delete(
    String path, {
    required String unavailableMessage,
  }) async {
    return send(
      () async => _client.delete(uri(path), headers: await headers()),
      unavailableMessage: unavailableMessage,
    );
  }

  Future<http.Response> sendMultipart({
    required String method,
    required String path,
    required Map<String, String> fields,
    required String unavailableMessage,
    String? fileField,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    return send(
      () async {
        final request = http.MultipartRequest('POST', uri(path))
          ..headers.addAll(await headers())
          ..fields.addAll(fields);
        if (method == 'PUT') {
          request.fields['_method'] = 'PUT';
        }
        if (fileField != null && fileName != null && fileBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fileField,
              fileBytes,
              filename: fileName,
            ),
          );
        }

        return http.Response.fromStream(await _client.send(request));
      },
      unavailableMessage: unavailableMessage,
    );
  }

  int? currentUserId(SharedPreferences preferences) {
    final userJson = preferences.getString('user');
    if (userJson == null) {
      return null;
    }

    try {
      final user = jsonDecode(userJson);
      final id = user is Map<String, dynamic> ? user['id'] : null;
      return id is int ? id : int.tryParse(id?.toString() ?? '');
    } on FormatException {
      return null;
    }
  }

  List<Map<String, dynamic>> decodeList(
    http.Response response,
    String fallbackMessage,
  ) {
    ensureStatus(response, 200, fallbackMessage);
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException(
        'Format data dari server tidak valid. Hubungi administrator jika masalah berlanjut.',
      );
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! List ||
        (decoded['data'] as List).any((item) => item is! Map)) {
      throw const ApiException(
        'Format data dari server tidak valid. Hubungi administrator jika masalah berlanjut.',
      );
    }

    return (decoded['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void ensureStatus(
    http.Response response,
    int expectedStatus,
    String fallbackMessage, {
    Set<int> alsoAccept = const {},
  }) {
    if (response.statusCode != expectedStatus &&
        !alsoAccept.contains(response.statusCode)) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: fallbackMessage,
      );
    }
  }
}
