import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _isInitializing = true;
  bool _isLoading = false;
  String? _role;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get role => _role;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _user != null && _role != null;

  Future<void> restoreSession() async {
    try {
      _user = await _authService.restoreSession();
      _role = _user?['role'] as String?;
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      if (result['success'] == true) {
        _user = result['user'] as Map<String, dynamic>;
        _role = result['role'] as String;
      } else {
        _errorMessage = result['message'] as String?;
      }

      return result;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> registerMember({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String noWhatsapp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.registerMember(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        noWhatsapp: noWhatsapp,
      );
      if (result['success'] == true) {
        _user = result['user'] as Map<String, dynamic>;
        _role = 'member';
      } else {
        _errorMessage = result['message'] as String?;
      }
      return result;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfilePhoto(Uint8List bytes) async {
    if (_user == null || _role == null) {
      _errorMessage = 'Sesi login tidak ditemukan. Silakan masuk kembali.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.updateProfilePhoto(bytes);
      _role = _user?['role'] as String?;
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? password,
    String? noWhatsapp,
  }) async {
    if (_user == null || _role == null) {
      _errorMessage = 'Sesi login tidak ditemukan. Silakan masuk kembali.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authService.updateProfile(
        name: name,
        email: email,
        password: password,
        noWhatsapp: noWhatsapp,
      );
      _role = _user?['role'] as String?;
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _role = null;
      return true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }
}
