import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_service_client.dart';

class MemberService {
  MemberService({http.Client? client})
    : _api = ApiServiceClient(client: client);

  final ApiServiceClient _api;

  Future<List<Map<String, dynamic>>> fetchMembers() async {
    final response = await _api.get(
      'members',
      unavailableMessage: 'Muat ulang daftar member setelah koneksi pulih.',
    );

    return _api.decodeList(response, 'Gagal mengambil daftar member.');
  }

  Future<void> updateMemberWhatsapp(int memberId, String? phoneNumber) async {
    final response = await _api.putJson(
      'members/$memberId/whatsapp',
      {'no_whatsapp': phoneNumber},
      unavailableMessage:
          'Muat ulang data member untuk memastikan perubahan nomor WhatsApp.',
    );

    _api.ensureStatus(
      response,
      200,
      'Gagal memperbarui nomor WhatsApp member.',
    );
  }

  Future<void> setMemberActive(int memberId, bool isActive) async {
    final response = await _api.putJson(
      'users/$memberId/status',
      {'is_active': isActive},
      unavailableMessage:
          'Muat ulang daftar member untuk memastikan status akun.',
    );

    _api.ensureStatus(response, 200, 'Gagal memperbarui status member.');
  }

  Future<List<Map<String, dynamic>>> fetchVehicles() async {
    final response = await _api.get(
      'kendaraan/me',
      unavailableMessage: 'Muat ulang data kendaraan setelah koneksi pulih.',
    );

    return _api.decodeList(response, 'Gagal mengambil data kendaraan.');
  }

  Future<Map<String, dynamic>> fetchMemberLoyalty(int memberId) async {
    final response = await _api.get(
      'members/$memberId/loyalty',
      unavailableMessage:
          'Muat ulang informasi promo member setelah koneksi pulih.',
    );
    _api.ensureStatus(
      response,
      200,
      'Gagal mengambil progres loyalitas member.',
    );

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
      throw const ApiException(
        'Format progres loyalitas dari server tidak valid.',
      );
    }

    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  Future<Map<String, dynamic>> fetchMyLoyalty() async {
    final response = await _api.get(
      'loyalty/me',
      unavailableMessage: 'Muat ulang progres promo setelah koneksi pulih.',
    );
    _api.ensureStatus(response, 200, 'Gagal mengambil progres promo.');

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
      throw const ApiException('Format progres promo dari server tidak valid.');
    }

    return Map<String, dynamic>.from(decoded['data'] as Map);
  }
}
