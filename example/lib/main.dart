import 'dart:math';

import 'package:debug_hit_points/debug_hit_points.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  double angle = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => angle += pi / 6),
                child: DebugHitPoints(
                  color: Colors.teal.withOpacity(0.6),
                  resolution: 22,
                  child: Transform.rotate(
                    angle: angle,
                    child: const Text('Hello World!'),
                  ),
                ),
              ),
              const DebugHitPoints(
                color: Colors.green,
                resolution: 50,
                child: CustomPaint(
                  size: Size.square(200),
                  painter: CirclePainter(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  const CirclePainter();

  @override
  bool? hitTest(Offset position) {
    return (position - const Offset(100, 100)).distance < 100;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(size.center(Offset.zero), size.shortestSide / 2, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
