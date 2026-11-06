import 'package:flutter/material.dart';

class SlideToFinishControl extends StatefulWidget {
  const SlideToFinishControl({
    super.key,
    required this.onComplete,
    this.enabled = true,
  });

  final Future<bool> Function() onComplete;
  final bool enabled;

  @override
  State<SlideToFinishControl> createState() => _SlideToFinishControlState();
}

class _SlideToFinishControlState extends State<SlideToFinishControl> {
  static const _thumbSize = 52.0;
  static const _inset = 6.0;
  double _progress = 0;
  bool _isCompleting = false;

  void _updateProgress(DragUpdateDetails details, double width) {
    if (!widget.enabled || _isCompleting) {
      return;
    }

    final travel = width - _thumbSize - (_inset * 2);
    if (travel <= 0) {
      return;
    }

    setState(() {
      _progress = (_progress + details.delta.dx / travel).clamp(0.0, 1.0);
    });
  }

  Future<void> _finishIfReleased() async {
    if (_progress < 0.8 || !widget.enabled || _isCompleting) {
      setState(() {
        _progress = 0;
      });
      return;
    }

    setState(() {
      _isCompleting = true;
      _progress = 1;
    });
    final succeeded = await widget.onComplete();
    if (!mounted) {
      return;
    }

    setState(() {
      _isCompleting = false;
      _progress = succeeded ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Geser untuk menyelesaikan cucian',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = constraints.maxWidth - _thumbSize - (_inset * 2);
          final thumbCenter = _inset + (_thumbSize / 2) + (travel * _progress);
          final thumbAlignment = (thumbCenter / constraints.maxWidth * 2) - 1;
          return GestureDetector(
            onHorizontalDragUpdate: (details) =>
                _updateProgress(details, constraints.maxWidth),
            onHorizontalDragEnd: (_) => _finishIfReleased(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 64,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: (_thumbSize + (_inset * 2)) + travel * _progress,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                  Text(
                    _isCompleting
                        ? 'Menyelesaikan...'
                        : _progress == 1
                        ? 'Tugas selesai'
                        : 'Geser untuk selesai',
                    style: TextStyle(
                      color: _progress > 0.4
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Align(
                    alignment: Alignment(thumbAlignment, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(_inset),
                      child: Container(
                        width: _thumbSize,
                        height: _thumbSize,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
