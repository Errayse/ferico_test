import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

///
/// Точка входа в приложение
///
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

///
/// Страница с отрисовкой многоугольника в отдельной "серединной" области
///
class PolygonDrawerPage extends StatefulWidget {
  const PolygonDrawerPage({super.key});

  @override
  State<PolygonDrawerPage> createState() => _PolygonDrawerPageState();
}

class _PolygonDrawerPageState extends State<PolygonDrawerPage> {
  /// Список точек, которые пользователь «натыкал»
  final List<Offset> _points = [];

  /// Длины сторон (после замыкания многоугольника)
  List<double> _sideLengths = [];

  /// Порог расстояния до первой точки, чтобы считать клик «близко» и замкнуть фигуру
  static const double _closeRadius = 20.0;

  /// Определяем, замкнут ли многоугольник (первая точка == последняя)
  bool get _isPolygonClosed =>
      _points.length > 2 && _points.first == _points.last;

  ///
  /// Обработчик тапа внутри области рисования
  ///
  void _onTapDown(TapDownDetails details) {
    final tapPos = details.localPosition;
    print('TapDown at $tapPos');

    // Если фигура уже замкнута — не даём добавлять точки
    if (_isPolygonClosed) {
      print('Многоугольник уже замкнут, новые точки не добавляем.');
      return;
    }

    // Проверяем, тапаем ли мы рядом с первой точкой (чтобы замкнуть)
    if (_points.isNotEmpty && (tapPos - _points.first).distance < _closeRadius) {
      print('Замыкаем многоугольник');
      setState(() {
        _points.add(_points.first);
      });
      _generateSideLengths();
    } else {
      // Добавляем новую точку
      setState(() {
        _points.add(tapPos);
      });
      print('Добавлена точка: $tapPos');
    }
  }

  ///
  /// После замыкания фигуры рассчитываем длины сторон
  ///
  void _generateSideLengths() {
    _sideLengths.clear();
    for (int i = 0; i < _points.length - 1; i++) {
      final dist = (_points[i + 1] - _points[i]).distance;
      _sideLengths.add(double.parse(dist.toStringAsFixed(1)));
    }
    print('Сгенерированы длины сторон: $_sideLengths');
  }

  ///
  /// "Применить" — перестраиваем фигуру, чтобы углы стали 90°
  ///
  void _applySideLengths() {
    if (!_isPolygonClosed || _sideLengths.length < 2) {
      print('Фигура не замкнута или сторон < 2 — не применяем');
      return;
    }

    final newPoints = <Offset>[];
    newPoints.add(_points.first);

    // Получаем направление от первой к второй точке
    var direction = _points[1] - _points[0];
    final dirLength = direction.distance;
    if (dirLength == 0) {
      direction = const Offset(1, 0);
    } else {
      direction = direction / dirLength;
    }

    // Для каждой длины строим новую точку
    for (int i = 0; i < _sideLengths.length; i++) {
      final current = newPoints.last;
      final length = _sideLengths[i];

      final next = current + direction * length;
      newPoints.add(next);

      // Поворот на 90° по часовой стрелке: (x, y) => (y, -x)
      direction = Offset(direction.dy, -direction.dx);
    }

    // Замыкаем
    newPoints.add(newPoints.first);

    setState(() {
      _points
        ..clear()
        ..addAll(newPoints);
    });

    print('Применили стороны, новые точки: $_points');
  }

  ///
  /// Сброс
  ///
  void _reset() {
    setState(() {
      _points.clear();
      _sideLengths.clear();
    });
    print('Сброс');
  }

  @override
  Widget build(BuildContext context) {
    final canInputSides = _isPolygonClosed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polygon Drawer'),
        centerTitle: true,
      ),
      // Размещаем всё в Column
      body: Column(
        children: [
          // 1) Любые элементы, которые надо сверху (если нужно)
          // Например, небольшая панель
          Container(
            height: 40,
            alignment: Alignment.center,
            color: Colors.pink.shade50,
            child: const Text(
              'Здесь может быть заголовок / подсказка / кнопки и т.д.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 2) Центр экрана — область рисования
          // Сделаем фиксированной высоты, чтобы не перекрывать нижние элементы
          const SizedBox(height: 20),
          // Используем Center + Container, чтобы область рисования была "отдельной"
          Center(
            child: Container(
              // Задаём ширину на всю ширину экрана, а высоту фиксированную (например, 300)
              width: MediaQuery.of(context).size.width,
              height: 300,
              color: Colors.white,
              // Stack нужен, чтобы GestureDetector был поверх CustomPaint
              // (или наоборот, если захотите)
              child: Stack(
                children: [
                  // Собственно отрисовка
                  CustomPaint(
                    painter: PolygonPainter(
                      points: _points,
                      sideLengths: canInputSides ? _sideLengths : null,
                    ),
                  ),
                  // Поверх кладём GestureDetector, чтобы "ловить" тапы
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _onTapDown,
                    child: Container(
                      // Заполняем весь Stack
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3) Внизу меню ввода длин сторон, кнопка "Применить" и "Сброс"
          if (canInputSides) ...[
            Text(
              'Введите длины сторон:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(_sideLengths.length, (index) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Стор. ${index + 1}',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          _sideLengths[index] = parsed;
                        }
                      },
                      controller: TextEditingController(
                        text: _sideLengths[index].toString(),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _applySideLengths,
              child: const Text('Применить'),
            ),
          ],

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _reset,
            child: const Text('Сбросить'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

///
/// Painter, который рисует:
///  - Многоугольник (линиями)
///  - Точки (увеличенные, радиус 8)
///  - Подписи сторон (если фигура замкнута)
///
class PolygonPainter extends CustomPainter {
  final List<Offset> points;
  final List<double>? sideLengths;

  PolygonPainter({required this.points, this.sideLengths});

  @override
  void paint(Canvas canvas, Size size) {
    // Для наглядности нарисуем "крест" по центру
    final center = Offset(size.width / 2, size.height / 2);
    final debugPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1;

    // Вертикальная линия
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      debugPaint,
    );
    // Горизонтальная
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      debugPaint,
    );

    // Линии многоугольника
    final linePaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Точки
    final circlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Рисуем сам путь
    final path = ui.Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Рисуем точки
    for (final p in points) {
      canvas.drawCircle(p, 8, circlePaint);
    }

    // Если есть sideLengths (замкнуто), подписываем стороны
    if (sideLengths != null && points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final mid = Offset(
          (p1.dx + p2.dx) / 2,
          (p1.dy + p2.dy) / 2,
        );

        final textSpan = TextSpan(
          text: sideLengths!.length > i ? sideLengths![i].toString() : '',
          style: const TextStyle(color: Colors.red, fontSize: 14),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: 200);
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
