// lib/widgets/ui/image/hand_drawn_crop_widget.dart

/// 该文件定义了手绘风格的图片裁剪RenderObjectWidget。
/// 它将图片显示、手势交互（平移/缩放）和裁剪覆盖层绘制封装到一个高性能的组件中。
library;

import 'dart:ui' as ui; // dart:ui 图像处理所需
import 'dart:math' as math; // 数学运算所需

import 'package:flutter/gestures.dart'; // Flutter 手势识别所需
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:flutter/rendering.dart'; // Flutter 渲染层所需

/// `HandDrawnCropWidget` 是一个自定义的 RenderObjectWidget，用于显示和交互式裁剪图片。
///
/// 它直接与渲染层交互，以获得最佳性能。
class HandDrawnCropWidget extends LeafRenderObjectWidget {
  final ui.Image? image; // 要显示的 ui.Image 对象
  final TransformationController controller; // 控制图片变换（平移、缩放）
  final double cropCircleRadiusRatio; // 裁剪圆相对于组件尺寸的半径比例
  final Color overlayColor; // 覆盖层颜色
  final Color borderColor; // 裁剪框边框颜色

  const HandDrawnCropWidget({
    super.key,
    required this.image,
    required this.controller,
    this.cropCircleRadiusRatio = 0.85, // 默认裁剪圆占85%
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.6), // 默认半透明黑
    this.borderColor = const Color.fromRGBO(255, 255, 255, 0.8), // 默认半透明白
  });

  /// 创建底层的 RenderObject。
  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderHandDrawnCrop(
      image: image,
      controller: controller,
      cropCircleRadiusRatio: cropCircleRadiusRatio,
      overlayColor: overlayColor,
      borderColor: borderColor,
    );
  }

  /// 当 Widget 属性更新时，同步更新 RenderObject 的属性。
  @override
  void updateRenderObject(
      BuildContext context, RenderHandDrawnCrop renderObject) {
    renderObject
      ..image = image
      ..controller = controller
      ..cropCircleRadiusRatio = cropCircleRadiusRatio
      ..overlayColor = overlayColor
      ..borderColor = borderColor;
  }
}

/// `RenderHandDrawnCrop` 是实际执行布局、绘制和命中测试的 RenderBox。
class RenderHandDrawnCrop extends RenderBox {
  ui.Image? _image;
  TransformationController _controller;
  double _cropCircleRadiusRatio;
  Color _overlayColor;
  Color _borderColor;

  // 手势识别器，用于处理平移和缩放
  late final ScaleGestureRecognizer _scaleGestureRecognizer;
  Matrix4? _initialMatrix; // 手势开始时的变换矩阵
  Offset? _initialFocalPoint; // 手势开始时的焦点

  RenderHandDrawnCrop({
    required ui.Image? image,
    required TransformationController controller,
    required double cropCircleRadiusRatio,
    required Color overlayColor,
    required Color borderColor,
  })  : _image = image,
        _controller = controller,
        _cropCircleRadiusRatio = cropCircleRadiusRatio,
        _overlayColor = overlayColor,
        _borderColor = borderColor {
    // 初始化手势识别器
    _scaleGestureRecognizer = ScaleGestureRecognizer(debugOwner: this)
      ..onStart = _handleScaleStart
      ..onUpdate = _handleScaleUpdate
      ..onEnd = _handleScaleEnd;
  }

  // --- 属性 Getters & Setters ---
  // 当属性变化时，我们需要通知Flutter框架进行重绘或重新布局

  set image(ui.Image? value) {
    if (_image == value) return;
    _image = value;
    markNeedsPaint(); // 图像变了，只需要重绘
  }

  set controller(TransformationController value) {
    if (_controller == value) return;
    _controller.removeListener(markNeedsPaint); // 移除旧的监听
    _controller = value;
    _controller.addListener(markNeedsPaint); // 添加新的监听
    markNeedsPaint();
  }

  set cropCircleRadiusRatio(double value) {
    if (_cropCircleRadiusRatio == value) return;
    _cropCircleRadiusRatio = value;
    markNeedsPaint();
  }

  set overlayColor(Color value) {
    if (_overlayColor == value) return;
    _overlayColor = value;
    markNeedsPaint();
  }

  set borderColor(Color value) {
    if (_borderColor == value) return;
    _borderColor = value;
    markNeedsPaint();
  }

  // --- RenderBox 生命周期 ---

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(markNeedsPaint); // 挂载时添加监听
  }

  @override
  void detach() {
    _controller.removeListener(markNeedsPaint); // 卸载时移除监听
    _scaleGestureRecognizer.dispose(); // 销毁手势识别器
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true; // 性能优化：这是一个重绘边界

  @override
  bool hitTestSelf(Offset position) => true; // 始终响应命中测试，以便手势可以触发

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    // 将指针事件传递给手势识别器
    if (event is PointerDownEvent) {
      _scaleGestureRecognizer.addPointer(event);
    }
  }

  @override
  void performLayout() {
    // 布局很简单：填满父组件给的约束
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    canvas.save();
    // 将画布的原点移动到我们组件的左上角
    canvas.translate(offset.dx, offset.dy);

    // --- 1. 绘制可交互的图片 ---
    if (_image != null) {
      canvas.save();
      // 应用 TransformationController 的变换矩阵
      canvas.transform(_controller.value.storage);
      // 绘制图片
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(
            0, 0, _image!.width.toDouble(), _image!.height.toDouble()),
        image: _image!,
        filterQuality: FilterQuality.medium,
        fit: BoxFit.contain,
      );
      canvas.restore();
    }

    // --- 2. 绘制裁剪覆盖层和边框 ---
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width, size.height) / 2 * _cropCircleRadiusRatio;

    final overlayRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // 使用 Path.combine 创建一个 "挖洞" 的路径
    final overlayPath = Path.combine(
        PathOperation.difference, Path()..addRect(overlayRect), circlePath);

    final overlayPaint = Paint()..color = _overlayColor;
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    canvas.restore();
  }

  // --- 手势处理逻辑 ---

  void _handleScaleStart(ScaleStartDetails details) {
    _initialFocalPoint = details.focalPoint;
    _initialMatrix = _controller.value.clone();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_initialMatrix == null || _initialFocalPoint == null) return;

    final scale = details.scale;
    final translationDelta = details.focalPoint - _initialFocalPoint!;

    // 创建一个从手势开始到现在的平移矩阵
    final translationMatrix =
        Matrix4.translationValues(translationDelta.dx, translationDelta.dy, 0);

    // 创建一个围绕焦点的缩放矩阵
    final scaleMatrix = Matrix4.identity()
      ..translate(details.localFocalPoint.dx, details.localFocalPoint.dy)
      ..scale(scale, scale)
      ..translate(-details.localFocalPoint.dx, -details.localFocalPoint.dy);

    // 将平移和缩放应用到初始矩阵上
    _controller.value = scaleMatrix * translationMatrix * _initialMatrix!;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _initialMatrix = null;
    _initialFocalPoint = null;
  }
}
