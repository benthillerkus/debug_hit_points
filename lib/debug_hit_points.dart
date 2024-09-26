library debug_hit_points;

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that visualizes where its children can be hit
class DebugHitPoints extends SingleChildRenderObjectWidget {
  /// A widget that visualizes where its children can be hit
  const DebugHitPoints({
    super.key,
    HitTestBehavior? behavior,
    this.enabled = kDebugMode,
    this.color = const Color(0xFFFF0000),
    this.resolution = 100,
    this.size = 1.5,
    super.child,
  }) : behavior = behavior ??
            (child != null
                ? HitTestBehavior.deferToChild
                : HitTestBehavior.translucent);

  /// Whether the debug hit points are calculated and displayed
  final bool enabled;

  /// Behaves like the [GestureDetector.behavior] property
  final HitTestBehavior behavior;

  /// The horizontal resolution of the grid
  ///
  /// The density is not fixed and varies with the size of the child.
  /// Smaller children need a smaller resolution to avoid unnecessary computations.

  final int resolution;

  /// The color of the visualized hit points
  final Color color;

  /// The size of the visualized hit points
  final double size;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return enabled
        ? DebugHitPointsRenderObject(
            behavior: behavior,
            color: color,
            resolution: resolution,
            pointSize: size,
          )
        : RenderProxyBox();
  }

  @override
  void updateRenderObject(
    BuildContext context,
    DebugHitPointsRenderObject renderObject,
  ) {
    renderObject
      ..behavior = behavior
      ..color = color
      ..resolution = resolution
      ..pointSize = size;
  }
}

/// A [RenderProxyBox] that visualizes where its children can be hit
class DebugHitPointsRenderObject extends RenderProxyBoxWithHitTestBehavior {
  /// A [RenderProxyBox] that visualizes where its children can be hit
  DebugHitPointsRenderObject({
    super.behavior,
    required this.color,
    required this.resolution,
    required this.pointSize,
    super.child,
  })  : _hits = Float32List(0),
        _paint = Paint();

  /// The color of the visualized hit points
  Color color;

  /// The size of the visualized hit points
  double pointSize;

  /// The horizontal resolution of the grid
  ///
  /// The density is not fixed and varies with the size of the child.
  /// Smaller children need a smaller resolution to avoid unnecessary computations.
  int resolution;

  Float32List _hits;
  final Paint _paint;

  @override
  void paint(PaintingContext context, Offset offset) {
    // Paints the child first
    super.paint(context, offset);
    if (child == null) return;

    _paint
      ..color = color
      ..strokeWidth = pointSize;

    final (w, h) = (resolution, (resolution / child!.size.aspectRatio).ceil());
    // Try to reuse the existing list if possible
    // It's ok if the list is too long, because for rendering
    // a sublist view on this list is submitted
    if (_hits.length < (w * h * 2)) _hits = Float32List(w * h * 2);
    int end = 0;

    /// When a single hit test failed, because it tried to use an empty hit test result,
    /// for the rest of this method, we use the standard [BoxHitTestResult]s
    /// instead of our lean [_EmptyBoxHitTestResult].
    bool needsFatHitTestResult = false;

    // Distributes the points in a simple grid.
    // Better would be some blue noise pattern to prevent aliasing.
    for (double y = 0; y < h; y++) {
      for (double x = 0; x < w; x++) {
        final position = Offset(
          x / w * child!.size.width,
          y / h * child!.size.height,
        );

        bool hit;
        if (needsFatHitTestResult) {
          hit = hitTest(BoxHitTestResult(), position: position);
        } else {
          try {
            hit = hitTest(const _EmptyBoxHitTestResult(), position: position);
          } on _TriedUsingEmptyHitTestResultException {
            needsFatHitTestResult = true;
            hit = hitTest(BoxHitTestResult(), position: position);
          }
        }

        if (hit) {
          _hits[end++] = position.dx + offset.dx;
          _hits[end++] = position.dy + offset.dy;
        }
      }
    }

    // There was some hearsay that this is very slow on Impeller,
    // and that you should rather bring your own small triangles.
    // I hope that's not true :)
    context.canvas.drawRawPoints(
      PointMode.points,
      Float32List.sublistView(_hits, 0, end),
      _paint,
    );
  }
}

/// Exception thrown when a class tried to get some results back from
/// an operation on an [_EmptyHitTestResult].
class _TriedUsingEmptyHitTestResultException implements Exception {
  const _TriedUsingEmptyHitTestResultException();
}

/// Used as an optimization to avoid creating a new [HitTestResult] for each test
final class _EmptyBoxHitTestResult extends _EmptyHitTestResult
    implements BoxHitTestResult {
  const _EmptyBoxHitTestResult();

  @override
  bool addWithOutOfBandPosition({
    Offset? paintOffset,
    Matrix4? paintTransform,
    Matrix4? rawTransform,
    required BoxHitTestWithOutOfBandPosition hitTest,
  }) {
    throw const _TriedUsingEmptyHitTestResultException();
  }

  @override
  bool addWithPaintOffset({
    required Offset? offset,
    required Offset position,
    required BoxHitTest hitTest,
  }) {
    throw const _TriedUsingEmptyHitTestResultException();
  }

  @override
  bool addWithPaintTransform({
    required Matrix4? transform,
    required Offset position,
    required BoxHitTest hitTest,
  }) {
    throw const _TriedUsingEmptyHitTestResultException();
  }

  @override
  bool addWithRawTransform({
    required Matrix4? transform,
    required Offset position,
    required BoxHitTest hitTest,
  }) {
    throw const _TriedUsingEmptyHitTestResultException();
  }
}

class _EmptyHitTestResult implements HitTestResult {
  const _EmptyHitTestResult();

  @override
  void add(HitTestEntry<HitTestTarget> entry) {}

  @override
  Iterable<HitTestEntry<HitTestTarget>> get path =>
      throw const _TriedUsingEmptyHitTestResultException();

  @override
  void popTransform() {}

  @override
  void pushOffset(Offset offset) {}

  @override
  void pushTransform(Matrix4 transform) {}
}
