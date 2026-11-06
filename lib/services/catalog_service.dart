import 'package:http/http.dart' as http;

import 'api_service_client.dart';

class CatalogService {
  CatalogService({http.Client? client})
    : _api = ApiServiceClient(client: client);

  final ApiServiceClient _api;

  Future<List<Map<String, dynamic>>> fetchLayanan({
    String? jenisKendaraan,
  }) async {
    final uri = _api.uri('layanan').replace(
      queryParameters: jenisKendaraan == null
          ? null
          : {'jenis_kendaraan': jenisKendaraan},
    );
    final response = await _api.getUri(
      uri,
      unavailableMessage:
          'Muat ulang daftar layanan setelah koneksi pulih.',
    );

    return _api.decodeList(response, 'Gagal mengambil data layanan.');
  }

  Future<List<Map<String, dynamic>>> fetchPromos() async {
    final response = await _api.get(
      'promos',
      unavailableMessage: 'Muat ulang daftar promo setelah koneksi pulih.',
    );

    return _api.decodeList(response, 'Gagal mengambil data promo.');
  }

  Future<bool> createLayanan(
    String namaLayanan,
    String jenisKendaraan,
    int harga,
  ) async {
    final response = await _api.postJson(
      'layanan',
      {
        'nama_layanan': namaLayanan,
        'jenis_kendaraan': jenisKendaraan,
        'harga': harga,
      },
      unavailableMessage: 'Muat ulang daftar layanan sebelum mencoba lagi.',
    );

    _api.ensureStatus(response, 201, 'Gagal menambahkan layanan.');
    return true;
  }

  Future<bool> updateLayanan(
    int id,
    String namaLayanan,
    String jenisKendaraan,
    int harga, {
    bool isActive = true,
  }) async {
    final response = await _api.putJson(
      'layanan/$id',
      {
        'nama_layanan': namaLayanan,
        'jenis_kendaraan': jenisKendaraan,
        'harga': harga,
        'is_active': isActive,
      },
      unavailableMessage: 'Muat ulang daftar layanan untuk memastikan perubahan.',
    );

    _api.ensureStatus(response, 200, 'Gagal memperbarui layanan.');
    return true;
  }

  Future<bool> deleteLayanan(int id) async {
    final response = await _api.delete(
      'layanan/$id',
      unavailableMessage:
          'Muat ulang daftar layanan untuk memastikan penghapusan.',
    );

    _api.ensureStatus(response, 200, 'Gagal menghapus layanan.');
    return true;
  }

  Future<bool> createPromo(String name, bool isActive) async {
    final response = await _api.postJson(
      'promos',
      {'name': name, 'is_active': isActive},
      unavailableMessage: 'Muat ulang daftar promo sebelum mencoba lagi.',
    );

    _api.ensureStatus(response, 201, 'Gagal menambahkan promo.');
    return true;
  }

  Future<bool> updatePromo(int id, String name, bool isActive) async {
    final response = await _api.putJson(
      'promos/$id',
      {'name': name, 'is_active': isActive},
      unavailableMessage: 'Muat ulang daftar promo untuk memastikan perubahan.',
    );

    _api.ensureStatus(response, 200, 'Gagal memperbarui promo.');
    return true;
  }
}
