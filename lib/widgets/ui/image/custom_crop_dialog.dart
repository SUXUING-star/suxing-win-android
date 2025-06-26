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
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/image/hand_drawn_crop_widget.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 应用 SnackBar 工具
import 'package:vector_math/vector_math_64.dart' show Vector3; // 向量数学库
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 功能按钮组件
import 'package:path/path.dart' as p; // 路径处理库

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
        AppSnackBar.showError('无法加载图片，请重新换一张图片'); // 显示错误提示
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
        AppSnackBar.showError("图片裁剪失败，请重试"); // 显示错误提示
      }
    }
  }

  /// 构建裁剪对话框的内容界面。
  @override
  Widget build(BuildContext context) {
    final double buttonIconSize = 18.0;
    final double buttonFontSize = 15.0;
    final EdgeInsets buttonPadding =
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10);

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              '更新头像',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade700)),
                    margin: const EdgeInsets.only(right: 8.0),
                    child: LayoutBuilder(
                      // 保留LayoutBuilder以获取尺寸
                      builder: (context, constraints) {
                        // LayoutBuilder 仍然有用，用来确定初始尺寸和半径
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              (_cropAreaSize == null ||
                                  _cropAreaSize !=
                                      Size(constraints.maxWidth,
                                          constraints.maxHeight))) {
                            final newSize = Size(
                                constraints.maxWidth, constraints.maxHeight);
                            // 这里的 cropCircleRadius 只是用于计算，实际绘制由 RenderObject 负责
                            final newRadius =
                                math.min(newSize.width, newSize.height) /
                                    2 *
                                    0.85;
                            setState(() {
                              _cropAreaSize = newSize;
                              _cropCircleRadius = newRadius;
                              if (_decodedUiImage != null &&
                                  _transformationController.value ==
                                      Matrix4.identity()) {
                                _setInitialTransformation(); // 仅在未设置时设置初始变换
                              }
                            });
                          }
                        });

                        Widget content;
                        if (_isLoadingImage) {
                          content = const LoadingWidget(size: 24);
                        } else if (_originalImageBytes == null ||
                            _decodedUiImage == null) {
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
                            // ClipRect 保证手势不出界
                            child: HandDrawnCropWidget(
                              image: _decodedUiImage,
                              controller: _transformationController,
                              // cropCircleRadiusRatio 可以自定义，这里保持和原来逻辑一致
                              // 实际的半径计算和绘制都封装在 RenderObject 里了
                            ),
                          );
                        }
                        return content;
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
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
                              ? (_decodedUiImage != null && !_isLoadingImage)
                                  ? (_isPreviewLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: LoadingWidget(),
                                        )
                                      : Icon(Icons.image_not_supported_outlined,
                                          size: 40, color: Colors.grey[400]))
                                  : Icon(Icons.person,
                                      size: 60, color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(height: 15),
                        if (_decodedUiImage != null)
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
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FunctionalTextButton(
                  onPressed: _isProcessingConfirm
                      ? null
                      : () => Navigator.of(context).pop(null),
                  label: '取消',
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: (_croppedPreviewBytes != null &&
                          _croppedPreviewBytes!.isNotEmpty)
                      ? _debugDecodeImage // 按下时调用新的验货方法
                      : null,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.orange),
                  child: const Text('本地解码测试'), // 给个醒目的颜色
                ),
                const SizedBox(width: 12),
                FunctionalButton(
                  label: '确定',
                  icon: Icons.check,
                  onPressed: (_croppedPreviewBytes != null &&
                          _croppedPreviewBytes!.isNotEmpty)
                      ? _confirmCrop
                      : null,
                  isLoading: _isProcessingConfirm,
                  isEnabled: (_croppedPreviewBytes != null &&
                      _croppedPreviewBytes!.isNotEmpty &&
                      !_isProcessingConfirm &&
                      !_isLoadingImage),
                  fontSize: buttonFontSize,
                  iconSize: buttonIconSize,
                  padding: buttonPadding,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 在 _CustomCropDialogContentState 类里，加这个新方法
  Future<void> _debugDecodeImage() async {
    if (_isProcessingConfirm || _decodedImageForProcessing == null) {
      AppSnackBar.showWarning("正在处理或无图片，无法测试");
      return;
    }

    // 1. 生成最终要上传的图片数据
    final CropResult? finalResult =
        await Future(() => _performActualCrop(forPreview: false));

    if (finalResult == null || finalResult.bytes.isEmpty) {
      AppSnackBar.showError("生成最终图片失败！");
      return;
    }

    // 2. 核心：尝试解码刚刚生成的图片数据
    try {
      // 使用 image 包的 decodeImage 方法，和Go后端的 image.Decode 异曲同工
      final decoded = img.decodeImage(finalResult.bytes);

      if (decoded != null) {
        if (mounted) {
          await BaseInputDialog.show(
            context: context,
            title: "测试图片",
            contentBuilder: (context) {
              return Center(
                child: Image.memory(
                  finalResult.bytes,
                ),
              );
            },
            onConfirm: () async {
              return;
            },
          );
        }
        // 如果能解码成功，就弹个成功的提示
        AppSnackBar.showSuccess(
          "本地解码成功！\n格式: ${decoded.format}, 尺寸: ${decoded.width}x${decoded.height}",
        );
      } else {
        // 如果解码返回 null，说明文件格式不对或者损坏了
        AppSnackBar.showError(
          "本地解码失败！decodeImage返回null，文件已损坏！",
        );
      }
    } catch (e) {
      // 如果解码过程直接抛出异常，也说明文件坏了
      AppSnackBar.showError(
        "本地解码异常！文件已损坏！\n错误: ${e.toString()}",
      );
    }
  }
}
