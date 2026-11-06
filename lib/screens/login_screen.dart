import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/transaksi_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialError});

  final String? initialError;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showRegister = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerWhatsappController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _registerEmailController.dispose();
    _registerWhatsappController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _executeLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }

    final result = await context.read<AuthProvider>().login(email, password);
    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      context.read<TransaksiProvider>().clear();
      return;
    }

    _showMessage(result['message'] as String? ?? 'Login gagal.');
  }

  Future<void> _executeRegister() async {
    final name = _nameController.text.trim();
    final email = _registerEmailController.text.trim();
    final noWhatsapp = _registerWhatsappController.text.trim();
    final password = _registerPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    if (name.isEmpty ||
        email.isEmpty ||
        noWhatsapp.isEmpty ||
        password.isEmpty ||
        confirmation.isEmpty) {
      _showMessage('Semua kolom pendaftaran wajib diisi.');
      return;
    }
    if (!RegExp(r'^\+?[0-9\s()-]{8,20}$').hasMatch(noWhatsapp)) {
      _showMessage('Format nomor WhatsApp tidak valid.');
      return;
    }
    if (password != confirmation) {
      _showMessage('Konfirmasi password tidak sama.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Password harus minimal 8 karakter.');
      return;
    }
    final result = await context.read<AuthProvider>().registerMember(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: confirmation,
      noWhatsapp: noWhatsapp,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      context.read<TransaksiProvider>().clear();
      _showMessage('Pendaftaran berhasil. Kamu sudah masuk sebagai member.');
    } else {
      _showMessage(result['message'] as String? ?? 'Pendaftaran gagal.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 8,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF53A9F5), Color(0xFF2369C8)],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF2369C8,
                                ).withValues(alpha: 0.3),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                blurRadius: 8,
                                offset: Offset(-3, -3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_car_wash_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CAR WASH',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Masuk untuk mengelola layanan cuci kendaraan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 28),
                      if (widget.initialError != null) ...[
                        _MessageBox(message: widget.initialError!),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _executeLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Tampilkan password'
                                : 'Sembunyikan password',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: auth.isLoading ? null : _executeLogin,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 28),
                      if (!_showRegister) ...[
                        const Text(
                          'Belum punya akun member?',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => setState(() => _showRegister = true),
                          child: const Text('Daftar sebagai member'),
                        ),
                      ] else ...[
                        const Text(
                          'Pendaftaran Member',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama lengkap',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _registerEmailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _registerWhatsappController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp *',
                            hintText: 'Contoh: +62 812 3456 7890',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _registerPasswordController,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Password (minimal 8 karakter)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _executeRegister(),
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: auth.isLoading ? null : _executeRegister,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Daftar & Masuk'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showRegister = false),
                          child: const Text('Kembali ke login'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: TextStyle(color: Colors.orange.shade900)),
    );
  }
}
