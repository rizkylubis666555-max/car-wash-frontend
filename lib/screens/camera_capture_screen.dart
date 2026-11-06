import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, this.title = 'Ambil foto'});

  final String title;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Uint8List? _capturedBytes;
  Object? _cameraError;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Kamera tidak ditemukan pada perangkat ini.');
      }

      final camera = cameras.firstWhere(
        (availableCamera) =>
            availableCamera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _cameraError = error;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _capturedBytes = bytes;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _capturedBytes != null
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: InteractiveViewer(
                            child: Image.memory(
                              _capturedBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )
                    : _cameraError != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kamera tidak dapat dibuka: $_cameraError',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _initializeCamera,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      )
                    : controller?.value.isInitialized == true
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: CameraPreview(controller!),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _capturedBytes == null
                  ? SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isTakingPicture ? null : _takePicture,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          _isTakingPicture ? 'Mengambil foto...' : 'Ambil foto',
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _capturedBytes = null;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retake / Ambil Ulang Foto'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(_capturedBytes),
                          child: const Text('Gunakan Foto'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
