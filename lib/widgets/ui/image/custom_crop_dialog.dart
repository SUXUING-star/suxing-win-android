// custom_crop_dialog.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/utils/font/font_config.dart';
import 'package:path/path.dart' as p;

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
    final Paint paint = Paint()..color = Colors.black.withSafeOpacity(0.6);
    canvas.drawPath(overlayPath, paint);
    final Paint borderPaint = Paint()
      ..color = Colors.white.withSafeOpacity(0.8)
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

class CropResult {
  final Uint8List bytes;
  final String outputExtension; // ".jpg" or ".png"

  CropResult({required this.bytes, required this.outputExtension});
}

class CustomCropDialog extends StatelessWidget {
  const CustomCropDialog({super.key});

  static Future<CropResult?> show(BuildContext context) {
    return showDialog<CropResult?>(
      context: context,
      builder: (BuildContext context) {
        return Opacity(
          opacity: 0.9,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: Colors.grey.shade300, width: 1)),
            insetPadding: const EdgeInsets.all(20),
            child: const CustomCropDialogContent(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CustomCropDialogContent extends StatefulWidget {
  const CustomCropDialogContent({super.key});

  @override
  _CustomCropDialogContentState createState() =>
      _CustomCropDialogContentState();
}

class _CustomCropDialogContentState extends State<CustomCropDialogContent> {
  final ImagePicker _picker = ImagePicker();
  final TransformationController _transformationController =
      TransformationController();

  Uint8List? _originalImageBytes; // 保存原始图片字节
  ui.Image? _decodedUiImage; // dart:ui Image 用于显示和获取原始尺寸
  img.Image? _decodedImageForProcessing; // image库的Image 用于实际裁剪和编码

  bool _isLoadingImage = false;
  bool _isProcessingConfirm = false;
  bool _isPreviewLoading = false;
  Uint8List? _croppedPreviewBytes;

  Size? _cropAreaSize;
  double _cropCircleRadius = 0;
  Timer? _debounceTimer;

  String? _originalFileExtension; // 存储原始文件的推断格式 (文件扩展名)

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

  Future<void> _pickImage() async {
    setState(() {
      _isLoadingImage = true;
      _originalImageBytes = null;
      _croppedPreviewBytes = null;
      _decodedUiImage = null;
      _decodedImageForProcessing = null;
      _originalFileExtension = null;
      _transformationController.value = Matrix4.identity();
    });
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        final bytes = await pickedFile.readAsBytes();

        String extension = p.extension(pickedFile.path).toLowerCase();
        if (extension == ".jpeg") {
          extension = ".jpg";
        }

        if (extension.isEmpty && pickedFile.mimeType != null) {
          if (pickedFile.mimeType == 'image/jpeg') {
            extension = '.jpg';
          } else if (pickedFile.mimeType == 'image/png') {
            extension = '.png';
          }
        }
        // 如果还是无法判断，或不是jpg/png，则后续执行裁剪时默认输出png
        _originalFileExtension =
            (extension == ".jpg" || extension == ".png") ? extension : ".png";

        _decodedImageForProcessing = img.decodeImage(bytes);
        if (_decodedImageForProcessing == null) {
          throw Exception("无法解码图片格式，请重新换一张图片");
        }

        final Completer<ui.Image> completerUi = Completer();
        ui.decodeImageFromList(bytes, (ui.Image decodedImg) {
          if (!completerUi.isCompleted) completerUi.complete(decodedImg);
        });
        _decodedUiImage = await completerUi.future;

        if (mounted) {
          setState(() {
            _originalImageBytes = bytes;
            _isLoadingImage = false;
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
      if (mounted) {
        setState(() => _isLoadingImage = false);
        AppSnackBar.showError(context, '无法加载图片，请重新换一张图片');
      }
    }
  }

  void _setInitialTransformation() {
    if (_decodedUiImage == null ||
        _cropAreaSize == null ||
        _cropAreaSize!.isEmpty) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    final imgWidth = _decodedUiImage!.width.toDouble();
    final imgHeight = _decodedUiImage!.height.toDouble();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _transformationController.value = initialMatrix;
    });
  }

  void _onInteractionUpdate() {
    _schedulePreviewUpdate();
  }

  void _schedulePreviewUpdate() {
    if (_decodedImageForProcessing == null || _isLoadingImage || !mounted) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _updatePreview();
    });
  }

  Future<void> _updatePreview() async {
    if (_decodedImageForProcessing == null || !mounted) return;
    if (mounted) setState(() => _isPreviewLoading = true);

    final result = await Future(() => _performActualCrop(forPreview: true));
    if (mounted) {
      setState(() {
        _croppedPreviewBytes = result?.bytes;
        _isPreviewLoading = false;
      });
    }
  }

  Rect _calculateCropRect() {
    if (_decodedUiImage == null || // 使用ui.Image获取真实尺寸
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
        _decodedUiImage!.width.toDouble(), _decodedUiImage!.height.toDouble());
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

  CropResult? _performActualCrop({bool forPreview = false}) {
    if (_decodedImageForProcessing == null) return null;

    final Rect cropRect = _calculateCropRect();
    if (cropRect.isEmpty) return null;

    img.Image? sourceImage = _decodedImageForProcessing;
    // 如果解码后的图像与用于计算尺寸的图像不同（例如，因为字节数组被重用或修改），
    // 最好每次都从_originalImageBytes重新解码，或者确保_decodedImageForProcessing是只读的。
    // 为简单起见，我们假设_decodedImageForProcessing是本次裁剪操作的正确源。

    img.Image cropped = img.copyCrop(
      sourceImage!,
      x: cropRect.left.round(),
      y: cropRect.top.round(),
      width: cropRect.width.round(),
      height: cropRect.height.round(),
    );

    // 应用圆形遮罩
    // 创建一个带alpha通道的图像副本用于圆形处理
    final img.Image circularImage =
        img.Image(width: cropped.width, height: cropped.height, numChannels: 4);

    final int centerX = circularImage.width ~/ 2;
    final int centerY = circularImage.height ~/ 2;
    final int radius = math.min(centerX, centerY);

    for (int y = 0; y < circularImage.height; ++y) {
      for (int x = 0; x < circularImage.width; ++x) {
        final num distSq = math.pow(x - centerX, 2) + math.pow(y - centerY, 2);
        if (distSq <= math.pow(radius, 2)) {
          final img.Pixel pixel = cropped.getPixel(x, y);
          circularImage.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(),
              pixel.b.toInt(), pixel.a.toInt());
        } else {
          circularImage.setPixelRgba(x, y, 0, 0, 0, 0); // 透明
        }
      }
    }

    Uint8List resultBytes;
    String outputExtension = _originalFileExtension ?? ".png"; // 默认输出png

    if (outputExtension == ".jpg") {
      img.Image imageForJpg;
      // 如果 circularImage 是 RGBA (numChannels == 4)，需要合成到不透明背景
      if (circularImage.numChannels == 4) {
        imageForJpg = img.Image(
            width: circularImage.width,
            height: circularImage.height,
            format: img.Format.uint8,
            numChannels: 3);
        img.fill(imageForJpg, color: img.ColorRgb8(255, 255, 255)); // 白色背景
        img.compositeImage(imageForJpg, circularImage);
      } else {
        imageForJpg = circularImage;
      }
      resultBytes = Uint8List.fromList(img.encodeJpg(imageForJpg, quality: 90));
    } else {
      // 默认或明确是 .png
      outputExtension = ".png"; // 确保后缀正确
      resultBytes = Uint8List.fromList(img.encodePng(circularImage));
    }

    return CropResult(bytes: resultBytes, outputExtension: outputExtension);
  }

  void _confirmCrop() async {
    if (_isProcessingConfirm || _decodedImageForProcessing == null) return;

    setState(() => _isProcessingConfirm = true);

    // 使用 Future.microtask 或 Future() 以确保在下一帧处理，避免 build 冲突
    final CropResult? finalResult =
        await Future(() => _performActualCrop(forPreview: false));

    if (mounted) {
      setState(() => _isProcessingConfirm = false);
      if (finalResult != null && finalResult.bytes.isNotEmpty) {
        Navigator.of(context).pop(finalResult);
      } else {
        // 可以选择通知用户裁剪失败，或者静默处理（当前 pop(null)）
        Navigator.of(context).pop(null);

        AppSnackBar.showError(context, "图片裁剪失败，请重试");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color disabledColor = Colors.grey.shade400;
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
                      builder: (context, constraints) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted &&
                              (_cropAreaSize == null ||
                                  _cropAreaSize !=
                                      Size(constraints.maxWidth,
                                          constraints.maxHeight))) {
                            final newSize = Size(
                                constraints.maxWidth, constraints.maxHeight);
                            final newRadius =
                                math.min(newSize.width, newSize.height) /
                                    2 *
                                    0.85; // 圆形裁剪框的半径，可以调整比例
                            setState(() {
                              _cropAreaSize = newSize;
                              _cropCircleRadius = newRadius;
                              if (_decodedUiImage != null) {
                                _setInitialTransformation();
                              }
                            });
                          }
                        });

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
                          content = LoadingWidget.inline(size: 24);
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
                                  child: Image.memory(
                                      _originalImageBytes!, // 使用原始字节显示，避免解码两次ui.Image
                                      key: ValueKey(
                                          _originalImageBytes!.hashCode),
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                      filterQuality: FilterQuality.medium),
                                ),
                                IgnorePointer(
                                  child: CustomPaint(
                                    size: currentCropAreaSize,
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
                              ? (_decodedUiImage !=
                                          null && // 用_decodedUiImage判断是否有图加载
                                      !_isLoadingImage)
                                  ? (_isPreviewLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      // 如果没有预览图但图片已加载，显示一个提示图标或空的
                                      : Icon(Icons.image_not_supported_outlined,
                                          size: 40, color: Colors.grey[400]))
                                  : Icon(Icons.person, // 初始状态，没有图片也没有加载
                                      size: 60,
                                      color: Colors.white70)
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
                TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: secondaryColor,
                      disabledForegroundColor:
                          disabledColor.withSafeOpacity(0.7),
                      padding: buttonPadding,
                      textStyle: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        fontFamily: FontConfig.defaultFontFamily,
                        fontFamilyFallback: FontConfig.fontFallback,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: _isProcessingConfirm
                      ? null
                      : () => Navigator.of(context).pop(null),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 12),
                FunctionalButton(
                  label: '确定',
                  icon: Icons.check,
                  onPressed: (_croppedPreviewBytes != null &&
                          _croppedPreviewBytes!.isNotEmpty)
                      ? _confirmCrop
                      : null, // 只有预览有效时才能点确定
                  isLoading: _isProcessingConfirm,
                  isEnabled: (_croppedPreviewBytes != null &&
                      _croppedPreviewBytes!.isNotEmpty &&
                      !_isProcessingConfirm &&
                      !_isLoadingImage), // 确保图片已加载且不在处理中
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
}
