import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  final Function(String base64Signature) onSignatureComplete;
  final double height;
  final Color penColor;
  final double penWidth;
  final Color backgroundColor;

  const SignaturePad({
    Key? key,
    required this.onSignatureComplete,
    this.height = 200,
    this.penColor = Colors.black,
    this.penWidth = 3.0,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;
  Size _padSize = Size.zero;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _currentStroke = [event.localPosition];
      _hasSignature = true;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      _currentStroke.add(event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _strokes.add(List.from(_currentStroke));
      }
      _currentStroke = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSignature = false;
    });
  }

  Future<void> _saveSignature() async {
    if (!_hasSignature || _strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign before saving')),
      );
      return;
    }

    try {
      final size = _padSize.isEmpty
          ? Size(MediaQuery.of(context).size.width - 32, widget.height)
          : _padSize;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = widget.backgroundColor,
      );

      final paint = Paint()
        ..color = widget.penColor
        ..strokeWidth = widget.penWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (var stroke in _strokes) {
        if (stroke.length == 1) {
          // Single tap — draw a dot
          canvas.drawCircle(
            stroke[0],
            widget.penWidth / 2,
            Paint()
              ..color = widget.penColor
              ..style = PaintingStyle.fill,
          );
        } else if (stroke.length > 1) {
          // Use quadratic bezier for smooth curves
          final path = Path();
          path.moveTo(stroke[0].dx, stroke[0].dy);
          for (int i = 1; i < stroke.length - 1; i++) {
            final midX = (stroke[i].dx + stroke[i + 1].dx) / 2;
            final midY = (stroke[i].dy + stroke[i + 1].dy) / 2;
            path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, midX, midY);
          }
          path.lineTo(stroke.last.dx, stroke.last.dy);
          canvas.drawPath(path, paint);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final base64 = base64Encode(byteData.buffer.asUint8List());
        widget.onSignatureComplete(base64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving signature: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            _padSize = Size(constraints.maxWidth, widget.height);
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border.all(color: Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    // Signature drawing area using Listener for reliable pointer events
                    Listener(
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerUp,
                      behavior: HitTestBehavior.opaque,
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          penColor: widget.penColor,
                          penWidth: widget.penWidth,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                    // Hint text when empty
                    if (!_hasSignature)
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.draw, size: 32, color: Color(0xFFBDBDBD)),
                            SizedBox(height: 6),
                            Text(
                              'Sign here',
                              style: TextStyle(
                                color: Color(0xFFBDBDBD),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _hasSignature ? _saveSignature : null,
                icon: const Icon(Icons.check),
                label: const Text('Accept Signature'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color penColor;
  final double penWidth;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.penWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = penWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> stroke) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke[0],
          penWidth / 2,
          Paint()
            ..color = penColor
            ..style = PaintingStyle.fill,
        );
      } else if (stroke.length > 1) {
        final path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length - 1; i++) {
          final midX = (stroke[i].dx + stroke[i + 1].dx) / 2;
          final midY = (stroke[i].dy + stroke[i + 1].dy) / 2;
          path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, midX, midY);
        }
        path.lineTo(stroke.last.dx, stroke.last.dy);
        canvas.drawPath(path, paint);
      }
    }

    for (var stroke in strokes) {
      drawStroke(stroke);
    }
    if (currentStroke.isNotEmpty) {
      drawStroke(currentStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

/// Widget to display a signature from base64
class SignatureDisplay extends StatelessWidget {
  final String base64Signature;
  final double? height;
  final BoxFit fit;

  const SignatureDisplay({
    Key? key,
    required this.base64Signature,
    this.height,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(base64Signature);
      return Container(
        height: height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            Uint8List.fromList(bytes),
            fit: fit,
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: height ?? 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Unable to display signature'),
        ),
      );
    }
  }
}
