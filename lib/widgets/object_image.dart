import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../services/matching_service.dart';
import '../services/object_region.dart';

/// Mantiene foto, contorno y gestos en el mismo rectángulo, sin incluir las
/// bandas vacías que introduce BoxFit.contain.
class ObjectImage extends StatefulWidget {
  final File image;
  final List<ImagePoint> outline;
  final String? label;
  final ValueChanged<ObjectRegion>? onRegionChanged;

  const ObjectImage({
    super.key,
    required this.image,
    this.outline = const [],
    this.label,
    this.onRegionChanged,
  });

  @override
  State<ObjectImage> createState() => _ObjectImageState();
}

class _ObjectImageState extends State<ObjectImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;
  bool _failed = false;
  Offset? _start;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(ObjectImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.path != widget.image.path) {
      _imageSize = null;
      _failed = false;
      _start = null;
      _resolve();
    }
  }

  void _resolve() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = FileImage(widget.image)
        .resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        info.dispose();
        if (mounted) setState(() => _imageSize = size);
      },
      onError: (Object error, StackTrace? stack) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: Text('No se pudo abrir la imagen'));
    if (_imageSize == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = applyBoxFit(
          BoxFit.contain,
          _imageSize!,
          constraints.biggest,
        ).destination;
        void select(Offset end) {
          final start = _start;
          if (start == null) return;
          final region = ObjectRegion(
            (math.min(start.dx, end.dx) / size.width).clamp(0, 1),
            (math.min(start.dy, end.dy) / size.height).clamp(0, 1),
            (math.max(start.dx, end.dx) / size.width).clamp(0, 1),
            (math.max(start.dy, end.dy) / size.height).clamp(0, 1),
          );
          if (region.isValid) widget.onRegionChanged?.call(region);
        }

        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: GestureDetector(
              dragStartBehavior: DragStartBehavior.down,
              key: const ValueKey('object-image-area'),
              onPanStart: widget.onRegionChanged == null
                  ? null
                  : (event) => _start = event.localPosition,
              onPanUpdate: widget.onRegionChanged == null
                  ? null
                  : (event) => select(event.localPosition),
              onPanEnd: widget.onRegionChanged == null
                  ? null
                  : (_) => _start = null,
              onPanCancel: () => _start = null,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      widget.image,
                      fit: BoxFit.fill,
                      gaplessPlayback: false,
                    ),
                    if (widget.outline.isNotEmpty) ...[
                      CustomPaint(
                        painter: ObjectOutlinePainter(widget.outline),
                      ),
                      if (widget.label != null)
                        Positioned(
                          left:
                              (widget.outline.map((p) => p.x).reduce(math.min) *
                                      size.width)
                                  .clamp(0, math.max(0, size.width - 120)),
                          top:
                              (widget.outline.map((p) => p.y).reduce(math.min) *
                                          size.height -
                                      30)
                                  .clamp(0, math.max(0, size.height - 30)),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: size.width),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: Colors.green.shade800,
                            child: Text(
                              widget.label!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ObjectOutlinePainter extends CustomPainter {
  final List<ImagePoint> outline;
  ObjectOutlinePainter(this.outline);

  @override
  void paint(Canvas canvas, Size size) {
    if (outline.length != 4) return;
    final path = Path()
      ..moveTo(outline.first.x * size.width, outline.first.y * size.height);
    for (final point in outline.skip(1)) {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.green.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(ObjectOutlinePainter oldDelegate) =>
      oldDelegate.outline != outline;
}
