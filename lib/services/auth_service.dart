import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'api_service_client.dart';
import '../utils/api_config.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client() {
    _api = ApiServiceClient(client: _client);
  }

  final http.Client _client;
  late final ApiServiceClient _api;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await sendApiRequest(
      () async => _client.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ),
      unavailableMessage:
          'Periksa jaringan dan alamat server, lalu coba masuk kembali.',
    );

    if (response.statusCode != 200) {
      return {
        'success': false,
        'message': _responseMessage(response, 'Email atau password salah.'),
      };
    }

    final data = _decodeObject(response.body);
    final token = data['token'];
    final user = data['user'];
    if (token is! String || user is! Map<String, dynamic>) {
      throw const FormatException('Respons login dari server tidak lengkap.');
    }

    final userData = Map<String, dynamic>.from(user);
    await _saveSession(token, userData);

    return {'success': true, 'role': userData['role'], 'user': userData};
  }

  Future<Map<String, dynamic>> registerMember({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String noWhatsapp,
  }) async {
    final response = await sendApiRequest(
      () async => _client.post(
        Uri.parse('${ApiConfig.baseUrl}/register'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'no_whatsapp': noWhatsapp,
        }),
      ),
      unavailableMessage:
          'Periksa jaringan dan alamat server, lalu coba daftar kembali.',
    );
    if (response.statusCode != 201) {
      return {
        'success': false,
        'message': _responseMessage(response, 'Pendaftaran gagal.'),
      };
    }
    final data = _decodeObject(response.body);
    final token = data['token'];
    final user = data['user'];
    if (token is! String || user is! Map<String, dynamic>) {
      throw const FormatException(
        'Respons pendaftaran dari server tidak lengkap.',
      );
    }
    final userData = Map<String, dynamic>.from(user);
    await _saveSession(token, userData);
    return {'success': true, 'role': 'member', 'user': userData};
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? password,
    String? noWhatsapp,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sesi login tidak ditemukan. Silakan masuk kembali.',
      );
    }

    final response = await sendApiRequest(
      () async => _client.put(
        Uri.parse('${ApiConfig.baseUrl}/profile'),
        headers: {
          ..._authenticatedHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': ?(password != null && password.isNotEmpty
              ? password
              : null),
          'no_whatsapp': ?noWhatsapp,
        }),
      ),
      unavailableMessage: 'Periksa jaringan untuk memastikan perubahan profil.',
    );

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Gagal memperbarui profil.',
      );
    }

    final user = _decodeObject(response.body)['data'];
    if (user is! Map<String, dynamic> || user['role'] is! String) {
      throw const FormatException('Data profil dari server tidak valid.');
    }
    final userData = Map<String, dynamic>.from(user);
    await _saveSession(token, userData);

    return userData;
  }

  Future<Map<String, dynamic>> updateProfilePhoto(Uint8List bytes) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sesi login tidak ditemukan. Silakan masuk kembali.',
      );
    }

    final response = await _api.sendMultipart(
      method: 'POST',
      path: 'profile/photo',
      fields: const {},
      fileField: 'foto_profil',
      fileName: 'foto-profil.jpg',
      fileBytes: bytes,
      unavailableMessage:
          'Periksa jaringan untuk memastikan foto profil tersimpan.',
    );
    _api.ensureStatus(response, 200, 'Gagal memperbarui foto profil.');

    final user = _decodeObject(response.body)['data'];
    if (user is! Map<String, dynamic> || user['role'] is! String) {
      throw const FormatException('Data profil dari server tidak valid.');
    }
    final userData = Map<String, dynamic>.from(user);
    await _saveSession(token, userData);

    return userData;
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await sendApiRequest(
      () async => _client.get(
        Uri.parse('${ApiConfig.baseUrl}/user'),
        headers: _authenticatedHeaders(token),
      ),
      unavailableMessage: 'Periksa jaringan untuk memulihkan sesi.',
    );

    if (response.statusCode == 401) {
      await clearSession();
      return null;
    }
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        fallbackMessage: 'Sesi tidak dapat diperiksa.',
      );
    }

    final data = _decodeObject(response.body)['data'];
    if (data is! Map<String, dynamic> || data['role'] is! String) {
      throw const FormatException('Data sesi dari server tidak valid.');
    }

    final user = Map<String, dynamic>.from(data);
    await _saveSession(token, user);
    return user;
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');

    if (token != null && token.isNotEmpty) {
      final response = await sendApiRequest(
        () async => _client.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: _authenticatedHeaders(token),
        ),
        unavailableMessage: 'Periksa jaringan lalu coba keluar kembali.',
      );

      if (response.statusCode != 200 && response.statusCode != 401) {
        throw ApiException.fromResponse(
          response,
          fallbackMessage: 'Logout dari server gagal.',
        );
      }
    }

    await clearSession();
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('token');
    await preferences.remove('role');
    await preferences.remove('user');
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('token', token);
    await preferences.setString('role', user['role'] as String);
    await preferences.setString('user', jsonEncode(user));
  }

  Map<String, String> _authenticatedHeaders(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respons server bukan objek JSON.');
    }

    return decoded;
  }

  String _responseMessage(http.Response response, String fallback) {
    return ApiException.fromResponse(
      response,
      fallbackMessage: fallback,
    ).message;
  }
}
