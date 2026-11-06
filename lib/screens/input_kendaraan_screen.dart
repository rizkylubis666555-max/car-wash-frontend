import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaksi_provider.dart';
import '../services/member_service.dart';
import '../services/transaksi_service.dart';

class InputKendaraanScreen extends StatefulWidget {
  const InputKendaraanScreen({super.key});

  @override
  State<InputKendaraanScreen> createState() => _InputKendaraanScreenState();
}

class _InputKendaraanScreenState extends State<InputKendaraanScreen> {
  final TextEditingController _noPolisiController = TextEditingController();
  final TextEditingController _merkController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TransaksiService _service = TransaksiService();
  final MemberService _memberService = MemberService();

  bool _isRestoringPending = true;
  bool _pendingRestoreFailed = false;
  bool _isSubmitting = false;
  int? _selectedLayananId;
  int? _selectedMemberId;
  String? _selectedVehicleType;
  String _tipePelanggan = 'reguler';
  bool _isAddingNewMemberVehicle = false;
  bool _isCustomBrand = false;
  int _totalHarga = 0;
  String? _validationMessage;
  String? _idempotencyKey;
  String? _requestFingerprint;
  bool _claimLoyaltyReward = false;
  Map<String, dynamic>? _selectedMemberLoyalty;

  @override
  void dispose() {
    _noPolisiController.dispose();
    _merkController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _restorePendingRequest();
  }

  Future<void> _restorePendingRequest() async {
    try {
      final pending = await _service.fetchPendingTransaction();
      if (mounted && pending != null) {
        final pendingMemberId = int.tryParse(
          pending['user_id']?.toString() ?? '',
        );
        final member = _findMember(
          Provider.of<TransaksiProvider>(context, listen: false).memberList,
          pendingMemberId,
        );
        final pendingVehicleIsRegistered = _vehiclesForMember(
          member,
        ).any((vehicle) => vehicle['no_polisi'] == pending['no_polisi']);
        final pendingBrand = pending['merk_kendaraan'] as String? ?? '';
        final knownBrands = Provider.of<TransaksiProvider>(
          context,
          listen: false,
        ).vehicleBrandList;
        setState(() {
          _noPolisiController.text = pending['no_polisi'] as String? ?? '';
          _merkController.text = pendingBrand;
          _isCustomBrand = !knownBrands.any(
            (brand) => brand['name'] == pendingBrand,
          );
          _modelController.text = pending['model_kendaraan'] as String? ?? '';
          _selectedLayananId = int.tryParse(
            pending['layanan_id']?.toString() ?? '',
          );
          _tipePelanggan = pending['tipe_pelanggan'] as String? ?? 'reguler';
          _selectedMemberId = pendingMemberId;
          _claimLoyaltyReward =
              pending['claim_loyalty_reward'] as bool? ?? false;
          _selectedVehicleType = pending['jenis_kendaraan'] as String?;
          _isAddingNewMemberVehicle =
              _tipePelanggan == 'member' && !pendingVehicleIsRegistered;
          _idempotencyKey = pending['idempotency_key'] as String?;
          _requestFingerprint = _makeFingerprint(
            noPolisi: _noPolisiController.text,
            merk: _merkController.text,
            modelKendaraan: _modelController.text,
            jenisKendaraan: _selectedVehicleType,
            layananId: _selectedLayananId,
            tipePelanggan: _tipePelanggan,
            userId: _selectedMemberId,
            claimLoyaltyReward: _claimLoyaltyReward,
          );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _validationMessage = error.toString();
          _pendingRestoreFailed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringPending = false;
        });
      }
    }
  }

  String _makeFingerprint({
    required String noPolisi,
    required String merk,
    required String modelKendaraan,
    required String? jenisKendaraan,
    required int? layananId,
    required String tipePelanggan,
    required int? userId,
    required bool claimLoyaltyReward,
  }) => jsonEncode([
    noPolisi.trim().toUpperCase(),
    merk.trim(),
    modelKendaraan.trim(),
    jenisKendaraan,
    layananId,
    tipePelanggan,
    tipePelanggan == 'member' ? userId : null,
    claimLoyaltyReward,
  ]);

  Future<void> _eksekusiSimpan() async {
    if (_isSubmitting) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_noPolisiController.text.trim().isEmpty ||
        _merkController.text.trim().isEmpty ||
        (_selectedVehicleType == null && !_isRetryingSameRequest) ||
        _selectedLayananId == null ||
        (_tipePelanggan == 'member' && _selectedMemberId == null)) {
      setState(() {
        _isSubmitting = false;
        _validationMessage =
            'Lengkapi jenis kendaraan, data kendaraan, layanan, dan akun member.';
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Lengkapi jenis kendaraan, data kendaraan, layanan, dan akun member.',
          ),
        ),
      );
      return;
    }

    final provider = Provider.of<TransaksiProvider>(context, listen: false);
    final noPolisi = _noPolisiController.text.trim().toUpperCase();
    final merk = _merkController.text.trim();
    final modelKendaraan = _modelController.text.trim();
    final userId = _tipePelanggan == 'member' ? _selectedMemberId : null;
    final fingerprint = _makeFingerprint(
      noPolisi: noPolisi,
      merk: merk,
      modelKendaraan: modelKendaraan,
      jenisKendaraan: _selectedVehicleType,
      layananId: _selectedLayananId,
      tipePelanggan: _tipePelanggan,
      userId: userId,
      claimLoyaltyReward: _claimLoyaltyReward,
    );
    if (_requestFingerprint != fingerprint || _idempotencyKey == null) {
      _idempotencyKey = _createIdempotencyKey();
      _requestFingerprint = fingerprint;
    }

    setState(() {
      _isSubmitting = true;
      _validationMessage = null;
    });
    try {
      await _service.savePendingTransaction(
        idempotencyKey: _idempotencyKey!,
        noPolisi: noPolisi,
        merk: merk,
        jenisKendaraan: _selectedVehicleType,
        layananId: _selectedLayananId!,
        tipePelanggan: _tipePelanggan,
        userId: userId,
        modelKendaraan: modelKendaraan,
        claimLoyaltyReward: _claimLoyaltyReward,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _validationMessage = error.toString();
        });
      }
      return;
    }

    final success = await provider.tambahTransaksi(
      noPolisi: noPolisi,
      merk: merk,
      jenisKendaraan: _selectedVehicleType,
      layananId: _selectedLayananId!,
      tipePelanggan: _tipePelanggan,
      idempotencyKey: _idempotencyKey!,
      userId: userId,
      modelKendaraan: modelKendaraan.isEmpty ? null : modelKendaraan,
      claimLoyaltyReward: _claimLoyaltyReward,
    );

    if (success && mounted) {
      String? cleanupWarning;
      if (provider.syncWarningMessage != null) {
        cleanupWarning =
            'Transaksi tersimpan, tetapi antrean gagal dimuat ulang: ${provider.syncWarningMessage}';
      }
      try {
        await _service.clearPendingTransaction();
      } catch (error) {
        cleanupWarning =
            '${cleanupWarning == null ? '' : '$cleanupWarning\n'}Penanda percobaan ulang gagal dibersihkan: $error';
      }
      if (!mounted) {
        return;
      }
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(cleanupWarning ?? 'Kendaraan berhasil masuk antrean!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      if (provider.lastErrorStatusCode == 422) {
        try {
          await _service.clearPendingTransaction();
          _idempotencyKey = null;
          _requestFingerprint = null;
        } catch (error) {
          if (!mounted) {
            return;
          }
          _validationMessage =
              'Pengiriman ditolak: ${provider.errorMessage}. Kunci transaksi tertunda belum dapat dihapus: $error';
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _validationMessage = provider.errorMessage ?? 'Antrean gagal disimpan.';
      });
      messenger.showSnackBar(SnackBar(content: Text(_validationMessage!)));
    }
  }

  String _createIdempotencyKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  bool get _isRetryingSameRequest {
    if (_idempotencyKey == null || _requestFingerprint == null) {
      return false;
    }

    return _requestFingerprint ==
        jsonEncode([
          _noPolisiController.text.trim().toUpperCase(),
          _merkController.text.trim(),
          _modelController.text.trim(),
          _selectedVehicleType,
          _selectedLayananId,
          _tipePelanggan,
          _tipePelanggan == 'member' ? _selectedMemberId : null,
          _claimLoyaltyReward,
        ]);
  }

  bool get _isFormEditable =>
      _idempotencyKey == null && !_pendingRestoreFailed && !_isRestoringPending;

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic>? _findMember(
    List<Map<String, dynamic>> members,
    int? memberId,
  ) {
    if (memberId == null) {
      return null;
    }

    for (final member in members) {
      if (_asInt(member['id']) == memberId) {
        return member;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _vehiclesForMember(Map<String, dynamic>? member) {
    final vehicles = member?['kendaraan'];
    if (vehicles is! List) {
      return [];
    }

    return vehicles
        .whereType<Map>()
        .map((vehicle) => Map<String, dynamic>.from(vehicle))
        .toList();
  }

  String _memberLabel(Map<String, dynamic> member) =>
      '${member['name'] ?? 'Tanpa nama'} • ID: ${member['id']} • ${member['email'] ?? '-'}';

  Future<void> _selectMember(Map<String, dynamic> member) async {
    final vehicles = _vehiclesForMember(member);
    final vehicle = vehicles.isEmpty ? null : vehicles.first;
    final memberId = _asInt(member['id']);
    final brands = context.read<TransaksiProvider>().vehicleBrandList;
    final brandName = vehicle?['merk_kendaraan'] as String?;

    setState(() {
      _selectedMemberId = memberId;
      _claimLoyaltyReward = false;
      _selectedMemberLoyalty = null;
      _isAddingNewMemberVehicle = vehicle == null;
      _noPolisiController.text = vehicle?['no_polisi'] as String? ?? '';
      _merkController.text = brandName ?? '';
      _isCustomBrand =
          brandName != null &&
          !brands.any((brand) => brand['name'] == brandName);
      _modelController.text = vehicle?['model_kendaraan'] as String? ?? '';
      _selectedVehicleType = vehicle?['jenis_kendaraan'] as String?;
      _validationMessage = null;
    });

    if (memberId == null) {
      return;
    }

    try {
      final loyalty = await _memberService.fetchMemberLoyalty(memberId);
      if (!mounted || _selectedMemberId != memberId) {
        return;
      }

      setState(() {
        _selectedMemberLoyalty = loyalty;
      });
      if (loyalty['reward_available'] != true) {
        return;
      }

      final promo = loyalty['promo'] as Map<String, dynamic>? ?? {};
      final threshold = promo['wash_threshold'] ?? 5;
      final shouldClaim = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Promo cuci gratis tersedia'),
          content: Text(
            'Member ini sudah menyelesaikan $threshold cucian berbayar. Gunakan 1 cucian gratis untuk transaksi ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Tidak sekarang'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Klaim gratis'),
            ),
          ],
        ),
      );
      if (mounted && shouldClaim == true) {
        setState(() {
          _claimLoyaltyReward = true;
          _validationMessage = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _validationMessage = 'Progres loyalitas tidak dapat dimuat: $error';
        });
      }
    }
  }

  void _selectVehicle(Map<String, dynamic> vehicle) {
    final brands = context.read<TransaksiProvider>().vehicleBrandList;
    final brandName = vehicle['merk_kendaraan'] as String? ?? '';

    setState(() {
      _isAddingNewMemberVehicle = false;
      _noPolisiController.text = vehicle['no_polisi'] as String? ?? '';
      _merkController.text = brandName;
      _isCustomBrand = !brands.any((brand) => brand['name'] == brandName);
      _modelController.text = vehicle['model_kendaraan'] as String? ?? '';
      _selectedVehicleType = vehicle['jenis_kendaraan'] as String?;
      _validationMessage = null;
    });
  }

  Widget _buildMemberLoyaltyProgress() {
    final loyalty = _selectedMemberLoyalty;
    if (loyalty == null) {
      return const SizedBox.shrink();
    }

    final promoValue = loyalty['promo'];
    if (promoValue is! Map) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.local_offer_outlined),
          title: Text('Belum ada promo aktif.'),
        ),
      );
    }

    final promo = Map<String, dynamic>.from(promoValue);
    final completedWashes =
        int.tryParse(loyalty['completed_washes']?.toString() ?? '') ?? 0;
    final threshold =
        int.tryParse(promo['wash_threshold']?.toString() ?? '') ?? 5;
    final rewardAvailable = loyalty['reward_available'] == true;
    final rewardReserved = loyalty['reward_reserved'] == true;
    final progress = threshold > 0
        ? (completedWashes / threshold).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${promo['name'] ?? 'Promo loyalitas'}: $completedWashes/$threshold cucian',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              _claimLoyaltyReward
                  ? 'Hadiah gratis dipilih untuk transaksi ini.'
                  : rewardReserved
                  ? 'Hadiah gratis sedang digunakan pada transaksi lain.'
                  : rewardAvailable
                  ? 'Hadiah gratis tersedia. Kasir dapat mengonfirmasi klaim.'
                  : 'Progres dihitung dari transaksi yang selesai dan lunas.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeading({
    required int step,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              color: Color(0xFF2369C8),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransaksiProvider>(context);
    final selectedMember = _findMember(provider.memberList, _selectedMemberId);
    final memberVehicles = _vehiclesForMember(selectedMember);
    Map<String, dynamic>? selectedVehicle;
    for (final vehicle in memberVehicles) {
      if (vehicle['no_polisi'] == _noPolisiController.text) {
        selectedVehicle = vehicle;
        break;
      }
    }
    final hasRegisteredVehicles =
        _tipePelanggan == 'member' && memberVehicles.isNotEmpty;
    final isUsingRegisteredVehicle =
        hasRegisteredVehicles && !_isAddingNewMemberVehicle;
    final availableServices = provider.layananList
        .where(
          (service) =>
              service['jenis_kendaraan'] == null ||
              service['jenis_kendaraan'] == _selectedVehicleType,
        )
        .toList();
    final canEdit = _isFormEditable;
    final vehicleBrands = provider.vehicleBrandList
        .where((brand) => brand['name'] is String)
        .toList();
    final selectedBrand = vehicleBrands.where(
      (brand) => brand['name'] == _merkController.text,
    );
    final selectedBrandId = selectedBrand.isNotEmpty
        ? _asInt(selectedBrand.first['id'])
        : _isCustomBrand
        ? -1
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F5FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input kendaraan',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang layanan',
            onPressed: provider.isLoading ? null : provider.loadLayanan,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B8CE7), Color(0xFF2369C8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2369C8,
                                ).withValues(alpha: 0.22),
                                blurRadius: 22,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.24),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.local_car_wash_rounded,
                                  color: Colors.white,
                                  size: 29,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transaksi baru',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Lengkapi pelanggan, kendaraan, dan layanan cuci.',
                                      style: TextStyle(
                                        color: Color(0xFFEAF3FF),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE5EDF7)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF536B8A,
                                ).withValues(alpha: 0.08),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSectionHeading(
                                step: 1,
                                title: 'Pilih pelanggan',
                                subtitle:
                                    'Tentukan jenis pelanggan untuk transaksi.',
                              ),
                              if (_idempotencyKey != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF5E8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFFE0B2),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFFB96800),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Pengiriman sebelumnya belum terkonfirmasi. Simpan kembali dengan data yang sama agar transaksi tidak tercatat ganda.',
                                          style: TextStyle(
                                            color: Color(0xFF8A4B00),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Text(
                                'Tipe pelanggan',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 9,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    avatar: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Reguler'),
                                    selected: _tipePelanggan == 'reguler',
                                    onSelected: canEdit
                                        ? (selected) {
                                            if (selected) {
                                              setState(() {
                                                _tipePelanggan = 'reguler';
                                                _selectedMemberId = null;
                                                _selectedMemberLoyalty = null;
                                                _claimLoyaltyReward = false;
                                                _isAddingNewMemberVehicle =
                                                    false;
                                                _isCustomBrand = false;
                                                _selectedVehicleType = null;
                                                _selectedLayananId = null;
                                                _totalHarga = 0;
                                                _noPolisiController.clear();
                                                _merkController.clear();
                                                _modelController.clear();
                                              });
                                            }
                                          }
                                        : null,
                                  ),
                                  ChoiceChip(
                                    avatar: const Icon(
                                      Icons.stars_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Member'),
                                    selected: _tipePelanggan == 'member',
                                    onSelected: canEdit
                                        ? (selected) {
                                            if (selected) {
                                              setState(() {
                                                _tipePelanggan = 'member';
                                                _selectedMemberId = null;
                                                _selectedMemberLoyalty = null;
                                                _claimLoyaltyReward = false;
                                                _isAddingNewMemberVehicle =
                                                    false;
                                                _isCustomBrand = false;
                                                _selectedVehicleType = null;
                                                _selectedLayananId = null;
                                                _totalHarga = 0;
                                                _noPolisiController.clear();
                                                _merkController.clear();
                                                _modelController.clear();
                                              });
                                            }
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              if (_tipePelanggan == 'member') ...[
                                const SizedBox(height: 12),
                                if (provider.memberList.isEmpty)
                                  const Text(
                                    'Belum ada akun member. Minta owner membuat akun.',
                                  )
                                else
                                  Autocomplete<Map<String, dynamic>>(
                                    initialValue: TextEditingValue(
                                      text: selectedMember == null
                                          ? ''
                                          : _memberLabel(selectedMember),
                                    ),
                                    displayStringForOption: _memberLabel,
                                    optionsBuilder: (value) {
                                      final query = value.text
                                          .trim()
                                          .toLowerCase();
                                      if (query.isEmpty) {
                                        return const <Map<String, dynamic>>[];
                                      }

                                      return provider.memberList
                                          .where((member) {
                                            final searchable =
                                                '${member['name'] ?? ''} ${member['id'] ?? ''} ${member['email'] ?? ''}'
                                                    .toLowerCase();
                                            return searchable.contains(query);
                                          })
                                          .take(30);
                                    },
                                    onSelected: _selectMember,
                                    fieldViewBuilder:
                                        (
                                          context,
                                          textController,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          return TextField(
                                            controller: textController,
                                            focusNode: focusNode,
                                            enabled: canEdit,
                                            onSubmitted: (_) =>
                                                onFieldSubmitted(),
                                            onChanged: (value) {
                                              final currentMember = _findMember(
                                                provider.memberList,
                                                _selectedMemberId,
                                              );
                                              if (currentMember != null &&
                                                  value !=
                                                      _memberLabel(
                                                        currentMember,
                                                      )) {
                                                setState(() {
                                                  _selectedMemberId = null;
                                                  _selectedMemberLoyalty = null;
                                                  _isAddingNewMemberVehicle =
                                                      false;
                                                  _selectedVehicleType = null;
                                                  _selectedLayananId = null;
                                                  _totalHarga = 0;
                                                  _noPolisiController.clear();
                                                  _merkController.clear();
                                                  _modelController.clear();
                                                  _claimLoyaltyReward = false;
                                                  _isCustomBrand = false;
                                                });
                                              }
                                            },
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Cari nama atau ID member',
                                              hintText:
                                                  'Ketik nama, ID, atau email',
                                              prefixIcon: Icon(
                                                Icons.search_rounded,
                                              ),
                                            ),
                                          );
                                        },
                                    optionsViewBuilder:
                                        (context, onSelected, options) => Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4,
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxHeight: 240,
                                              ),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (context, index) {
                                                  final member = options
                                                      .elementAt(index);
                                                  return ListTile(
                                                    title: Text(
                                                      member['name']
                                                              as String? ??
                                                          'Tanpa nama',
                                                    ),
                                                    subtitle: Text(
                                                      'ID: ${member['id']} • ${member['email'] ?? '-'}',
                                                    ),
                                                    onTap: () =>
                                                        onSelected(member),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                              ],
                              if (_selectedMemberId != null &&
                                  _selectedMemberLoyalty != null) ...[
                                const SizedBox(height: 12),
                                _buildMemberLoyaltyProgress(),
                              ],
                              const SizedBox(height: 26),
                              _buildSectionHeading(
                                step: 2,
                                title: 'Pilih kendaraan',
                                subtitle:
                                    'Pilih kendaraan member atau isi data baru.',
                              ),
                              const SizedBox(height: 12),
                              if (_tipePelanggan == 'member' &&
                                  _selectedMemberId == null)
                                const Text(
                                  'Cari dan pilih member terlebih dahulu.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                )
                              else ...[
                                if (hasRegisteredVehicles) ...[
                                  const Text(
                                    'Kendaraan member',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      for (final vehicle in memberVehicles)
                                        ChoiceChip(
                                          label: Text(
                                            '${vehicle['no_polisi']} • ${vehicle['merk_kendaraan']}',
                                          ),
                                          selected:
                                              !_isAddingNewMemberVehicle &&
                                              selectedVehicle?['id'] ==
                                                  vehicle['id'],
                                          onSelected: canEdit
                                              ? (selected) {
                                                  if (selected) {
                                                    _selectVehicle(vehicle);
                                                  }
                                                }
                                              : null,
                                        ),
                                      ChoiceChip(
                                        avatar: const Icon(Icons.add, size: 18),
                                        label: const Text(
                                          'Input kendaraan baru',
                                        ),
                                        selected: _isAddingNewMemberVehicle,
                                        onSelected: canEdit
                                            ? (selected) {
                                                if (selected) {
                                                  setState(() {
                                                    _isAddingNewMemberVehicle =
                                                        true;
                                                    _selectedVehicleType = null;
                                                    _selectedLayananId = null;
                                                    _totalHarga = 0;
                                                    _noPolisiController.clear();
                                                    _merkController.clear();
                                                    _modelController.clear();
                                                    _claimLoyaltyReward = false;
                                                    _isCustomBrand = false;
                                                  });
                                                }
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                                if (_tipePelanggan == 'member' &&
                                    _selectedMemberId != null &&
                                    !hasRegisteredVehicles)
                                  const Text(
                                    'Member ini belum memiliki kendaraan. Isi data kendaraan baru.',
                                  ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Jenis kendaraan',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ChoiceChip(
                                      avatar: const Icon(
                                        Icons.two_wheeler,
                                        size: 18,
                                      ),
                                      label: const Text('Motor'),
                                      selected: _selectedVehicleType == 'motor',
                                      onSelected:
                                          canEdit &&
                                              selectedVehicle?['jenis_kendaraan'] ==
                                                  null
                                          ? (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedVehicleType =
                                                      'motor';
                                                  _selectedLayananId = null;
                                                  _totalHarga = 0;
                                                  _validationMessage = null;
                                                });
                                              }
                                            }
                                          : null,
                                    ),
                                    ChoiceChip(
                                      avatar: const Icon(
                                        Icons.directions_car,
                                        size: 18,
                                      ),
                                      label: const Text('Mobil'),
                                      selected: _selectedVehicleType == 'mobil',
                                      onSelected:
                                          canEdit &&
                                              selectedVehicle?['jenis_kendaraan'] ==
                                                  null
                                          ? (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedVehicleType =
                                                      'mobil';
                                                  _selectedLayananId = null;
                                                  _totalHarga = 0;
                                                  _validationMessage = null;
                                                });
                                              }
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                                if (_tipePelanggan == 'member' &&
                                        hasRegisteredVehicles &&
                                        !_isAddingNewMemberVehicle ||
                                    selectedVehicle != null) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Kendaraan member terdaftar tidak dapat diubah.',
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _noPolisiController,
                                  enabled: canEdit,
                                  readOnly: isUsingRegisteredVehicle,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'Nomor polisi',
                                    hintText: 'Contoh: B 1234 XYZ',
                                    prefixIcon: const Icon(Icons.pin_outlined),
                                    filled: isUsingRegisteredVehicle,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (isUsingRegisteredVehicle)
                                  TextField(
                                    controller: _merkController,
                                    enabled: canEdit,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Merek kendaraan',
                                      prefixIcon: Icon(
                                        Icons.directions_car_filled_outlined,
                                      ),
                                    ),
                                  )
                                else ...[
                                  DropdownButtonFormField<int>(
                                    initialValue: selectedBrandId,
                                    decoration: const InputDecoration(
                                      labelText: 'Merek kendaraan',
                                      prefixIcon: Icon(
                                        Icons.directions_car_filled_outlined,
                                      ),
                                    ),
                                    hint: const Text('Pilih merek'),
                                    items: [
                                      for (final brand in vehicleBrands)
                                        DropdownMenuItem<int>(
                                          value: _asInt(brand['id']),
                                          child: Text(brand['name'] as String),
                                        ),
                                      const DropdownMenuItem<int>(
                                        value: -1,
                                        child: Text('Lainnya / Custom'),
                                      ),
                                    ],
                                    onChanged: !canEdit
                                        ? null
                                        : (brandId) {
                                            setState(() {
                                              _isCustomBrand = brandId == -1;
                                              if (brandId == -1) {
                                                _merkController.clear();
                                              } else {
                                                final brand = vehicleBrands
                                                    .where(
                                                      (item) =>
                                                          _asInt(item['id']) ==
                                                          brandId,
                                                    );
                                                _merkController.text =
                                                    brand.isEmpty
                                                    ? ''
                                                    : brand.first['name']
                                                          as String;
                                              }
                                            });
                                          },
                                  ),
                                  if (_isCustomBrand) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _merkController,
                                      enabled: canEdit,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Merek custom',
                                        hintText: 'Ketik merek kendaraan',
                                        prefixIcon: Icon(Icons.edit_outlined),
                                      ),
                                    ),
                                  ],
                                ],
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _modelController,
                                  enabled: canEdit,
                                  readOnly: isUsingRegisteredVehicle,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: 'Model kendaraan',
                                    hintText: 'Contoh: Vario 160',
                                    prefixIcon: const Icon(
                                      Icons.commute_outlined,
                                    ),
                                    filled: isUsingRegisteredVehicle,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 26),
                              _buildSectionHeading(
                                step: 3,
                                title: 'Pilih layanan cuci',
                                subtitle:
                                    'Pilih paket yang sesuai untuk kendaraan.',
                              ),
                              const SizedBox(height: 12),
                              if (provider.errorMessage != null ||
                                  _validationMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFFD6D6),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFC83D4D),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _validationMessage ??
                                              provider.errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFC83D4D),
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (_selectedVehicleType == null)
                                const Text(
                                  'Pilih jenis kendaraan untuk melihat layanan yang sesuai.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                )
                              else if (availableServices.isEmpty)
                                Text(
                                  provider.errorMessage ??
                                      'Belum ada layanan untuk jenis kendaraan ini.',
                                )
                              else
                                ...availableServices.map((layanan) {
                                  final isSelected =
                                      _selectedLayananId == layanan['id'];
                                  final serviceType =
                                      layanan['jenis_kendaraan'];
                                  return GestureDetector(
                                    onTap:
                                        _idempotencyKey == null &&
                                            !_pendingRestoreFailed &&
                                            !_isRestoringPending
                                        ? () {
                                            setState(() {
                                              _selectedLayananId =
                                                  layanan['id'];
                                              _totalHarga =
                                                  int.tryParse(
                                                    layanan['harga'].toString(),
                                                  ) ??
                                                  0;
                                              _validationMessage = null;
                                            });
                                          }
                                        : null,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF1F7FF)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2369C8)
                                              : const Color(0xFFE5EDF7),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF536B8A,
                                            ).withValues(alpha: 0.05),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            serviceType == 'motor'
                                                ? Icons.two_wheeler_rounded
                                                : Icons.directions_car_rounded,
                                            size: 42,
                                            color: serviceType == 'motor'
                                                ? const Color(0xFFEF9A3D)
                                                : const Color(0xFF3986DD),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  layanan['nama_layanan'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rp ${layanan['harga']}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF2369C8),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE5EDF7))),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF536B8A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total pembayaran',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Siap ditambahkan ke antrean',
                              style: TextStyle(
                                color: Color(0xFF172B4D),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Rp ${_claimLoyaltyReward ? 0 : _totalHarga}',
                            style: const TextStyle(
                              color: Color(0xFF2369C8),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            provider.isLoading ||
                                _isSubmitting ||
                                _isRestoringPending ||
                                _pendingRestoreFailed
                            ? null
                            : _eksekusiSimpan,
                        icon: provider.isLoading || _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_road_rounded),
                        label: Text(
                          _isRetryingSameRequest
                              ? 'Coba simpan lagi'
                              : 'Masukkan ke antrean',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2369C8),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(
                            0xFF2369C8,
                          ).withValues(alpha: 0.26),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
