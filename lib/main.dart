import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polygon Drawer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PolygonDrawerPage(),
    );
  }
}

class PolygonDrawerPage extends StatefulWidget {
  const PolygonDrawerPage({super.key});
  @override
  State<PolygonDrawerPage> createState() => _PolygonDrawerPageState();
}

class _PolygonDrawerPageState extends State<PolygonDrawerPage>
    with SingleTickerProviderStateMixin {
  final List<Offset> _points = [];
  List<double> _sideLengths = [];
  static const double _closeRadius = 20;
  bool get _isPolygonClosed => _points.length > 2 && _points.first == _points.last;

  void _onTapDown(TapDownDetails details) {
    final p = details.localPosition;
    if (_isPolygonClosed) return;
    if (_points.isNotEmpty && (p - _points.first).distance < _closeRadius) {
      setState(() {
        _points.add(_points.first);
      });
      _generateSideLengths();
    } else {
      setState(() {
        _points.add(p);
      });
    }
  }

  void _generateSideLengths() {
    _sideLengths.clear();
    for (var i = 0; i < _points.length - 1; i++) {
      final d = (_points[i + 1] - _points[i]).distance;
      _sideLengths.add(double.parse(d.toStringAsFixed(1)));
    }
  }

  void _applySideLengths() {
    if (!_isPolygonClosed || _sideLengths.length < 2) return;
    final newPoints = <Offset>[];
    newPoints.add(_points.first);
    var dir = _points[1] - _points[0];
    final dist = dir.distance;
    dir = dist == 0 ? const Offset(1, 0) : dir / dist;
    for (var length in _sideLengths) {
      final curr = newPoints.last;
      final next = curr + dir * length;
      newPoints.add(next);
      dir = Offset(dir.dy, -dir.dx);
    }
    newPoints.add(newPoints.first);
    setState(() {
      _points
        ..clear()
        ..addAll(newPoints);
    });
  }

  void _reset() {
    setState(() {
      _points.clear();
      _sideLengths.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canInputSides = _isPolygonClosed;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polygon Drawer'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Основная область для рисования
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: PolygonPainter(
                        points: _points,
                        sideLengths: canInputSides ? _sideLengths : null,
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _onTapDown,
                      child: const SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Нижняя анимированная панель
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: double.infinity,
              color: Colors.pink.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canInputSides) ...[
                    const Text(
                      'Введите длины сторон:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_sideLengths.length, (i) {
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Стор. ${i + 1}',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed > 0) {
                                  _sideLengths[i] = parsed;
                                }
                              },
                              controller: TextEditingController(
                                text: _sideLengths[i].toString(),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FilledButton(
                      onPressed: _applySideLengths,
                      child: const Text('Применить'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton(
                    onPressed: _reset,
                    child: const Text('Сбросить'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final List<double>? sideLengths;
  PolygonPainter({required this.points, this.sideLengths});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final circlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, linePaint);

    for (var p in points) {
      canvas.drawCircle(p, 8, circlePaint);
    }

    if (sideLengths != null && points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final textSpan = TextSpan(
          text: sideLengths!.length > i ? sideLengths![i].toString() : '',
          style: const TextStyle(color: Colors.red, fontSize: 14),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          mid - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
