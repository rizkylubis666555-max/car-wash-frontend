import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:berkah_mobile/services/auth_service.dart';

void main() {
  test('sends WhatsApp number when registering a member', () async {
    SharedPreferences.setMockInitialValues({});
    Map<String, dynamic>? sentBody;
    final service = AuthService(
      client: MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'token': 'member-token',
            'role': 'member',
            'user': {
              'id': 8,
              'name': 'New Member',
              'email': 'new-member@example.test',
              'role': 'member',
              'no_whatsapp': '+62 812-3456-7890',
            },
          }),
          201,
        );
      }),
    );

    await service.registerMember(
      name: 'New Member',
      email: 'new-member@example.test',
      password: 'secret123',
      passwordConfirmation: 'secret123',
      noWhatsapp: '+62 812-3456-7890',
    );

    expect(sentBody?['no_whatsapp'], '+62 812-3456-7890');
  });
}
