import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    final defaultUrl =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000/api'
        : 'http://127.0.0.1:8000/api';
    final configuredUrl = _configuredBaseUrl.isEmpty
        ? defaultUrl
        : _configuredBaseUrl;
    final uri = Uri.parse(configuredUrl);

    if (!uri.hasScheme || !uri.hasAuthority) {
      throw StateError('API_BASE_URL must be an absolute URL.');
    }

    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError('Production builds require an HTTPS API_BASE_URL.');
    }

    return configuredUrl;
  }
}
