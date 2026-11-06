import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/camera_capture_screen.dart';

class ProfilePhotoInput extends StatefulWidget {
  const ProfilePhotoInput({
    super.key,
    required this.onPhotoSelected,
    this.photoUrl,
    this.isBusy = false,
  });

  final Future<void> Function(Uint8List bytes) onPhotoSelected;
  final String? photoUrl;
  final bool isBusy;

  @override
  State<ProfilePhotoInput> createState() => _ProfilePhotoInputState();
}

class _ProfilePhotoInputState extends State<ProfilePhotoInput> {
  Uint8List? _selectedBytes;

  Future<void> _capturePhoto() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CameraCaptureScreen(title: 'Foto profil'),
      ),
    );
    if (bytes != null) {
      await _usePhoto(bytes);
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _usePhoto(await image.readAsBytes());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih foto: $error')));
      }
    }
  }

  Future<void> _usePhoto(Uint8List bytes) async {
    setState(() {
      _selectedBytes = bytes;
    });
    await widget.onPhotoSelected(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final selectedBytes = _selectedBytes;
    final photoUrl = widget.photoUrl;

    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF77BDF7), Color(0xFF2369C8), Color(0xFF8A65C5)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2369C8).withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 7,
                offset: Offset(-2, -2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBFE),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: SizedBox(
                width: 96,
                height: 96,
                child: selectedBytes != null
                    ? Image.memory(selectedBytes, fit: BoxFit.cover)
                    : photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person_rounded, size: 48),
                      )
                    : const Icon(Icons.person_rounded, size: 48),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.isBusy)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _capturePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera (disarankan)'),
              ),
              OutlinedButton.icon(
                onPressed: _chooseFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pilih gambar'),
              ),
            ],
          ),
      ],
    );
  }
}
