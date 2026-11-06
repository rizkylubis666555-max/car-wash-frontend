import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'api_service_client.dart';

class TransaksiService {
  TransaksiService({http.Client? client})
    : _api = ApiServiceClient(client: client);

  final ApiServiceClient _api;

  Future<List<Map<String, dynamic>>> fetchTransaksi({
    required bool member,
  }) async {
    final endpoint = member ? 'transaksi/me' : 'transaksi';
    final response = await _api.get(
      endpoint,
      unavailableMessage: 'Muat ulang antrean untuk memastikan data terbaru.',
    );

    return _api.decodeList(response, 'Gagal mengambil data transaksi.');
  }

  Future<Uint8List> fetchQrisProof(int transactionId) async {
    final response = await _api.get(
      'transaksi/$transactionId/bukti-qris',
      unavailableMessage: 'Muat ulang bukti QRIS setelah koneksi pulih.',
    );
    _api.ensureStatus(response, 200, 'Gagal mengambil bukti pembayaran QRIS.');

    return response.bodyBytes;
  }

  Future<bool> inputAntrean({
    required String noPolisi,
    required String merk,
    required String? jenisKendaraan,
    required int layananId,
    required String tipePelanggan,
    required String idempotencyKey,
    int? userId,
    String? modelKendaraan,
    bool claimLoyaltyReward = false,
  }) async {
    final payload = <String, dynamic>{
      'no_polisi': noPolisi,
      'merk_kendaraan': merk,
      'layanan_id': layananId,
      'tipe_pelanggan': tipePelanggan,
      'user_id': userId,
      'claim_loyalty_reward': claimLoyaltyReward,
    };
    if (modelKendaraan != null && modelKendaraan.isNotEmpty) {
      payload['model_kendaraan'] = modelKendaraan;
    }
    if (jenisKendaraan != null) {
      payload['jenis_kendaraan'] = jenisKendaraan;
    }

    final response = await _api.postJson(
      'transaksi',
      payload,
      additionalHeaders: {'Idempotency-Key': idempotencyKey},
      unavailableMessage:
          'Data mungkin sudah tersimpan. Periksa antrean atau tekan Coba lagi dengan data yang sama.',
    );
    _api.ensureStatus(
      response,
      201,
      'Gagal memasukkan kendaraan ke antrean.',
      alsoAccept: {200},
    );

    return true;
  }

  Future<Map<String, dynamic>?> fetchPendingTransaction() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = _api.currentUserId(preferences);
    if (userId == null) {
      return null;
    }

    final savedRequest = preferences.getString('pending_transaction_$userId');
    if (savedRequest == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(savedRequest);
      if (decoded is Map<String, dynamic>) {
        final idempotencyKey = decoded['idempotency_key'];
        final noPolisi = decoded['no_polisi'];
        final merk = decoded['merk_kendaraan'];
        final jenisKendaraan = decoded['jenis_kendaraan'];
        final modelKendaraan = decoded['model_kendaraan'];
        final claimLoyaltyReward = decoded['claim_loyalty_reward'];
        final layananId = decoded['layanan_id'];
        final tipePelanggan = decoded['tipe_pelanggan'];
        if (idempotencyKey is String &&
            RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
            ).hasMatch(idempotencyKey) &&
            noPolisi is String &&
            merk is String &&
            (jenisKendaraan == null ||
                jenisKendaraan == 'motor' ||
                jenisKendaraan == 'mobil') &&
            (modelKendaraan == null || modelKendaraan is String) &&
            (claimLoyaltyReward == null || claimLoyaltyReward is bool) &&
            layananId is int &&
            (tipePelanggan == 'reguler' || tipePelanggan == 'member') &&
            (tipePelanggan != 'member' || decoded['user_id'] is int)) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } on FormatException {
      throw const ApiException(
        'Data pengiriman transaksi yang tertunda tidak dapat dibaca. Hubungi administrator sebelum mengirim ulang.',
      );
    }

    throw const ApiException(
      'Data pengiriman transaksi yang tertunda tidak valid. Hubungi administrator sebelum mengirim ulang.',
    );
  }

  Future<void> savePendingTransaction({
    required String idempotencyKey,
    required String noPolisi,
    required String merk,
    String? jenisKendaraan,
    required int layananId,
    required String tipePelanggan,
    int? userId,
    String? modelKendaraan,
    bool claimLoyaltyReward = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final cashierId = _api.currentUserId(preferences);
    if (cashierId == null) {
      throw const ApiException(
        'Sesi akun tidak valid. Masuk kembali sebelum membuat transaksi.',
      );
    }

    await preferences.setString(
      'pending_transaction_$cashierId',
      jsonEncode({
        'idempotency_key': idempotencyKey,
        'no_polisi': noPolisi,
        'merk_kendaraan': merk,
        'jenis_kendaraan': jenisKendaraan,
        'layanan_id': layananId,
        'tipe_pelanggan': tipePelanggan,
        'user_id': userId,
        'model_kendaraan': modelKendaraan,
        'claim_loyalty_reward': claimLoyaltyReward,
      }),
    );
  }

  Future<void> clearPendingTransaction() async {
    final preferences = await SharedPreferences.getInstance();
    final userId = _api.currentUserId(preferences);
    if (userId != null) {
      await preferences.remove('pending_transaction_$userId');
    }
  }

  Future<bool> cancelTransaksi(int id, String reason) async {
    final response = await _api.postJson(
      'transaksi/$id/cancel',
      {'reason': reason},
      unavailableMessage:
          'Muat ulang antrean untuk memastikan status pembatalan.',
    );
    _api.ensureStatus(response, 200, 'Gagal membatalkan transaksi.');

    return true;
  }

  Future<bool> bayarTransaksi(
    int id,
    String metodeBayar, {
    Uint8List? buktiQris,
  }) async {
    final response = metodeBayar == 'qris'
        ? await _api.sendMultipart(
            method: 'PUT',
            path: 'transaksi/$id/bayar',
            fields: {'metode_bayar': metodeBayar},
            fileField: 'bukti_qris',
            fileName: 'bukti-qris.jpg',
            fileBytes: buktiQris,
            unavailableMessage:
                'Muat ulang transaksi sebelum mengulangi konfirmasi pembayaran.',
          )
        : await _api.putJson(
            'transaksi/$id/bayar',
            {'metode_bayar': metodeBayar},
            unavailableMessage:
                'Muat ulang transaksi sebelum mengulangi konfirmasi pembayaran.',
          );
    _api.ensureStatus(response, 200, 'Gagal mengonfirmasi pembayaran.');

    return true;
  }

  Future<bool> updateStatusCuci(int id, String statusBaru) async {
    final response = await _api.putJson(
      'transaksi/$id/status-cuci',
      {'status_cucian': statusBaru},
      unavailableMessage:
          'Muat ulang antrean sebelum mengulangi perubahan status.',
    );
    _api.ensureStatus(response, 200, 'Gagal memperbarui status cucian.');

    return true;
  }

  Future<bool> assignOperator(int transactionId, int operatorId) async {
    final response = await _api.postJson(
      'transaksi/$transactionId/assign',
      {'operator_id': operatorId},
      unavailableMessage: 'Muat ulang antrean untuk memastikan penugasan.',
    );
    _api.ensureStatus(response, 200, 'Gagal menugaskan operator.');

    return true;
  }

  Future<bool> finishFromCashier(int transactionId) async {
    final response = await _api.post(
      'transaksi/$transactionId/finish',
      unavailableMessage: 'Muat ulang antrean untuk memastikan status tugas.',
    );
    _api.ensureStatus(response, 200, 'Gagal menyelesaikan tugas cucian.');

    return true;
  }

  Future<bool> unlockOperatorTask(int transactionId, String reason) async {
    final response = await _api.postJson(
      'transaksi/$transactionId/unlock',
      {'reason': reason},
      unavailableMessage: 'Muat ulang antrean untuk memastikan tugas dilepas.',
    );
    _api.ensureStatus(response, 200, 'Gagal melepas tugas operator.');

    return true;
  }
}
