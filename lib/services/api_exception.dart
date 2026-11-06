import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get hasUnknownWriteOutcome => statusCode == null || statusCode! >= 500;

  @override
  String toString() => message;

  static ApiException fromResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    String? serverMessage;
    String? validationMessage;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) {
          serverMessage = message;
        }

        final errors = body['errors'];
        if (errors is Map<String, dynamic>) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty && value.first is String) {
              validationMessage = value.first as String;
              break;
            }
          }
        }
      }
    } on FormatException {
      serverMessage = null;
    }

    if (serverMessage != null && _containsInternalDetails(serverMessage)) {
      serverMessage = null;
    }
    if (validationMessage != null &&
        _containsInternalDetails(validationMessage)) {
      validationMessage = null;
    }

    switch (response.statusCode) {
      case 401:
        if (serverMessage != null &&
            serverMessage.toLowerCase() != 'unauthenticated.') {
          return ApiException(serverMessage, statusCode: response.statusCode);
        }
        return const ApiException(
          'Sesi login sudah berakhir. Silakan masuk kembali.',
          statusCode: 401,
        );
      case 403:
        return ApiException(
          serverMessage ??
              'Akun ini tidak memiliki izin untuk melakukan tindakan tersebut.',
          statusCode: 403,
        );
      case 404:
        return ApiException(
          serverMessage ??
              'Data tidak ditemukan atau sudah dihapus. Muat ulang data.',
          statusCode: 404,
        );
      case 409:
        return ApiException(
          serverMessage ?? 'Data berubah di server. Muat ulang lalu coba lagi.',
          statusCode: 409,
        );
      case 422:
        final message = validationMessage ?? serverMessage;
        if (message != null &&
            message.toLowerCase() != 'the given data was invalid.') {
          return ApiException(message, statusCode: 422);
        }
        return ApiException(fallbackMessage, statusCode: 422);
      case 429:
        return const ApiException(
          'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
          statusCode: 429,
        );
      default:
        if (response.statusCode >= 500) {
          return const ApiException(
            'Server sedang bermasalah. Data mungkin belum tersimpan; periksa antrean sebelum mencoba lagi.',
            statusCode: 500,
          );
        }
        return ApiException(
          serverMessage ?? fallbackMessage,
          statusCode: response.statusCode,
        );
    }
  }

  static bool _containsInternalDetails(String message) {
    return RegExp(
      r'\bSQLSTATE\b|\bPDOException\b|\bIlluminate\\|\bStack trace\b|'
      r'\bselect\b.+\bfrom\b|\binsert\s+into\b|\bupdate\b.+\bset\b|'
      r'\bdelete\s+from\b',
      caseSensitive: false,
      dotAll: true,
    ).hasMatch(message);
  }
}

Future<http.Response> sendApiRequest(
  Future<http.Response> Function() request, {
  required String unavailableMessage,
}) async {
  try {
    return await request().timeout(const Duration(seconds: 20));
  } on TimeoutException {
    throw ApiException('Koneksi ke server terlalu lama. $unavailableMessage');
  } on http.ClientException {
    throw ApiException(
      'Tidak dapat terhubung ke server. Periksa jaringan dan alamat server. $unavailableMessage',
    );
  }
}
