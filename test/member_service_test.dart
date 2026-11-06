import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berkah_mobile/services/member_service.dart';

void main() {
  test('loads promo progress for the authenticated member', () async {
    SharedPreferences.setMockInitialValues({'token': 'member-token'});
    String? requestedPath;
    final service = MemberService(
      client: MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'data': {
              'member': {'id': 8, 'name': 'Member'},
              'promo': {
                'id': 1,
                'name': 'Cuci Gratis',
                'wash_threshold': 5,
                'free_washes': 1,
              },
              'completed_washes': 3,
              'reward_reserved': false,
              'reward_available': false,
            },
          }),
          200,
        );
      }),
    );

    final loyalty = await service.fetchMyLoyalty();

    expect(requestedPath, '/api/loyalty/me');
    expect(loyalty['completed_washes'], 3);
    expect(loyalty['reward_available'], false);
  });

  test('sends member account status changes to the owner endpoint', () async {
    SharedPreferences.setMockInitialValues({'token': 'owner-token'});
    String? requestedMethod;
    String? requestedPath;
    Map<String, dynamic>? requestedBody;
    final service = MemberService(
      client: MockClient((request) async {
        requestedMethod = request.method;
        requestedPath = request.url.path;
        requestedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'message': 'Akun berhasil dinonaktifkan.'}),
          200,
        );
      }),
    );

    await service.setMemberActive(8, false);

    expect(requestedMethod, 'PUT');
    expect(requestedPath, '/api/users/8/status');
    expect(requestedBody, {'is_active': false});
  });
}
