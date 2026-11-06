import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaksi_provider.dart';
import '../utils/api_config.dart';
import '../widgets/profile_photo_input.dart';
import 'detailed_view_screen.dart';

class KasirProfilTab extends StatefulWidget {
  const KasirProfilTab({super.key});

  @override
  State<KasirProfilTab> createState() => _KasirProfilTabState();
}

class _KasirProfilTabState extends State<KasirProfilTab> {
  String _roleLabel(String role) {
    return switch (role) {
      'owner' => 'Owner',
      'operator' => 'Operator',
      'member' => 'Member',
      _ => 'Kasir',
    };
  }

  Future<void> _editCredentials(AuthProvider auth) async {
    final roleLabel = _roleLabel(auth.role ?? '');
    final nameController = TextEditingController(
      text: auth.user?['name'] as String? ?? '',
    );
    final emailController = TextEditingController(
      text: auth.user?['email'] as String? ?? '',
    );
    final whatsappController = TextEditingController(
      text: auth.user?['no_whatsapp'] as String? ?? '',
    );
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    String? errorMessage;
    var isSaving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Ubah kredensial $roleLabel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                if (auth.role == 'member')
                  TextField(
                    controller: whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp',
                      hintText: 'Contoh: +62 812 3456 7890',
                    ),
                  ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password baru (opsional)',
                  ),
                ),
                TextField(
                  controller: confirmationController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi password baru',
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text;
                      if (name.isEmpty || email.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Nama dan email wajib diisi.';
                        });
                        return;
                      }
                      if (password.isNotEmpty && password.length < 8) {
                        setDialogState(() {
                          errorMessage = 'Password minimal 8 karakter.';
                        });
                        return;
                      }
                      if (password != confirmationController.text) {
                        setDialogState(() {
                          errorMessage = 'Konfirmasi password tidak sama.';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                        errorMessage = null;
                      });
                      final succeeded = await auth.updateProfile(
                        name: name,
                        email: email,
                        password: password.isEmpty ? null : password,
                        noWhatsapp: auth.role == 'member'
                            ? whatsappController.text.trim()
                            : null,
                      );
                      if (!dialogContext.mounted) {
                        return;
                      }
                      if (succeeded) {
                        Navigator.pop(dialogContext, true);
                      } else {
                        setDialogState(() {
                          isSaving = false;
                          errorMessage =
                              auth.errorMessage ?? 'Profil gagal diperbarui.';
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    passwordController.dispose();
    confirmationController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil $roleLabel berhasil diperbarui.')),
      );
    }
  }

  Future<void> _eksekusiLogout() async {
    final auth = context.read<AuthProvider>();
    final succeeded = await auth.logout();
    if (succeeded && mounted) {
      context.read<TransaksiProvider>().clear();
    }
    if (!succeeded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Logout gagal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?['name'] as String? ?? 'Pengguna';
    final email = auth.user?['email'] as String? ?? '';
    final role = auth.role ?? '';
    final userId = auth.user?['id'];
    final photoPath = auth.user?['foto_profil'];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          ProfilePhotoInput(
            photoUrl:
                userId is int && photoPath is String && photoPath.isNotEmpty
                ? '${ApiConfig.baseUrl}/profile-photos/$userId'
                : null,
            isBusy: auth.isLoading,
            onPhotoSelected: (bytes) async {
              final succeeded = await auth.updateProfilePhoto(bytes);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    succeeded
                        ? 'Foto profil berhasil diperbarui.'
                        : auth.errorMessage ?? 'Foto profil gagal diperbarui.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Informasi akun',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _profileRow('Nama', name),
                  _profileRow('Email', email),
                  _profileRow('Peran', _roleLabel(role)),
                  if (role == 'kasir' || role == 'operator')
                    _profileRow(
                      'NIK pegawai',
                      auth.user?['nik'] as String? ?? 'Belum tersedia',
                    ),
                  if (role == 'kasir' || role == 'operator')
                    _profileRow(
                      'Mulai bekerja',
                      auth.user?['tanggal_kerja'] as String? ?? 'Belum diisi',
                    ),
                  if (role == 'member')
                    _profileRow(
                      'WhatsApp',
                      auth.user?['no_whatsapp'] as String? ?? 'Belum diisi',
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => openDetailedView(
                        context,
                        title: 'Detail Profil ${_roleLabel(role)}',
                        data: auth.user ?? const {},
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Lihat detail'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: auth.isLoading ? null : () => _editCredentials(auth),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Ubah kredensial'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: auth.isLoading ? null : _eksekusiLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar dari akun'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCC4D59),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
