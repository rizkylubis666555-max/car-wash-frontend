import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_exception.dart';
import '../services/member_service.dart';
import '../widgets/owner_config_section_header.dart';
import 'detailed_view_screen.dart';

class OwnerMemberTab extends StatefulWidget {
  const OwnerMemberTab({super.key});

  @override
  State<OwnerMemberTab> createState() => _OwnerMemberTabState();
}

class _OwnerMemberTabState extends State<OwnerMemberTab> {
  final MemberService _service = MemberService();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _members = await _service.fetchMembers();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final normalizedNumber = digits.startsWith('0')
        ? '62${digits.substring(1)}'
        : digits.startsWith('8')
        ? '62$digits'
        : digits;
    final uri = Uri.https('wa.me', '/$normalizedNumber');

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp tidak dapat dibuka.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka WhatsApp: $error')),
        );
      }
    }
  }

  Future<void> _editWhatsapp(Map<String, dynamic> member) async {
    final controller = TextEditingController(
      text: member['no_whatsapp'] as String? ?? '',
    );
    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nomor WhatsApp Member'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nomor WhatsApp',
            hintText: 'Contoh: 081234567890',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty &&
                  !RegExp(r'^\+?[0-9\s()-]{8,20}$').hasMatch(value)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Format nomor WhatsApp tidak valid.'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (phone == null || !mounted) {
      return;
    }

    try {
      final expectedPhone = phone.isEmpty ? null : phone;
      try {
        await _service.updateMemberWhatsapp(member['id'] as int, expectedPhone);
      } catch (error) {
        if (error is! ApiException || !error.hasUnknownWriteOutcome) {
          rethrow;
        }

        List<Map<String, dynamic>> savedMembers;
        try {
          savedMembers = await _service.fetchMembers();
        } catch (verificationError) {
          throw ApiException(
            'Respons simpan nomor WhatsApp tidak diterima dan hasilnya belum dapat dipastikan. Muat ulang data member sebelum mencoba lagi. $verificationError',
          );
        }
        final savedMember = savedMembers.where(
          (item) => item['id'] == member['id'],
        );
        if (savedMember.isEmpty ||
            savedMember.first['no_whatsapp'] != expectedPhone) {
          rethrow;
        }
      }
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? 'Nomor WhatsApp berhasil diperbarui.'
                  : 'Nomor berhasil disimpan, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
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

  Future<void> _setMemberActive(
    Map<String, dynamic> member,
    bool isActive,
  ) async {
    try {
      try {
        await _service.setMemberActive(member['id'] as int, isActive);
      } catch (error) {
        if (error is! ApiException || !error.hasUnknownWriteOutcome) {
          rethrow;
        }

        List<Map<String, dynamic>> savedMembers;
        try {
          savedMembers = await _service.fetchMembers();
        } catch (verificationError) {
          throw ApiException(
            'Respons perubahan status tidak diterima dan hasilnya belum dapat dipastikan. Muat ulang daftar member sebelum mencoba lagi. $verificationError',
          );
        }
        final savedMember = savedMembers.where(
          (item) => item['id'] == member['id'],
        );
        if (savedMember.isEmpty || savedMember.first['is_active'] != isActive) {
          rethrow;
        }
      }

      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage == null
                  ? isActive
                        ? 'Akun member berhasil diaktifkan.'
                        : 'Akun member dinonaktifkan dan seluruh sesi dicabut.'
                  : 'Status akun tersimpan, tetapi daftar gagal dimuat ulang: $_errorMessage',
            ),
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
          children: [
            OwnerConfigSectionHeader(
              title: 'Kelola member',
              subtitle: 'Kelola akun dan kontak pelanggan terdaftar',
              icon: Icons.groups_rounded,
              itemCount: _members.length,
              isLoading: _isLoading,
              onRefresh: _loadMembers,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _loadMembers,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    )
                  : _members.isEmpty
                  ? const Center(child: Text('Belum ada data member.'))
                  : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final phone = member['no_whatsapp'] as String?;
                          final isActive = member['is_active'] == true;
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
                                child: Text(
                                  (member['name'] as String? ?? 'M')
                                      .characters
                                      .first
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                member['name'] as String? ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                'WhatsApp: ${phone?.isNotEmpty == true ? phone : 'Belum diisi'}',
                              ),
                              onTap: () => openDetailedView(
                                context,
                                title: 'Detail Member ${member['name'] ?? ''}',
                                data: member,
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  Switch.adaptive(
                                    value: member['is_active'] == true,
                                    onChanged: (value) =>
                                        _setMemberActive(member, value),
                                    activeTrackColor: const Color(0xFF54A985),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit nomor WhatsApp',
                                    onPressed: () => _editWhatsapp(member),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: phone?.isNotEmpty == true
                                        ? 'Buka WhatsApp'
                                        : 'Nomor WhatsApp belum tersedia',
                                    onPressed: phone?.isNotEmpty == true
                                        ? () => _openWhatsApp(phone!)
                                        : null,
                                    icon: const Icon(Icons.chat),
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
    );
  }
}
