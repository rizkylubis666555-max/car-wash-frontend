import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_service_client.dart';

class UserManagementService {
  UserManagementService({http.Client? client})
    : _api = ApiServiceClient(client: client);

  final ApiServiceClient _api;

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final response = await _api.get(
      'users',
      unavailableMessage: 'Muat ulang daftar akun setelah koneksi pulih.',
    );

    return _api.decodeList(response, 'Gagal mengambil data user.');
  }

  Future<bool> createUser(
    String name,
    String email,
    String password,
    String role,
    String tanggalKerja,
    Uint8List fotoProfil,
  ) async {
    final response = await _api.sendMultipart(
      method: 'POST',
      path: 'users',
      fields: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'tanggal_kerja': tanggalKerja,
      },
      fileField: 'foto_profil',
      fileName: 'foto-profil.jpg',
      fileBytes: fotoProfil,
      unavailableMessage: 'Muat ulang daftar akun sebelum mengulang pembuatan.',
    );

    _api.ensureStatus(response, 201, 'Gagal membuat akun.');
    return true;
  }

  Future<bool> updateUser(
    int id, {
    required String name,
    required String email,
    required String role,
    required bool isActive,
    String? password,
    String? tanggalKerja,
    String? noWhatsapp,
    Uint8List? fotoProfil,
  }) async {
    final response = await _api.sendMultipart(
      method: 'PUT',
      path: 'users/$id',
      fields: {
        'name': name,
        'email': email,
        'role': role,
        'is_active': isActive ? '1' : '0',
        'password': ?(password != null && password.isNotEmpty ? password : null),
        'tanggal_kerja': ?tanggalKerja,
        'no_whatsapp': ?noWhatsapp,
      },
      fileField: fotoProfil == null ? null : 'foto_profil',
      fileName: fotoProfil == null ? null : 'foto-profil.jpg',
      fileBytes: fotoProfil,
      unavailableMessage: 'Muat ulang daftar akun untuk memastikan perubahan.',
    );

    _api.ensureStatus(response, 200, 'Gagal memperbarui akun.');
    return true;
  }

  Future<bool> deleteUser(int id) async {
    final response = await _api.delete(
      'users/$id',
      unavailableMessage:
          'Muat ulang daftar akun untuk memastikan penghapusan.',
    );

    _api.ensureStatus(response, 200, 'Gagal menghapus akun.');
    return true;
  }
}
