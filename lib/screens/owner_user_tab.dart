import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/user_management_service.dart';
import '../utils/api_config.dart';
import '../widgets/owner_config_section_header.dart';
import '../widgets/profile_photo_input.dart';
import 'detailed_view_screen.dart';

class OwnerUserTab extends StatefulWidget {
  const OwnerUserTab({super.key});

  @override
  State<OwnerUserTab> createState() => _OwnerUserTabState();
}

class _OwnerUserTabState extends State<OwnerUserTab> {
  final UserManagementService _service = UserManagementService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _service.fetchUsers();
      if (mounted) {
        setState(() {
          _users = users;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshUsers() async {
    await _loadUsers();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_errorMessage ?? 'Daftar akun berhasil diperbarui.'),
      ),
    );
  }

  Future<void> _showAddUserForm() => _showUserForm();

  Future<void> _showEditUserForm(Map<String, dynamic> user) =>
      _showUserForm(user: user);

  Future<void> _showUserForm({Map<String, dynamic>? user}) async {
    final isEditing = user != null;
    var name = user?['name'] as String? ?? '';
    var email = user?['email'] as String? ?? '';
    var password = '';
    var selectedRole = user?['role'] as String? ?? 'kasir';
    var isActive = user?['is_active'] != false;
    var tanggalKerja = (user?['tanggal_kerja'] as String? ?? '')
        .split('T')
        .first;
    Uint8List? profilePhotoBytes;
    var isSubmitting = false;
    String? formError;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? 'Edit akun' : 'Tambah akun',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: name,
                      onChanged: (value) => name = value,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: email,
                      onChanged: (value) => email = value,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      onChanged: (value) => password = value,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEditing
                            ? 'Password baru (opsional)'
                            : 'Password (minimal 8 karakter)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tanggal kerja'),
                      subtitle: Text(
                        tanggalKerja.isEmpty
                            ? 'Pilih tanggal kerja'
                            : tanggalKerja,
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: isSubmitting
                          ? null
                          : () async {
                              final initialDate = DateTime.tryParse(
                                tanggalKerja,
                              );
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: initialDate ?? DateTime.now(),
                                firstDate: DateTime(1970),
                                lastDate: DateTime.now(),
                              );
                              if (selectedDate != null) {
                                setModalState(() {
                                  tanggalKerja = selectedDate
                                      .toIso8601String()
                                      .split('T')
                                      .first;
                                });
                              }
                            },
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'NIK pegawai dibuat otomatis: 2 digit awal mengikuti tahun mulai kerja, 2 digit akhir adalah nomor unik.',
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Akun aktif'),
                        subtitle: Text(
                          isActive
                              ? 'Akun dapat login dan memakai aplikasi.'
                              : 'Akun tidak dapat login; sesi yang ada dicabut.',
                        ),
                        value: isActive,
                        onChanged: isSubmitting
                            ? null
                            : (value) => setModalState(() {
                                isActive = value;
                              }),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          user['nik'] is String
                              ? 'NIK pegawai: ${user['nik']}'
                              : 'NIK belum dibuat. Pilih tanggal mulai kerja yang benar, lalu simpan.',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ProfilePhotoInput(
                      photoUrl:
                          isEditing &&
                              user['foto_profil'] is String &&
                              (user['foto_profil'] as String).isNotEmpty
                          ? _profilePhotoUrl(user['id'] as int)
                          : null,
                      isBusy: isSubmitting,
                      onPhotoSelected: (bytes) async {
                        setModalState(() {
                          profilePhotoBytes = bytes;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Peran akun'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final role in const {
                          'kasir': 'Kasir',
                          'operator': 'Operator',
                        }.entries)
                          ChoiceChip(
                            label: Text(role.value),
                            selected: selectedRole == role.key,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedRole = role.key;
                                });
                              }
                            },
                          ),
                      ],
                    ),
                    if (formError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        formError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (name.trim().isEmpty ||
                                  email.trim().isEmpty ||
                                  tanggalKerja.isEmpty ||
                                  (!isEditing &&
                                      (password.isEmpty ||
                                          profilePhotoBytes == null))) {
                                setModalState(() {
                                  formError =
                                      'Nama, email, dan tanggal mulai kerja wajib diisi. Akun baru juga memerlukan password dan foto profil.';
                                });
                                return;
                              }
                              if (password.isNotEmpty && password.length < 8) {
                                setModalState(() {
                                  formError =
                                      'Password harus minimal 8 karakter.';
                                });
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                formError = null;
                              });
                              try {
                                if (isEditing) {
                                  final trimmedName = name.trim();
                                  final trimmedEmail = email.trim();
                                  try {
                                    await _service.updateUser(
                                      user['id'] as int,
                                      name: trimmedName,
                                      email: trimmedEmail,
                                      role: selectedRole,
                                      isActive: isActive,
                                      password: password.isEmpty
                                          ? null
                                          : password,
                                      tanggalKerja: tanggalKerja.isEmpty
                                          ? null
                                          : tanggalKerja,
                                      fotoProfil: profilePhotoBytes,
                                    );
                                  } catch (error) {
                                    if (!_hasUnknownWriteOutcome(error)) {
                                      rethrow;
                                    }

                                    final users = await _service.fetchUsers();
                                    final savedUser = users.where(
                                      (candidate) =>
                                          candidate['id'] == user['id'],
                                    );
                                    if (savedUser.isEmpty ||
                                        savedUser.first['name'] !=
                                            trimmedName ||
                                        savedUser.first['email'] !=
                                            trimmedEmail ||
                                        savedUser.first['role'] !=
                                            selectedRole ||
                                        savedUser.first['is_active'] !=
                                            isActive) {
                                      rethrow;
                                    }
                                  }
                                } else {
                                  final trimmedName = name.trim();
                                  final trimmedEmail = email.trim();
                                  try {
                                    await _service.createUser(
                                      trimmedName,
                                      trimmedEmail,
                                      password,
                                      selectedRole,
                                      tanggalKerja,
                                      profilePhotoBytes!,
                                    );
                                  } catch (error) {
                                    if (!_hasUnknownWriteOutcome(error)) {
                                      rethrow;
                                    }

                                    List<Map<String, dynamic>> users;
                                    try {
                                      users = await _service.fetchUsers();
                                    } catch (verificationError) {
                                      throw ApiException(
                                        'Respons simpan tidak diterima dan hasilnya belum dapat dipastikan. Muat ulang daftar akun sebelum mencoba lagi. $verificationError',
                                      );
                                    }

                                    final wasSaved = users.any(
                                      (savedUser) =>
                                          (savedUser['email'] as String?)
                                                  ?.toLowerCase() ==
                                              trimmedEmail.toLowerCase() &&
                                          savedUser['name'] == trimmedName &&
                                          savedUser['role'] == selectedRole,
                                    );
                                    if (!wasSaved) {
                                      rethrow;
                                    }
                                  }
                                }
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext, true);
                                }
                              } catch (error) {
                                if (sheetContext.mounted) {
                                  setModalState(() {
                                    formError = error.toString();
                                  });
                                }
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing ? 'Simpan perubahan' : 'Simpan akun',
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? isEditing
                        ? 'Akun berhasil diperbarui.'
                        : 'Akun berhasil dibuat.'
                  : 'Akun berhasil disimpan, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  bool _hasUnknownWriteOutcome(Object error) =>
      error is ApiException && error.hasUnknownWriteOutcome;

  String _profilePhotoUrl(int userId) =>
      '${ApiConfig.baseUrl}/profile-photos/$userId';

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: Text(
          'Akun ${user['name']} tidak dapat digunakan lagi. Riwayat transaksi dan kendaraan tetap disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus akun'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      try {
        await _service.deleteUser(user['id'] as int);
      } catch (error) {
        if (!_hasUnknownWriteOutcome(error)) {
          rethrow;
        }

        final users = await _service.fetchUsers();
        if (users.any((candidate) => candidate['id'] == user['id'])) {
          rethrow;
        }
      }
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? 'Akun berhasil dihapus. Riwayat tetap tersimpan.'
                  : 'Akun berhasil dihapus, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OwnerConfigSectionHeader(
              title: 'Kelola akun',
              subtitle: 'Atur akses dan data seluruh pengguna',
              icon: Icons.manage_accounts_rounded,
              itemCount: _users.length,
              isLoading: _isLoading,
              onRefresh: _refreshUsers,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _users.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadUsers,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _users.isEmpty
                  ? const Center(child: Text('Belum ada akun.'))
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 92),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final name = user['name'] as String? ?? 'Tanpa nama';
                          final role = user['role'] as String? ?? 'unknown';

                          final isActive = user['is_active'] == true;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(
                                14,
                                8,
                                8,
                                8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isActive
                                    ? const Color(0xFFE5EFFF)
                                    : const Color(0xFFF0F1F4),
                                foregroundColor: isActive
                                    ? const Color(0xFF2369C8)
                                    : const Color(0xFF8490A1),
                                backgroundImage:
                                    user['foto_profil'] is String &&
                                        (user['foto_profil'] as String)
                                            .isNotEmpty
                                    ? NetworkImage(
                                        _profilePhotoUrl(user['id'] as int),
                                      )
                                    : null,
                                child: Text(
                                  user['foto_profil'] is String &&
                                          (user['foto_profil'] as String)
                                              .isNotEmpty
                                      ? ''
                                      : name.isEmpty
                                      ? '?'
                                      : name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: const Color(0xFF2369C8),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(user['email'] as String? ?? '-'),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE5EFFF),
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: Text(
                                            role.toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF2369C8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        OwnerConfigStatusBadge(
                                          isActive: isActive,
                                        ),
                                      ],
                                    ),
                                    if (user['nik'] != null) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        'NIK ${user['nik']} • Mulai ${user['tanggal_kerja'] ?? '-'}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              onTap: () => openDetailedView(
                                context,
                                title: 'Detail Akun $name',
                                data: user,
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit akun',
                                    onPressed: () => _showEditUserForm(user),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus akun',
                                    onPressed: () => _confirmDeleteUser(user),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserForm,
        icon: const Icon(Icons.person_add),
        label: const Text('Tambah akun'),
      ),
    );
  }
}
