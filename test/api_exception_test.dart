import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berkah_mobile/providers/transaksi_provider.dart';
import 'package:berkah_mobile/services/api_exception.dart';
import 'package:berkah_mobile/services/transaksi_service.dart';
import 'package:berkah_mobile/services/vehicle_brand_service.dart';

void main() {
  group('ApiException', () {
    test(
      'shows a useful validation error instead of the generic server text',
      () {
        final exception = ApiException.fromResponse(
          http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'email': ['Format email tidak valid.'],
              },
            }),
            422,
          ),
          fallbackMessage: 'Permintaan gagal.',
        );

        expect(exception.statusCode, 422);
        expect(exception.message, 'Format email tidak valid.');
      },
    );

    test('explains that an expired session requires signing in again', () {
      final exception = ApiException.fromResponse(
        http.Response('{"message":"Unauthenticated."}', 401),
        fallbackMessage: 'Permintaan gagal.',
      );

      expect(
        exception.message,
        'Sesi login sudah berakhir. Silakan masuk kembali.',
      );
    });

    test('does not expose internal server details', () {
      final exception = ApiException.fromResponse(
        http.Response('{"message":"SQL connection password failed"}', 500),
        fallbackMessage: 'Permintaan gagal.',
      );

      expect(exception.message, contains('Server sedang bermasalah'));
      expect(exception.message, isNot(contains('password')));
    });

    test('does not display SQL details returned in an error response', () {
      final exception = ApiException.fromResponse(
        http.Response(
          jsonEncode({
            'message': 'SQLSTATE[42S02]: Table not found: select * from users',
          }),
          404,
        ),
        fallbackMessage: 'Gagal memuat data.',
      );

      expect(exception.message, contains('Data tidak ditemukan'));
      expect(exception.message, isNot(contains('SQLSTATE')));
      expect(exception.message, isNot(contains('select * from')));
    });

    test('identifies writes whose server outcome must be verified', () {
      expect(ApiException('timeout').hasUnknownWriteOutcome, isTrue);
      expect(
        ApiException('server error', statusCode: 500).hasUnknownWriteOutcome,
        isTrue,
      );
      expect(
        ApiException('invalid input', statusCode: 422).hasUnknownWriteOutcome,
        isFalse,
      );
    });

    test('explains a timeout and suggests the next step', () async {
      await expectLater(
        sendApiRequest(
          () => Future<http.Response>.error(
            TimeoutException('request timed out'),
          ),
          unavailableMessage: 'Tekan Coba lagi dengan data yang sama.',
        ),
        throwsA(
          isA<ApiException>().having(
            (exception) => exception.message,
            'message',
            contains('Tekan Coba lagi dengan data yang sama.'),
          ),
        ),
      );
    });
  });

  test(
    'pending transaction request can be restored and cleared for the same user',
    () async {
      SharedPreferences.setMockInitialValues({
        'user': jsonEncode({'id': 42, 'role': 'kasir'}),
      });
      final service = TransaksiService();

      await service.savePendingTransaction(
        idempotencyKey: '93e601a6-c28d-41c5-9421-fb23a30f1a84',
        noPolisi: 'B 1234 XYZ',
        merk: 'Honda',
        jenisKendaraan: 'motor',
        layananId: 3,
        tipePelanggan: 'reguler',
      );

      final pending = await service.fetchPendingTransaction();
      expect(
        pending?['idempotency_key'],
        '93e601a6-c28d-41c5-9421-fb23a30f1a84',
      );
      expect(pending?['no_polisi'], 'B 1234 XYZ');
      expect(pending?['jenis_kendaraan'], 'motor');
      expect(pending?['layanan_id'], 3);

      await service.clearPendingTransaction();
      expect(await service.fetchPendingTransaction(), isNull);
    },
  );

  test('vehicle brand updates can reactivate an inactive brand', () async {
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
    Map<String, dynamic>? sentBody;
    final service = VehicleBrandService(
      client: MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"message":"Merek berhasil diperbarui."}', 200);
      }),
    );

    await service.updateVehicleBrand(7, 'Honda', isActive: true);

    expect(sentBody, {'name': 'Honda', 'is_active': true});
  });

  test(
    'keeps a completed task successful when its follow-up refresh fails',
    () async {
      SharedPreferences.setMockInitialValues({'token': 'test-token'});
      var transactionReads = 0;
      final service = TransaksiService(
        client: MockClient((request) async {
          if (request.method == 'PUT' &&
              request.url.path.endsWith('/transaksi/4/status-cuci')) {
            return http.Response('{"message":"Status cucian diperbarui"}', 200);
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/transaksi')) {
            transactionReads++;
            if (transactionReads == 1) {
              return http.Response('{"data":[]}', 200);
            }
            throw http.ClientException('Refresh failed', request.url);
          }
          return http.Response('{"message":"Unexpected request"}', 500);
        }),
      );
      final provider = TransaksiProvider(service: service);

      await provider.loadTransaksi(role: 'operator');
      final succeeded = await provider.ubahStatusCuci(4, 'selesai');

      expect(succeeded, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.syncWarningMessage, contains('Muat ulang antrean'));
    },
  );

  test(
    'legacy pending transaction without vehicle type can be restored',
    () async {
      SharedPreferences.setMockInitialValues({
        'user': jsonEncode({'id': 42, 'role': 'kasir'}),
        'pending_transaction_42': jsonEncode({
          'idempotency_key': '93e601a6-c28d-41c5-9421-fb23a30f1a84',
          'no_polisi': 'B 1234 XYZ',
          'merk_kendaraan': 'Honda',
          'layanan_id': 3,
          'tipe_pelanggan': 'reguler',
          'user_id': null,
        }),
      });

      final pending = await TransaksiService().fetchPendingTransaction();

      expect(pending?['jenis_kendaraan'], isNull);
      expect(
        pending?['idempotency_key'],
        '93e601a6-c28d-41c5-9421-fb23a30f1a84',
      );
    },
  );
}
