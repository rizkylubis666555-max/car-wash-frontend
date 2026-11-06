import 'package:flutter/foundation.dart';

import '../services/api_exception.dart';
import '../services/catalog_service.dart';
import '../services/member_service.dart';
import '../services/operator_service.dart';
import '../services/transaksi_service.dart';
import '../services/vehicle_brand_service.dart';

class TransaksiProvider with ChangeNotifier {
  TransaksiProvider({
    TransaksiService? service,
    CatalogService? catalogService,
    MemberService? memberService,
    OperatorService? operatorService,
    VehicleBrandService? vehicleBrandService,
  }) : _service = service ?? TransaksiService(),
       _catalogService = catalogService ?? CatalogService(),
       _memberService = memberService ?? MemberService(),
       _operatorService = operatorService ?? OperatorService(),
       _vehicleBrandService = vehicleBrandService ?? VehicleBrandService();

  final TransaksiService _service;
  final CatalogService _catalogService;
  final MemberService _memberService;
  final OperatorService _operatorService;
  final VehicleBrandService _vehicleBrandService;

  List<Map<String, dynamic>> _transaksiList = [];
  List<Map<String, dynamic>> _layananList = [];
  List<Map<String, dynamic>> _memberList = [];
  List<Map<String, dynamic>> _kendaraanList = [];
  List<Map<String, dynamic>> _vehicleBrandList = [];
  List<Map<String, dynamic>> _promoList = [];
  List<Map<String, dynamic>> _operatorList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _syncWarningMessage;
  int? _lastErrorStatusCode;
  String? _activeRole;

  List<Map<String, dynamic>> get transaksiList => _transaksiList;
  List<Map<String, dynamic>> get layananList => _layananList;
  List<Map<String, dynamic>> get memberList => _memberList;
  List<Map<String, dynamic>> get kendaraanList => _kendaraanList;
  List<Map<String, dynamic>> get vehicleBrandList => _vehicleBrandList;
  List<Map<String, dynamic>> get promoList => _promoList;
  List<Map<String, dynamic>> get operatorList => _operatorList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get syncWarningMessage => _syncWarningMessage;
  int? get lastErrorStatusCode => _lastErrorStatusCode;

  Future<void> loadTransaksi({required String role}) async {
    if (_activeRole != null && _activeRole != role) {
      _clearData();
    }
    _activeRole = role;
    _isLoading = true;
    _errorMessage = null;
    _syncWarningMessage = null;
    _lastErrorStatusCode = null;
    notifyListeners();

    try {
      await _reloadData();
    } catch (error) {
      _errorMessage = _messageFor(error);
      _lastErrorStatusCode = _statusCodeFor(error);
      _syncWarningMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _clearData();
    _isLoading = false;
    _activeRole = null;
    notifyListeners();
  }

  Future<void> loadVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    _syncWarningMessage = null;
    _lastErrorStatusCode = null;
    notifyListeners();

    try {
      _kendaraanList = await _memberService.fetchVehicles();
    } catch (error) {
      _errorMessage = _messageFor(error);
      _lastErrorStatusCode = _statusCodeFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTransaksiSilently() async {
    final role = _activeRole;
    if (role == null || _isLoading) {
      return;
    }

    try {
      _transaksiList = await _service.fetchTransaksi(member: role == 'member');
      if (role == 'kasir' || role == 'owner') {
        _operatorList = await _operatorService.fetchOperators();
      }
      _errorMessage = null;
      _syncWarningMessage = null;
      _lastErrorStatusCode = null;
    } catch (error) {
      _errorMessage = _messageFor(error);
      _syncWarningMessage = null;
      _lastErrorStatusCode = _statusCodeFor(error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadLayanan() async {
    _isLoading = true;
    _errorMessage = null;
    _lastErrorStatusCode = null;
    notifyListeners();

    try {
      _layananList = await _catalogService.fetchLayanan();
    } catch (error) {
      _errorMessage = _messageFor(error);
      _lastErrorStatusCode = _statusCodeFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> tambahTransaksi({
    required String noPolisi,
    required String merk,
    required String? jenisKendaraan,
    required int layananId,
    required String tipePelanggan,
    required String idempotencyKey,
    int? userId,
    String? modelKendaraan,
    bool claimLoyaltyReward = false,
  }) {
    return _performMutation(() async {
      await _service.inputAntrean(
        noPolisi: noPolisi,
        merk: merk,
        jenisKendaraan: jenisKendaraan,
        layananId: layananId,
        tipePelanggan: tipePelanggan,
        idempotencyKey: idempotencyKey,
        userId: userId,
        modelKendaraan: modelKendaraan,
        claimLoyaltyReward: claimLoyaltyReward,
      );
    });
  }

  Future<bool> batalkanTransaksi(int id, String reason) {
    return _performMutation(() async {
      await _service.cancelTransaksi(id, reason);
    });
  }

  Future<bool> prosesPembayaran(
    int id,
    String metodeBayar, {
    Uint8List? buktiQris,
  }) {
    return _performMutation(() async {
      await _service.bayarTransaksi(id, metodeBayar, buktiQris: buktiQris);
    });
  }

  Future<bool> ubahStatusCuci(int id, String statusBaru) {
    return _performMutation(() async {
      await _service.updateStatusCuci(id, statusBaru);
    });
  }

  Future<bool> assignOperator(int transactionId, int operatorId) {
    return _performMutation(() async {
      await _service.assignOperator(transactionId, operatorId);
    });
  }

  Future<bool> finishFromCashier(int transactionId) {
    return _performMutation(() async {
      await _service.finishFromCashier(transactionId);
    });
  }

  Future<bool> unlockOperatorTask(int transactionId, String reason) {
    return _performMutation(() async {
      await _service.unlockOperatorTask(transactionId, reason);
    });
  }

  Future<void> loadPromos() async {
    _isLoading = true;
    _errorMessage = null;
    _lastErrorStatusCode = null;
    notifyListeners();

    try {
      _promoList = await _catalogService.fetchPromos();
    } catch (error) {
      _errorMessage = _messageFor(error);
      _lastErrorStatusCode = _statusCodeFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadData() async {
    _transaksiList = await _service.fetchTransaksi(
      member: _activeRole == 'member',
    );

    if (_activeRole == 'kasir') {
      _layananList = await _catalogService.fetchLayanan();
      _memberList = await _memberService.fetchMembers();
      _vehicleBrandList = await _vehicleBrandService.fetchVehicleBrands();
      _operatorList = await _operatorService.fetchOperators();
    } else if (_activeRole == 'owner') {
      _operatorList = await _operatorService.fetchOperators();
    }
  }

  Future<bool> _performMutation(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    _syncWarningMessage = null;
    _lastErrorStatusCode = null;
    notifyListeners();

    var succeeded = false;
    try {
      await action();
      succeeded = true;
    } catch (error) {
      _errorMessage = _messageFor(error);
      _lastErrorStatusCode = _statusCodeFor(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (succeeded && _activeRole != null) {
      await loadTransaksi(role: _activeRole!);
      if (_errorMessage != null) {
        _syncWarningMessage = _errorMessage;
        _errorMessage = null;
        notifyListeners();
      }
    }

    return succeeded;
  }

  String _messageFor(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  int? _statusCodeFor(Object error) =>
      error is ApiException ? error.statusCode : null;

  void _clearData() {
    _transaksiList = [];
    _layananList = [];
    _memberList = [];
    _kendaraanList = [];
    _vehicleBrandList = [];
    _promoList = [];
    _operatorList = [];
    _errorMessage = null;
    _syncWarningMessage = null;
    _lastErrorStatusCode = null;
  }
}
