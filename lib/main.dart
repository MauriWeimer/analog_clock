import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() => runApp(const AnalogClock());

class AnalogClock extends StatelessWidget {
  const AnalogClock({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      theme: ThemeData(fontFamily: 'RobotoMono'),
      home: const _ClockScreen(),
    );
  }
}

class _ClockScreen extends StatefulWidget {
  const _ClockScreen({Key? key}) : super(key: key);

  @override
  State<_ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<_ClockScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final ValueNotifier<DateTime> _dateNotifier;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _epoch = now.hour * 3600 + now.minute * 60 + (now.second + now.millisecond / 1000);
    _second = (_epoch % 3600) % 60;
    _minute = (_epoch % 3600) / 60;
    _hour = _epoch / 3600;

    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    _animationController.addListener(_animationListener);

    _dateNotifier = ValueNotifier<DateTime>(
      DateTime(
        now.year,
        now.month,
        now.day,
        _hour.toInt(),
        _minute.toInt(),
        _second.toInt(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.removeListener(_animationListener);
    _animationController.dispose();
    _dateNotifier.dispose();

    super.dispose();
  }

  late num _epoch;

  late double _second;
  double get second => _second / 60;
  set second(double value) {
    if (value == _second) {
      return;
    }

    _second = (value >= 60.0) ? 0.0 : value;
  }

  late double _minute;
  double get minute => _minute / 60;
  set minute(double value) {
    if (value == _minute) {
      return;
    }

    _minute = (value >= 60.0) ? 0.0 : value;
  }

  late double _hour;
  double get hour => (_hour >= 12.0 ? _hour - 12.0 : _hour) / 12;
  set hour(double value) {
    if (value == _hour) {
      return;
    }

    _hour = (value >= 24.0) ? 0.0 : value;
  }

  void _animationListener() {
    final value = _animationController.value;
    _epoch = _epoch.toInt() + value;

    second = (_epoch % 3600) % 60;
    minute = (_epoch % 3600) / 60;
    hour = _epoch / 3600;

    if (_animationController.isCompleted) {
      final now = DateTime.now();
      _dateNotifier.value = DateTime(
        now.year,
        now.month,
        now.day,
        _hour.toInt(),
        _minute.toInt(),
        _second.toInt(),
      );
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: OrientationBuilder(
            builder: (_, oriantation) {
              final clock = Expanded(
                flex: 2,
                child: CustomPaint(
                  painter: const _TicksPainter(
                    background: Color(0xFFF9F8FF),
                    padding: 8.0,
                    count: 60,
                    length: 8.0,
                    stroke: 2.0,
                    color: Color(0xFFE1E1EB),
                  ),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          final dimension = min(constraints.maxWidth, constraints.maxHeight) * 0.5;

                          return SizedBox.square(
                            dimension: dimension,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF4F4FA),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: FittedBox(
                                  child: ValueListenableBuilder<DateTime>(
                                    valueListenable: _dateNotifier,
                                    builder: (_, date, __) => Text(
                                      timeFormat.format(date),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF3B3A45),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    builder: (_, child) => CustomPaint(
                      foregroundPainter: _IndicatorsPainter(
                        padding: 24.0,
                        indicators: [
                          _Indicator(
                            percent: second,
                            factor: 0.6,
                            stroke: 8.0,
                            color: const Color(0xFFF0C323),
                          ),
                          _Indicator(
                            percent: minute,
                            factor: 0.8,
                            stroke: 10.0,
                            color: const Color(0xFFFF7733),
                          ),
                          _Indicator(
                            percent: hour,
                            stroke: 12.0,
                            color: const Color(0xFFE7446C),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
              final date = Expanded(
                child: Center(
                  child: ValueListenableBuilder<DateTime>(
                    valueListenable: _dateNotifier,
                    builder: (_, date, __) => Text(
                      dateFormat.format(date).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24.0,
                        color: Color(0xFF3B3A45),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );

              if (oriantation == Orientation.portrait) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    clock,
                    date,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  clock,
                  date,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TicksPainter extends CustomPainter {
  const _TicksPainter({
    required this.background,
    required this.padding,
    required this.count,
    required this.length,
    required this.stroke,
    required this.color,
  });

  final Color background;
  final double padding;
  final int count;
  final double length;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);

    final backgroundPaint = Paint()..color = background;
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;

    final outerRadius = min(size.width, size.height) * 0.5 - padding;
    final innerRadius = outerRadius - length;

    canvas.drawCircle(Offset.zero, outerRadius + padding, backgroundPaint);

    final angle = (pi * 2) / count;
    final radians = List.generate(count, (i) => angle * i);

    canvas.drawPoints(
      PointMode.lines,
      [
        for (var radian in radians) ...[
          Offset(outerRadius * cos(radian), outerRadius * sin(radian)),
          Offset(innerRadius * cos(radian), innerRadius * sin(radian)),
        ],
      ],
      tickPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TicksPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.length != length ||
      oldDelegate.stroke != stroke ||
      oldDelegate.color != color;
}

class _Indicator {
  const _Indicator({
    required this.percent,
    this.factor = 1.0,
    required this.stroke,
    required this.color,
  });

  final double percent;
  final double factor;
  final double stroke;
  final Color color;

  @override
  int get hashCode => percent.hashCode ^ factor.hashCode ^ stroke.hashCode ^ color.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is _Indicator &&
        other.percent == percent &&
        other.factor == factor &&
        other.stroke == stroke &&
        other.color == color;
  }
}

class _IndicatorsPainter extends CustomPainter {
  const _IndicatorsPainter({required this.padding, required this.indicators});

  final double padding;
  final List<_Indicator> indicators;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var indicator in indicators) {
      final radius = (min(size.width, size.height) * 0.5 * indicator.factor) - padding - indicator.stroke * 0.5;
      final radians = (pi * 2.0 * indicator.percent) - pi * 0.5;

      canvas.drawPoints(
        PointMode.points,
        [Offset(radius * cos(radians), radius * sin(radians))],
        paint
          ..strokeWidth = indicator.stroke
          ..color = indicator.color,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_IndicatorsPainter oldDelegate) =>
      oldDelegate.padding != padding || !listEquals(oldDelegate.indicators, indicators);
}
