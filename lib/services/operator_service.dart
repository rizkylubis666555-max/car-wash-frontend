import 'package:http/http.dart' as http;

import 'api_service_client.dart';

class OperatorService {
  OperatorService({http.Client? client})
    : _api = ApiServiceClient(client: client);

  final ApiServiceClient _api;

  Future<List<Map<String, dynamic>>> fetchOperators() async {
    final response = await _api.get(
      'operators',
      unavailableMessage: 'Muat ulang status operator setelah koneksi pulih.',
    );

    return _api.decodeList(response, 'Gagal mengambil status operator.');
  }
}
