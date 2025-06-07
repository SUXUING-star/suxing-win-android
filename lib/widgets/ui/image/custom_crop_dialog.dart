// lib/widgets/ui/image/custom_crop_dialog.dart

/// 该文件定义了自定义图片裁剪对话框组件。
/// 该组件用于图片选择、裁剪和预览。
library;

import 'dart:async'; // 异步操作所需
import 'dart:typed_data'; // 字节数据类型所需
import 'dart:ui' as ui; // dart:ui 图像处理所需
import 'dart:math' as math; // 数学运算所需
import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:image_picker/image_picker.dart'; // 图片选择器库
import 'package:image/image.dart' as img; // 图片处理库
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // 功能文本按钮组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展工具
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 应用 SnackBar 工具
import 'package:vector_math/vector_math_64.dart' show Vector3; // 向量数学库
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 功能按钮组件
import 'package:path/path.dart' as p; // 路径处理库

/// `_CropOverlayPainter` 类：自定义裁剪覆盖层绘制器。
///
/// 该绘制器在画布上绘制半透明的遮罩和裁剪圆形边框。
class _CropOverlayPainter extends CustomPainter {
  final double cropCircleRadius; // 裁剪圆形区域的半径
  final Offset centerOffset; // 裁剪区域的中心偏移

  /// 构造函数。
  ///
  /// [cropCircleRadius]：裁剪圆形半径。
  /// [centerOffset]：中心偏移。
  _CropOverlayPainter(
      {required this.cropCircleRadius, required this.centerOffset});

  /// 绘制裁剪覆盖层。
  ///
  /// [canvas]：画布。
  /// [size]：绘制区域尺寸。
  @override
  void paint(Canvas canvas, Size size) {
    final center = centerOffset; // 裁剪区域中心
    final overlayRect = Rect.fromLTWH(0, 0, size.width, size.height); // 覆盖层矩形
    final circlePath = Path()
      ..addOval(
          Rect.fromCircle(center: center, radius: cropCircleRadius)); // 裁剪圆形路径
    final overlayPath = Path.combine(PathOperation.difference,
        Path()..addRect(overlayRect), circlePath); // 结合路径
    final Paint paint = Paint()
      ..color = Colors.black.withSafeOpacity(0.6); // 绘制半透明黑色
    canvas.drawPath(overlayPath, paint); // 绘制覆盖层
    final Paint borderPaint = Paint()
      ..color = Colors.white.withSafeOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // 绘制白色边框
    canvas.drawCircle(center, cropCircleRadius, borderPaint); // 绘制圆形边框
  }

  /// 判断是否需要重绘。
  ///
  /// [oldDelegate]：旧的绘制器代理。
  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropCircleRadius != cropCircleRadius ||
        oldDelegate.centerOffset != centerOffset; // 裁剪半径或中心偏移变化时重绘
  }
}

/// `CropResult` 类：表示图片裁剪结果。
///
/// 该类封装了裁剪后的图片字节数据和输出文件扩展名。
class CropResult {
  final Uint8List bytes; // 裁剪后的图片字节数据
  final String outputExtension; // 输出文件扩展名

  /// 构造函数。
  ///
  /// [bytes]：图片字节数据。
  /// [outputExtension]：输出扩展名。
  CropResult({required this.bytes, required this.outputExtension});
}

/// `CustomCropDialog` 类：自定义图片裁剪对话框。
///
/// 该类提供静态方法用于显示裁剪对话框。
class CustomCropDialog extends StatelessWidget {
  /// 构造函数。
  const CustomCropDialog({super.key});

  /// 显示图片裁剪对话框。
  ///
  /// [context]：Build 上下文。
  /// 返回包含裁剪结果的 Future。
  static Future<CropResult?> show(BuildContext context) {
    return showDialog<CropResult?>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withSafeOpacity(0.9), // 对话框背景色
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(
                  color: Colors.grey.shade300, width: 1)), // 对话框形状和边框
          insetPadding: const EdgeInsets.all(20), // 内部填充
          child: const CustomCropDialogContent(), // 对话框内容
        );
      },
    );
  }

  /// 构建组件。
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // 返回一个空组件
  }
}

/// `CustomCropDialogContent` 类：自定义裁剪对话框的内容。
///
/// 该类负责图片选择、裁剪交互和结果预览。
class CustomCropDialogContent extends StatefulWidget {
  /// 构造函数。
  const CustomCropDialogContent({super.key});

  /// 创建状态。
  @override
  _CustomCropDialogContentState createState() =>
      _CustomCropDialogContentState();
}

/// `_CustomCropDialogContentState` 类：`CustomCropDialogContent` 的状态管理。
///
/// 管理图片加载、裁剪变换、预览更新和最终确认裁剪的逻辑。
class _CustomCropDialogContentState extends State<CustomCropDialogContent> {
  final ImagePicker _picker = ImagePicker(); // 图片选择器实例
  final TransformationController _transformationController =
      TransformationController(); // 交互式视图的变换控制器

  Uint8List? _originalImageBytes; // 原始图片字节数据
  ui.Image? _decodedUiImage; // 用于显示和获取原始尺寸的 dart:ui Image
  img.Image? _decodedImageForProcessing; // 用于实际裁剪和编码的 image 库 Image

  bool _isLoadingImage = false; // 图片是否正在加载中
  bool _isProcessingConfirm = false; // 确认裁剪是否正在处理中
  bool _isPreviewLoading = false; // 预览图是否正在加载中
  Uint8List? _croppedPreviewBytes; // 裁剪后的预览图片字节数据

  Size? _cropAreaSize; // 裁剪区域的尺寸
  double _cropCircleRadius = 0; // 裁剪圆形区域的半径
  Timer? _debounceTimer; // 防抖计时器

  String? _originalFileExtension; // 原始文件的扩展名

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onInteractionUpdate); // 监听变换控制器
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onInteractionUpdate); // 移除监听器
    _transformationController.dispose(); // 销毁控制器
    _debounceTimer?.cancel(); // 取消计时器
    super.dispose();
  }

  /// 选择图片。
  ///
  /// 从相册选择一张图片，并解码处理。
  Future<void> _pickImage() async {
    setState(() {
      _isLoadingImage = true; // 设置加载状态
      _originalImageBytes = null; // 清空旧数据
      _croppedPreviewBytes = null;
      _decodedUiImage = null;
      _decodedImageForProcessing = null;
      _originalFileExtension = null;
      _transformationController.value = Matrix4.identity(); // 重置变换
    });
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery); // 调起图片选择器
      if (pickedFile != null && mounted) {
        final bytes = await pickedFile.readAsBytes(); // 读取图片字节

        String extension =
            p.extension(pickedFile.path).toLowerCase(); // 获取文件扩展名
        if (extension == ".jpeg") {
          extension = ".jpg"; // 统一 .jpeg 为 .jpg
        }

        if (extension.isEmpty && pickedFile.mimeType != null) {
          // 根据 MIME 类型推断扩展名
          if (pickedFile.mimeType == 'image/jpeg') {
            extension = '.jpg';
          } else if (pickedFile.mimeType == 'image/png') {
            extension = '.png';
          }
        }
        _originalFileExtension = (extension == ".jpg" || extension == ".png")
            ? extension
            : ".png"; // 存储有效扩展名

        _decodedImageForProcessing = img.decodeImage(bytes); // 解码图片用于处理
        if (_decodedImageForProcessing == null) {
          throw Exception("无法解码图片格式，请重新换一张图片"); // 解码失败抛出异常
        }

        final Completer<ui.Image> completerUi = Completer(); // 创建 Completer
        ui.decodeImageFromList(bytes, (ui.Image decodedImg) {
          if (!completerUi.isCompleted) {
            completerUi.complete(decodedImg); // 解码 UI Image
          }
        });
        _decodedUiImage = await completerUi.future; // 获取 UI Image

        if (mounted) {
          setState(() {
            _originalImageBytes = bytes; // 存储原始字节
            _isLoadingImage = false; // 取消加载状态
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _setInitialTransformation(); // 设置初始变换
            });
            _schedulePreviewUpdate(); // 调度预览更新
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingImage = false); // 未选择图片时取消加载状态
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingImage = false); // 捕获异常时取消加载状态
        AppSnackBar.showError(context, '无法加载图片，请重新换一张图片'); // 显示错误提示
      }
    }
  }

  /// 设置图片初始变换。
  ///
  /// 根据裁剪区域尺寸计算图片的初始缩放和偏移。
  void _setInitialTransformation() {
    if (_decodedUiImage == null ||
        _cropAreaSize == null ||
        _cropAreaSize!.isEmpty) {
      _transformationController.value = Matrix4.identity(); // 重置变换矩阵
      return;
    }
    final imgWidth = _decodedUiImage!.width.toDouble(); // 图片原始宽度
    final imgHeight = _decodedUiImage!.height.toDouble(); // 图片原始高度
    final areaWidth = _cropAreaSize!.width; // 裁剪区域宽度
    final areaHeight = _cropAreaSize!.height; // 裁剪区域高度
    final double scaleX = areaWidth / imgWidth; // X 轴缩放比例
    final double scaleY = areaHeight / imgHeight; // Y 轴缩放比例
    final double scale = math.min(scaleX, scaleY); // 最小缩放比例
    final double displayWidth = imgWidth * scale; // 显示宽度
    final double displayHeight = imgHeight * scale; // 显示高度
    final double offsetX = (areaWidth - displayWidth) / 2.0; // X 轴偏移
    final double offsetY = (areaHeight - displayHeight) / 2.0; // Y 轴偏移
    final initialMatrix = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale); // 初始变换矩阵

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _transformationController.value = initialMatrix; // 设置变换矩阵
    });
  }

  /// 交互更新回调。
  ///
  /// 触发图片预览更新。
  void _onInteractionUpdate() {
    _schedulePreviewUpdate(); // 调度预览更新
  }

  /// 调度预览更新。
  ///
  /// 使用防抖机制，避免频繁更新预览。
  void _schedulePreviewUpdate() {
    if (_decodedImageForProcessing == null || _isLoadingImage || !mounted) {
      return; // 不满足条件时返回
    }
    _debounceTimer?.cancel(); // 取消现有计时器
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _updatePreview(); // 计时器结束后更新预览
    });
  }

  /// 更新图片预览。
  ///
  /// 执行实际裁剪操作以生成预览图。
  Future<void> _updatePreview() async {
    if (_decodedImageForProcessing == null || !mounted) return; // 不满足条件时返回
    if (mounted) setState(() => _isPreviewLoading = true); // 设置预览加载状态

    final result =
        await Future(() => _performActualCrop(forPreview: true)); // 执行裁剪生成预览
    if (mounted) {
      setState(() {
        _croppedPreviewBytes = result?.bytes; // 更新预览字节
        _isPreviewLoading = false; // 取消预览加载状态
      });
    }
  }

  /// 计算裁剪矩形。
  ///
  /// 根据 InteractiveViewer 的变换矩阵和裁剪区域计算图片上的实际裁剪矩形。
  Rect _calculateCropRect() {
    if (_decodedUiImage == null ||
        _cropAreaSize == null ||
        _cropCircleRadius <= 0) {
      return Rect.zero; // 返回空矩形
    }
    final Matrix4 matrix = _transformationController.value; // 获取当前变换矩阵
    final Offset cropAreaCenter =
        Offset(_cropAreaSize!.width / 2, _cropAreaSize!.height / 2); // 裁剪区域中心
    final Rect widgetCropRect = Rect.fromCircle(
        center: cropAreaCenter, radius: _cropCircleRadius); // 裁剪区域矩形

    final Matrix4 inverseMatrix = Matrix4.inverted(matrix); // 获取逆变换矩阵

    final Vector3 topLeft = inverseMatrix.transform3(
        Vector3(widgetCropRect.left, widgetCropRect.top, 0)); // 变换后的左上角
    final Vector3 topRight = inverseMatrix.transform3(
        Vector3(widgetCropRect.right, widgetCropRect.top, 0)); // 变换后的右上角
    final Vector3 bottomLeft = inverseMatrix.transform3(
        Vector3(widgetCropRect.left, widgetCropRect.bottom, 0)); // 变换后的左下角
    final Vector3 bottomRight = inverseMatrix.transform3(
        Vector3(widgetCropRect.right, widgetCropRect.bottom, 0)); // 变换后的右下角

    final double minX = [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x]
        .reduce(math.min); // 最小 X 坐标
    final double maxX = [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x]
        .reduce(math.max); // 最大 X 坐标
    final double minY = [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y]
        .reduce(math.min); // 最小 Y 坐标
    final double maxY = [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y]
        .reduce(math.max); // 最大 Y 坐标

    Rect imageRect = Rect.fromLTRB(minX, minY, maxX, maxY); // 裁剪后的图片矩形

    final Rect imageBounds = Rect.fromLTWH(
        0,
        0,
        _decodedUiImage!.width.toDouble(),
        _decodedUiImage!.height.toDouble()); // 图片原始边界
    imageRect = imageRect.intersect(imageBounds); // 裁剪矩形与图片边界求交集

    if (imageRect.width < 1 || imageRect.height < 1) {
      return Rect.zero; // 裁剪结果无效时返回空矩形
    }

    final double finalSize =
        math.min(imageRect.width, imageRect.height); // 最终尺寸
    final Offset finalCenter = imageRect.center; // 最终中心点
    imageRect = Rect.fromCenter(
            center: finalCenter, width: finalSize, height: finalSize)
        .intersect(imageBounds); // 再次裁剪为正方形并与图片边界求交集

    if (imageRect.width < 1 || imageRect.height < 1) {
      return Rect.zero; // 裁剪结果无效时返回空矩形
    }
    return imageRect;
  }

  /// 执行实际的图片裁剪操作。
  ///
  /// [forPreview]：是否为预览裁剪。
  /// 返回裁剪结果 [CropResult]。
  CropResult? _performActualCrop({bool forPreview = false}) {
    if (_decodedImageForProcessing == null) return null; // 未解码图片时返回 null

    final Rect cropRect = _calculateCropRect(); // 计算裁剪矩形
    if (cropRect.isEmpty) return null; // 裁剪矩形为空时返回 null

    img.Image? sourceImage = _decodedImageForProcessing; // 源图片

    img.Image cropped = img.copyCrop(
      sourceImage!,
      x: cropRect.left.round(), // 裁剪起始 X 坐标
      y: cropRect.top.round(), // 裁剪起始 Y 坐标
      width: cropRect.width.round(), // 裁剪宽度
      height: cropRect.height.round(), // 裁剪高度
    );

    /// 应用圆形遮罩。
    final img.Image circularImage = img.Image(
        width: cropped.width,
        height: cropped.height,
        numChannels: 4); // 创建带 alpha 通道的图像

    final int centerX = circularImage.width ~/ 2; // 圆心 X 坐标
    final int centerY = circularImage.height ~/ 2; // 圆心 Y 坐标
    final int radius = math.min(centerX, centerY); // 半径

    for (int y = 0; y < circularImage.height; ++y) {
      for (int x = 0; x < circularImage.width; ++x) {
        final num distSq =
            math.pow(x - centerX, 2) + math.pow(y - centerY, 2); // 计算距离平方
        if (distSq <= math.pow(radius, 2)) {
          final img.Pixel pixel = cropped.getPixel(x, y); // 获取像素
          circularImage.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(),
              pixel.b.toInt(), pixel.a.toInt()); // 设置像素
        } else {
          circularImage.setPixelRgba(x, y, 0, 0, 0, 0); // 设置为透明像素
        }
      }
    }

    Uint8List resultBytes; // 结果字节数据
    String outputExtension = _originalFileExtension ?? ".png"; // 默认输出 png

    if (outputExtension == ".jpg") {
      // 输出为 JPG 格式
      img.Image imageForJpg;
      if (circularImage.numChannels == 4) {
        // 如果是 RGBA 格式
        imageForJpg = img.Image(
            width: circularImage.width,
            height: circularImage.height,
            format: img.Format.uint8,
            numChannels: 3); // 创建 RGB 格式图像
        img.fill(imageForJpg, color: img.ColorRgb8(255, 255, 255)); // 填充白色背景
        img.compositeImage(imageForJpg, circularImage); // 合成图像
      } else {
        imageForJpg = circularImage;
      }
      resultBytes = Uint8List.fromList(
          img.encodeJpg(imageForJpg, quality: 90)); // 编码为 JPG
    } else {
      outputExtension = ".png"; // 确保后缀正确
      resultBytes = Uint8List.fromList(img.encodePng(circularImage)); // 编码为 PNG
    }

    return CropResult(
        bytes: resultBytes, outputExtension: outputExtension); // 返回裁剪结果
  }

  /// 确认裁剪。
  ///
  /// 执行最终裁剪并返回结果。
  void _confirmCrop() async {
    if (_isProcessingConfirm || _decodedImageForProcessing == null) {
      return; // 正在处理或未解码图片时返回
    }

    setState(() => _isProcessingConfirm = true); // 设置处理状态

    final CropResult? finalResult =
        await Future(() => _performActualCrop(forPreview: false)); // 执行最终裁剪

    if (mounted) {
      // 检查组件是否挂载
      setState(() => _isProcessingConfirm = false); // 取消处理状态
      if (finalResult != null && finalResult.bytes.isNotEmpty) {
        // 裁剪结果有效
        Navigator.of(context).pop(finalResult); // 返回裁剪结果
      } else {
        Navigator.of(context).pop(null); // 返回 null
        AppSnackBar.showError(context, "图片裁剪失败，请重试"); // 显示错误提示
      }
    }
  }

  /// 构建裁剪对话框的内容界面。
  @override
  Widget build(BuildContext context) {
    final double buttonIconSize = 18.0; // 按钮图标大小
    final double buttonFontSize = 15.0; // 按钮字体大小
    final EdgeInsets buttonPadding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10); // 按钮内边距

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0), // 容器内边距
      child: Column(
        mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化以适应内容
        crossAxisAlignment: CrossAxisAlignment.stretch, // 交叉轴拉伸
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0), // 底部填充
            child: Text(
              '更新头像', // 标题文本
              style: Theme.of(context).textTheme.headlineSmall, // 文本样式
              textAlign: TextAlign.center, // 文本居中
            ),
          ),
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 交叉轴拉伸
              children: [
                Expanded(
                  flex: 6, // 裁剪区域宽度比例
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.grey.shade700)), // 裁剪区域装饰
                    margin: const EdgeInsets.only(right: 8.0), // 右侧外边距
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              (_cropAreaSize == null ||
                                  _cropAreaSize !=
                                      Size(constraints.maxWidth,
                                          constraints.maxHeight))) {
                            // 裁剪区域尺寸变化时
                            final newSize = Size(constraints.maxWidth,
                                constraints.maxHeight); // 新尺寸
                            final newRadius =
                                math.min(newSize.width, newSize.height) /
                                    2 *
                                    0.85; // 新半径
                            setState(() {
                              _cropAreaSize = newSize; // 更新裁剪区域尺寸
                              _cropCircleRadius = newRadius; // 更新裁剪圆形半径
                              if (_decodedUiImage != null) {
                                _setInitialTransformation(); // 设置初始变换
                              }
                            });
                          }
                        });

                        final currentCropAreaSize = _cropAreaSize ??
                            Size(constraints.maxWidth,
                                constraints.maxHeight); // 当前裁剪区域尺寸
                        final currentRadius = _cropCircleRadius > 0
                            ? _cropCircleRadius
                            : math.min(constraints.maxWidth,
                                    constraints.maxHeight) /
                                2 *
                                0.85; // 当前裁剪半径
                        final centerOffset = Offset(
                            currentCropAreaSize.width / 2,
                            currentCropAreaSize.height / 2); // 中心偏移

                        Widget content; // 内容组件
                        if (_isLoadingImage) {
                          content = LoadingWidget.inline(size: 24); // 显示加载动画
                        } else if (_originalImageBytes == null ||
                            _decodedUiImage == null) {
                          content = Center(
                            child: FunctionalButton(
                              icon: Icons.upload_file, // 上传文件图标
                              label: '选择图片', // 按钮文本
                              onPressed: _pickImage, // 点击回调
                              foregroundColor: Colors.black, // 前景色
                              backgroundColor: Colors.white, // 背景色
                            ),
                          );
                        } else {
                          content = ClipRect(
                            // 裁剪矩形
                            child: Stack(
                              alignment: Alignment.center, // 堆栈内容居中
                              children: [
                                InteractiveViewer(
                                  // 交互式查看器
                                  transformationController:
                                      _transformationController, // 变换控制器
                                  boundaryMargin: const EdgeInsets.all(
                                      double.infinity), // 边界边距
                                  minScale: 0.1, // 最小缩放
                                  maxScale: 10.0, // 最大缩放
                                  constrained: false, // 不受约束
                                  child: Image.memory(
                                      _originalImageBytes!, // 原始图片字节
                                      key: ValueKey(
                                          _originalImageBytes!.hashCode), // 唯一键
                                      fit: BoxFit.contain, // 填充模式
                                      alignment: Alignment.center, // 对齐方式
                                      filterQuality:
                                          FilterQuality.medium), // 过滤质量
                                ),
                                IgnorePointer(
                                  // 忽略指针事件
                                  child: CustomPaint(
                                    size: currentCropAreaSize, // 尺寸
                                    painter: _CropOverlayPainter(
                                        cropCircleRadius: currentRadius,
                                        centerOffset: centerOffset), // 绘制器
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return content; // 返回内容
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 4, // 预览区域宽度比例
                  child: Container(
                    padding: const EdgeInsets.all(16.0), // 内边距
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8)), // 装饰
                    margin: const EdgeInsets.only(left: 8.0), // 左侧外边距
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                      crossAxisAlignment: CrossAxisAlignment.center, // 水平居中
                      children: [
                        const Text('效果预览',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500)), // 预览标题
                        const SizedBox(height: 20), // 间距
                        CircleAvatar(
                          radius: 60, // 半径
                          backgroundColor: Colors.grey.shade200, // 背景色
                          backgroundImage: (_croppedPreviewBytes != null &&
                                  _croppedPreviewBytes!.isNotEmpty)
                              ? MemoryImage(_croppedPreviewBytes!) // 预览图片
                              : null,
                          child: (_croppedPreviewBytes == null ||
                                  _croppedPreviewBytes!.isEmpty)
                              ? (_decodedUiImage != null && !_isLoadingImage)
                                  ? (_isPreviewLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)) // 预览加载动画
                                      : Icon(Icons.image_not_supported_outlined,
                                          size: 40,
                                          color: Colors.grey[400])) // 预览失败图标
                                  : Icon(Icons.person, // 初始状态图标
                                      size: 60,
                                      color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(height: 15), // 间距
                        if (_decodedUiImage != null) // 显示重新选择按钮
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 18), // 刷新图标
                            label: const Text('重新选择'), // 按钮文本
                            onPressed: _pickImage, // 点击回调
                            style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .secondary, // 字体颜色
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6), // 内边距
                                textStyle:
                                    const TextStyle(fontSize: 14)), // 文本样式
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0), // 内边距
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // 主轴末尾对齐
              children: [
                FunctionalTextButton(
                  onPressed: _isProcessingConfirm
                      ? null
                      : () => Navigator.of(context).pop(null), // 取消按钮点击回调
                  label: '取消', // 按钮文本
                ),
                const SizedBox(width: 12), // 间距
                FunctionalButton(
                  label: '确定', // 按钮文本
                  icon: Icons.check, // 图标
                  onPressed: (_croppedPreviewBytes != null &&
                          _croppedPreviewBytes!.isNotEmpty)
                      ? _confirmCrop
                      : null, // 仅当预览有效时可点击确定
                  isLoading: _isProcessingConfirm, // 加载状态
                  isEnabled: (_croppedPreviewBytes != null &&
                      _croppedPreviewBytes!.isNotEmpty &&
                      !_isProcessingConfirm &&
                      !_isLoadingImage), // 启用状态
                  fontSize: buttonFontSize, // 字体大小
                  iconSize: buttonIconSize, // 图标大小
                  padding: buttonPadding, // 内边距
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
