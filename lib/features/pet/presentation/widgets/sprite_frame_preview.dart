import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Muestra UN SOLO frame de un sprite sheet, escalado al tamaño deseado.
/// Pensado para pixel art (filterQuality.none).
///
/// Para los sheets de mutación (192×192, grid 4×4 de 48px):
///   `SpriteFramePreview(assetPath: 'assets/sprites/slimebit.png', frameSize: 48, displaySize: 96)`
///   muestra la celda (col 0, row 0) — primera frame de la animación idle.
class SpriteFramePreview extends StatefulWidget {
  final String assetPath;
  final int frameCol;
  final int frameRow;
  final double frameSize;
  final double displaySize;

  const SpriteFramePreview({
    super.key,
    required this.assetPath,
    this.frameCol = 0,
    this.frameRow = 0,
    this.frameSize = 48,
    this.displaySize = 96,
  });

  @override
  State<SpriteFramePreview> createState() => _SpriteFramePreviewState();
}

class _SpriteFramePreviewState extends State<SpriteFramePreview> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant SpriteFramePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _image = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load(widget.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final size = Size(widget.displaySize, widget.displaySize);
    if (_image == null) {
      return SizedBox(width: size.width, height: size.height);
    }
    return CustomPaint(
      size: size,
      painter: _SpriteFramePainter(
        image: _image!,
        srcRect: Rect.fromLTWH(
          widget.frameCol * widget.frameSize,
          widget.frameRow * widget.frameSize,
          widget.frameSize,
          widget.frameSize,
        ),
      ),
    );
  }
}

class _SpriteFramePainter extends CustomPainter {
  final ui.Image image;
  final Rect srcRect;

  _SpriteFramePainter({required this.image, required this.srcRect});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      srcRect,
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _SpriteFramePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.srcRect != srcRect;
}
