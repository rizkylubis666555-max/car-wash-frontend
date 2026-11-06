import 'package:http/http.dart' as http;

import 'api_service_client.dart';

class VehicleBrandService {
  VehicleBrandService({http.Client? client})
    : _api = ApiServiceClient(client: client);

  final ApiServiceClient _api;

  Future<List<Map<String, dynamic>>> fetchVehicleBrands() async {
    final response = await _api.get(
      'vehicle-brands',
      unavailableMessage: 'Muat ulang daftar merek setelah koneksi pulih.',
    );

    return _api.decodeList(response, 'Gagal mengambil daftar merek kendaraan.');
  }

  Future<bool> createVehicleBrand(String name) async {
    final response = await _api.postJson(
      'vehicle-brands',
      {'name': name},
      unavailableMessage: 'Muat ulang daftar merek sebelum mencoba lagi.',
    );

    _api.ensureStatus(response, 201, 'Gagal menambahkan merek kendaraan.');
    return true;
  }

  Future<bool> updateVehicleBrand(int id, String name, {bool? isActive}) async {
    final response = await _api.putJson(
      'vehicle-brands/$id',
      {'name': name, 'is_active': ?isActive},
      unavailableMessage: 'Muat ulang daftar merek untuk memastikan perubahan.',
    );

    _api.ensureStatus(response, 200, 'Gagal memperbarui merek kendaraan.');
    return true;
  }

  Future<bool> deactivateVehicleBrand(int id) async {
    final response = await _api.delete(
      'vehicle-brands/$id',
      unavailableMessage: 'Muat ulang daftar merek untuk memastikan perubahan.',
    );

    _api.ensureStatus(response, 200, 'Gagal menonaktifkan merek kendaraan.');
    return true;
  }
}
