// custom_crop_dialog.dart (完整代码，直接复用 FunctionalButton)

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // Image 库
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../../../../widgets/ui/buttons/functional_button.dart';
import '../../../../utils/font/font_config.dart';

// --- 裁剪框绘制 Painter ---
class _CropOverlayPainter extends CustomPainter {
  final double cropCircleRadius;
  final Offset centerOffset;

  _CropOverlayPainter(
      {required this.cropCircleRadius, required this.centerOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final center = centerOffset;
    final overlayRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: cropCircleRadius));
    final overlayPath = Path.combine(
        PathOperation.difference, Path()..addRect(overlayRect), circlePath);
    final Paint paint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawPath(overlayPath, paint);
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, cropCircleRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropCircleRadius != cropCircleRadius ||
        oldDelegate.centerOffset != centerOffset;
  }
}

// --- Dialog 的入口 (保持不变) ---
class CustomCropDialog extends StatelessWidget {
  // 改回 StatelessWidget，因为状态在 Content 里
  const CustomCropDialog({super.key});

  static Future<Uint8List?> show(BuildContext context) {
    return showDialog<Uint8List?>(
      context: context,
      builder: (BuildContext context) {
        return Opacity(
          opacity: 0.9,
          child: Dialog(
            backgroundColor: Colors.white, // 白色，接近不透明
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: Colors.grey.shade300, width: 1)),
            insetPadding: const EdgeInsets.all(20),
            child: const CustomCropDialogContent(), // Dialog 内容由这个 Widget 负责
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 这个 Widget 本身不构建 UI，只是 showDialog 的一个静态方法入口
    // 返回一个占位符或者直接抛出错误表明它不应该被直接构建
    return const SizedBox.shrink(); // 或者 throw UnimplementedError();
  }
}

class CustomCropDialogContent extends StatefulWidget {
  const CustomCropDialogContent({super.key});

  @override
  _CustomCropDialogContentState createState() =>
      _CustomCropDialogContentState();
}

class _CustomCropDialogContentState extends State<CustomCropDialogContent> {
  // --- 状态变量 (和之前一样) ---
  final ImagePicker _picker = ImagePicker();
  final TransformationController _transformationController =
      TransformationController();
  Uint8List? _originalImageBytes;
  Uint8List? _croppedPreviewBytes;
  ui.Image? _decodedImage;
  bool _isLoadingImage = false;
  bool _isProcessing = false; // 控制“确定”按钮的加载状态
  bool _isPreviewLoading = false;
  Size? _cropAreaSize;
  double _cropCircleRadius = 0;
  Timer? _debounceTimer;
  // --- 结束 状态变量 ---

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onInteractionUpdate);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onInteractionUpdate);
    _transformationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // --- 图片选择逻辑 (包含初始缩放) ---
  Future<void> _pickImage() async {
    setState(() {
      _isLoadingImage = true;
      _originalImageBytes = null;
      _croppedPreviewBytes = null;
      _decodedImage = null;
      _transformationController.value = Matrix4.identity();
    });
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        final bytes = await pickedFile.readAsBytes();
        final Completer<ui.Image> completer = Completer();
        ui.decodeImageFromList(bytes, (ui.Image img) {
          if (!completer.isCompleted) completer.complete(img);
        });
        _decodedImage = await completer.future;
        if (mounted) {
          setState(() {
            _originalImageBytes = bytes;
            _isLoadingImage = false;
            // 等待下一帧布局完成后再设置初始变换，确保 _cropAreaSize 有效
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _setInitialTransformation();
            });
            _schedulePreviewUpdate();
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingImage = false);
      }
    } catch (e) {
      /* ... 错误处理 ... */
      print("Error picking image: $e");
      if (mounted) {
        setState(() => _isLoadingImage = false);
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text('无法加载图片: $e')));
      }
    }
  }
  // --- 结束 图片选择逻辑 ---

  // --- 设置初始变换 (保持不变) ---
  void _setInitialTransformation() {
    if (_decodedImage == null ||
        _cropAreaSize == null ||
        _cropAreaSize!.isEmpty) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    final imgWidth = _decodedImage!.width.toDouble();
    final imgHeight = _decodedImage!.height.toDouble();
    final areaWidth = _cropAreaSize!.width;
    final areaHeight = _cropAreaSize!.height;
    final double scaleX = areaWidth / imgWidth;
    final double scaleY = areaHeight / imgHeight;
    final double scale = math.min(scaleX, scaleY);
    final double displayWidth = imgWidth * scale;
    final double displayHeight = imgHeight * scale;
    final double offsetX = (areaWidth - displayWidth) / 2.0;
    final double offsetY = (areaHeight - displayHeight) / 2.0;
    final initialMatrix = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale);
    // 避免在 build 期间直接赋值，如果还在 build 阶段
    // 可以用 addPostFrameCallback 或者直接赋值（如果能确保不在 build 中）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _transformationController.value = initialMatrix;
    });
    // _transformationController.value = initialMatrix; // 或者直接这样，如果调用时机安全
    print(
        "Initial transformation set: scale=$scale, offset=($offsetX, $offsetY)");
  }
  // --- 结束 设置初始变换 ---

  // --- 预览更新和防抖 (保持不变) ---
  void _onInteractionUpdate() {
    _schedulePreviewUpdate();
  }

  void _schedulePreviewUpdate() {
    if (_originalImageBytes == null || _isLoadingImage || !mounted) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _updatePreview();
    });
  }

  Future<void> _updatePreview() async {
    if (_originalImageBytes == null || !mounted) return;
    if (mounted) setState(() => _isPreviewLoading = true);
    final previewBytes = await Future(() => _performCrop(isPreview: true));
    if (mounted) {
      setState(() {
        _croppedPreviewBytes = previewBytes;
        _isPreviewLoading = false;
      });
    }
  }
  // --- 结束 预览更新和防抖 ---

  // --- 计算裁剪矩形 (保持不变) ---
  Rect _calculateCropRect() {
    if (_decodedImage == null ||
        _cropAreaSize == null ||
        _cropCircleRadius <= 0) {
      return Rect.zero;
    }
    final Matrix4 matrix = _transformationController.value;
    final Offset cropAreaCenter =
        Offset(_cropAreaSize!.width / 2, _cropAreaSize!.height / 2);
    final Rect widgetCropRect =
        Rect.fromCircle(center: cropAreaCenter, radius: _cropCircleRadius);
    final Matrix4 inverseMatrix = Matrix4.inverted(matrix);
    final Vector3 topLeft = inverseMatrix
        .transform3(Vector3(widgetCropRect.left, widgetCropRect.top, 0));
    final Vector3 topRight = inverseMatrix
        .transform3(Vector3(widgetCropRect.right, widgetCropRect.top, 0));
    final Vector3 bottomLeft = inverseMatrix
        .transform3(Vector3(widgetCropRect.left, widgetCropRect.bottom, 0));
    final Vector3 bottomRight = inverseMatrix
        .transform3(Vector3(widgetCropRect.right, widgetCropRect.bottom, 0));
    final double minX =
        [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x].reduce(math.min);
    final double maxX =
        [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x].reduce(math.max);
    final double minY =
        [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y].reduce(math.min);
    final double maxY =
        [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y].reduce(math.max);
    Rect imageRect = Rect.fromLTRB(minX, minY, maxX, maxY);
    final Rect imageBounds = Rect.fromLTWH(0, 0,
        _decodedImage!.width.toDouble(), _decodedImage!.height.toDouble());
    imageRect = imageRect.intersect(imageBounds);
    if (imageRect.width < 1 || imageRect.height < 1) return Rect.zero;
    final double finalSize = math.min(imageRect.width, imageRect.height);
    final Offset finalCenter = imageRect.center;
    imageRect = Rect.fromCenter(
            center: finalCenter, width: finalSize, height: finalSize)
        .intersect(imageBounds);
    if (imageRect.width < 1 || imageRect.height < 1) return Rect.zero;
    return imageRect;
  }
  // --- 结束 计算裁剪矩形 ---

  // --- 执行裁剪 (保持不变) ---
  Uint8List? _performCrop({bool isPreview = false}) {
    if (_decodedImage == null || _originalImageBytes == null) return null;
    final Rect cropRect = _calculateCropRect();
    if (cropRect == Rect.zero || cropRect.width <= 0 || cropRect.height <= 0)
      return null;
    img.Image? originalImg = img.decodeImage(_originalImageBytes!);
    if (originalImg == null) return null;
    img.Image? croppedRectImage;
    img.Image? finalCircularImage;
    try {
      final int cropX = math.max(0, cropRect.left.round());
      final int cropY = math.max(0, cropRect.top.round());
      final int cropW =
          math.min(cropRect.width.round(), originalImg.width - cropX);
      final int cropH =
          math.min(cropRect.height.round(), originalImg.height - cropY);
      if (cropW <= 0 || cropH <= 0) return null;
      croppedRectImage = img.copyCrop(originalImg,
          x: cropX, y: cropY, width: cropW, height: cropH);
      final int centerX = croppedRectImage.width ~/ 2;
      final int centerY = croppedRectImage.height ~/ 2;
      final int radius = math.min(centerX, centerY);
      finalCircularImage = img.Image(
          width: croppedRectImage.width,
          height: croppedRectImage.height,
          numChannels: 4);
      for (int y = 0; y < finalCircularImage.height; ++y) {
        for (int x = 0; x < finalCircularImage.width; ++x) {
          final num distSq =
              math.pow(x - centerX, 2) + math.pow(y - centerY, 2);
          if (distSq <= math.pow(radius, 2)) {
            final img.Pixel pixel = croppedRectImage.getPixel(x, y);
            finalCircularImage.setPixelRgba(x, y, pixel.r.toInt(),
                pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt());
          } else {
            finalCircularImage.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        }
      }
      final resultBytes = img.encodePng(finalCircularImage);
      return Uint8List.fromList(resultBytes);
    } catch (e, stacktrace) {
      print(
          "_performCrop Error: Exception during image processing: $e\n$stacktrace");
      return null;
    }
  }
  // --- 结束 执行裁剪 ---

  // --- 确认裁剪 (保持不变) ---
  void _confirmCrop() {
    if (_isProcessing || _croppedPreviewBytes == null) return;
    setState(() => _isProcessing = true);
    final finalBytes = _croppedPreviewBytes;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isProcessing = false);
        Navigator.of(context).pop(finalBytes);
      }
    });
  }

  // --- **完整且使用 FunctionalButton** 的构建 UI 方法 ---
  @override
  Widget build(BuildContext context) {
    // Dialog 内容部分的 context
    // 获取主题颜色
    final Color secondaryColor =
        Theme.of(context).colorScheme.secondary; // 用于取消按钮
    final Color disabledColor = Colors.grey.shade400; // 用于禁用状态

    // --- FunctionalButton 的通用参数 ---
    final double buttonIconSize = 18.0;
    final double buttonFontSize = 15.0;
    final EdgeInsets buttonPadding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10);

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0), // 内容区域的内边距
      child: Column(
        mainAxisSize: MainAxisSize.min, // 高度自适应
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 标题 ---
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              '更新头像',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),

          // --- 上部：左右布局 ---
          // 使用 Flexible 包裹 Row，使其在 Column 中可扩展但高度由内容或父级限制
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 左侧面板：上传和裁剪区域 ---
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade700)),
                    margin: const EdgeInsets.only(right: 8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 使用 PostFrameCallback 安全地更新状态
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              (_cropAreaSize == null ||
                                  _cropAreaSize !=
                                      Size(constraints.maxWidth,
                                          constraints.maxHeight))) {
                            // 必须在 setState 外部计算新值
                            final newSize = Size(
                                constraints.maxWidth, constraints.maxHeight);
                            final newRadius =
                                math.min(newSize.width, newSize.height) /
                                    2 *
                                    0.85;
                            setState(() {
                              _cropAreaSize = newSize;
                              _cropCircleRadius = newRadius;
                              // 如果是首次布局或尺寸变化，并且有图片，重新计算初始变换
                              if (_originalImageBytes != null) {
                                _setInitialTransformation(); // 确保在状态更新后调用
                              }
                            });
                          }
                        });

                        // 确保在访问 _cropAreaSize 前它已被初始化 (或提供默认值)
                        final currentCropAreaSize = _cropAreaSize ??
                            Size(constraints.maxWidth, constraints.maxHeight);
                        final currentRadius = _cropCircleRadius > 0
                            ? _cropCircleRadius
                            : math.min(constraints.maxWidth,
                                    constraints.maxHeight) /
                                2 *
                                0.85;
                        final centerOffset = Offset(
                            currentCropAreaSize.width / 2,
                            currentCropAreaSize.height / 2);

                        Widget content;
                        if (_isLoadingImage) {
                          content = LoadingWidget.inline(
                            size: 24,
                          );
                        } else if (_originalImageBytes == null) {
                          content = Center(
                            child: FunctionalButton(
                              icon: Icons.upload_file,
                              label: '选择图片',
                              onPressed: _pickImage,
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                            ),
                          );
                        } else {
                          content = ClipRect(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                InteractiveViewer(
                                  transformationController:
                                      _transformationController,
                                  boundaryMargin:
                                      const EdgeInsets.all(double.infinity),
                                  minScale: 0.1,
                                  maxScale: 10.0,
                                  constrained: false,
                                  child: Image.memory(_originalImageBytes!,
                                      key: ValueKey(
                                          _originalImageBytes!.hashCode),
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      filterQuality: FilterQuality.medium),
                                ),
                                IgnorePointer(
                                  child: CustomPaint(
                                    /* ... 遮罩层 ... */
                                    size: currentCropAreaSize, // 使用当前尺寸
                                    painter: _CropOverlayPainter(
                                        cropCircleRadius: currentRadius,
                                        centerOffset: centerOffset),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return content;
                      },
                    ),
                  ),
                ),

                // --- 右侧面板：效果预览 ---
                Expanded(
                  flex: 4,
                  child: Container(
                    /* ... 预览区域容器 ... */
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8)),
                    margin: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('效果预览',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (_croppedPreviewBytes != null &&
                                  _croppedPreviewBytes!.isNotEmpty)
                              ? MemoryImage(_croppedPreviewBytes!)
                              : null,
                          child: (_croppedPreviewBytes == null ||
                                  _croppedPreviewBytes!.isEmpty)
                              ? (_originalImageBytes != null &&
                                      !_isLoadingImage)
                                  ? (_isPreviewLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      Colors.grey))))
                                  : const Icon(Icons.person,
                                      size: 60, color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(height: 15),
                        if (_originalImageBytes != null) /* ... 重新选择按钮 ... */
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('重新选择'),
                            onPressed: _pickImage,
                            style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 14)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ), // --- 结束 上部 Row (Flexible) ---

          // --- 底部：操作按钮 (使用 FunctionalButton 和 TextButton) ---
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 取消按钮 (使用 TextButton 以示区分)
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: secondaryColor, // 使用次要颜色
                      disabledForegroundColor: disabledColor.withOpacity(0.7),
                      padding: buttonPadding, // 统一 padding
                      textStyle: TextStyle(
                        // 统一字体
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: FontConfig.defaultFontFamily,
                        fontFamilyFallback: FontConfig.fontFallback,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)) // 统一圆角
                      ),
                  onPressed: _isProcessing
                      ? null
                      : () => Navigator.of(context).pop(null),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),

                // *** 确定按钮 (直接使用 FunctionalButton) ***
                FunctionalButton(
                  label: '确定',
                  icon: Icons.check, // 可以用 '确定' 图标
                  onPressed: _confirmCrop, // 传递确认方法
                  isLoading: _isProcessing, // 控制加载状态
                  // 禁用条件：正在处理 或 没有有效的预览图
                  isEnabled: (_croppedPreviewBytes != null &&
                      _croppedPreviewBytes!.isNotEmpty &&
                      !_isProcessing),
                  // 可以传递其他 FunctionalButton 的参数来统一外观
                  fontSize: buttonFontSize,
                  iconSize: buttonIconSize,
                  padding: buttonPadding,
                ),
              ],
            ),
          ), // --- 结束 底部按钮 ---
        ],
      ),
    );
  }
}
