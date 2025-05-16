import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';

class CustomAvatarCropper {
  // 保存原始图片的引用，用于重新裁剪
  static File? _originalImageFile;

  /// 从相册选择并裁剪头像
  static Future<void> pickAndCropImage(
    BuildContext context, {
    required String? currentAvatarUrl,
    required Function(File) onCropComplete,
  }) async {
    final ImagePicker picker = ImagePicker();

    try {
      // 直接打开图库选择器
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1500,
        maxHeight: 1500,
      );

      // 如果用户选择了图片，保存原始文件并打开裁剪对话框
      if (pickedFile != null && context.mounted) {
        _originalImageFile = File(pickedFile.path);

        final File? croppedFile = await _showCustomCropper(
          context,
          _originalImageFile!,
        );

        if (croppedFile != null && context.mounted) {
          // 显示预览确认对话框
          await _showPreviewDialog(context, croppedFile, onCropComplete);
        }
      }
    } catch (e) {
      print('选择或裁剪图片失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理图片时出错，请重试')),
        );
      }
    }
  }

  /// 显示自定义裁剪对话框
  static Future<File?> _showCustomCropper(
      BuildContext context, File imageFile) async {
    return await showDialog<File>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CustomCropperDialog(imageFile: imageFile),
    );
  }

  /// 显示预览确认对话框
  static Future<void> _showPreviewDialog(
    BuildContext context,
    File imageFile,
    Function(File) onCropComplete,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('预览头像'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                image: DecorationImage(
                  image: FileImage(imageFile),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withSafeOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '您对这个头像满意吗？',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              NavigationUtils.of(context).pop();

              // 重新裁剪时使用原始图片，而不是裁剪后的图片
              if (_originalImageFile != null) {
                _showCustomCropper(context, _originalImageFile!).then((file) {
                  if (file != null && context.mounted) {
                    _showPreviewDialog(context, file, onCropComplete);
                  }
                });
              }
            },
            child: Text('重新裁剪'),
          ),
          ElevatedButton(
            onPressed: () {
              onCropComplete(imageFile);
              Navigator.of(context).pop();
            },
            child: Text('确认使用'),
          ),
        ],
      ),
    );
  }
}

/// 自定义裁剪对话框
class _CustomCropperDialog extends StatefulWidget {
  final File imageFile;

  const _CustomCropperDialog({
    required this.imageFile,
  });

  @override
  _CustomCropperDialogState createState() => _CustomCropperDialogState();
}

class _CustomCropperDialogState extends State<_CustomCropperDialog>
    with SnackBarNotifierMixin {
  ui.Image? _image;
  bool _imageLoaded = false;
  double _scale = 1.0;
  Offset _position = Offset.zero;
  Size _imageSize = Size.zero;

  // 捏合缩放相关变量
  double _startScale = 1.0;

  // 将裁剪区域减小，占据视口的50%
  final double _cropRatio = 0.5;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  // 加载图片
  Future<void> _loadImage() async {
    try {
      final data = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _image = frame.image;
          _imageSize =
              Size(_image!.width.toDouble(), _image!.height.toDouble());
          _imageLoaded = true;
        });

        // 初始化位置和缩放在图片加载后执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initPosition();
        });
      }
    } catch (e) {
      print('加载图片失败: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载图片失败，请重试')),
        );
      }
    }
  }

  // 初始化图片位置和缩放 - 完全重写此方法
  void _initPosition() {
    if (!mounted || _image == null) return;

    // 获取容器尺寸
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size viewportSize = box.size;

    // 计算裁剪区域大小和中心点
    final double cropSize =
        math.min(viewportSize.width, viewportSize.height) * _cropRatio;
    final Offset viewportCenter =
        Offset(viewportSize.width / 2, viewportSize.height / 2);

    // 图片宽高比
    final double imageAspectRatio = _imageSize.width / _imageSize.height;
    // 裁剪区域宽高比 (始终为1，因为是正方形)
    final double cropAspectRatio = 1.0;

    // 计算初始缩放比例
    double scale;
    if (imageAspectRatio > cropAspectRatio) {
      // 横向图片，以高度为基准
      scale = cropSize / _imageSize.height;
    } else {
      // 纵向图片，以宽度为基准
      scale = cropSize / _imageSize.width;
    }

    // 缩放后的图片尺寸
    final Size scaledImageSize = Size(
      _imageSize.width * scale,
      _imageSize.height * scale,
    );

    // 计算图片左上角位置，使其中心与裁剪区域中心对齐
    final Offset position = Offset(
      viewportCenter.dx - scaledImageSize.width / 2,
      viewportCenter.dy - scaledImageSize.height / 2,
    );

    // 更新状态
    setState(() {
      _scale = scale;
      _position = position;
    });

    print(
        '重置图片位置 - 中心点: $viewportCenter, 缩放: $_scale, 位置: $_position, 裁剪大小: $cropSize');
  }

  // 处理缩放开始事件
  void _handleScaleStart(ScaleStartDetails details) {
    _startScale = _scale;
  }

  // 处理缩放更新事件
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!mounted) return;

    setState(() {
      // 处理缩放
      if (details.scale != 1.0) {
        _scale = (_startScale * details.scale).clamp(0.5, 5.0);
      }

      // 处理平移
      _position += details.focalPointDelta;
    });
  }

  // 进行裁剪
  Future<File?> _cropImage() async {
    if (!_imageLoaded || _image == null) return null;

    try {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final Size viewportSize = box.size;

      // 裁剪区域
      final double cropSize =
          math.min(viewportSize.width, viewportSize.height) * _cropRatio;
      final Offset cropCenter =
          Offset(viewportSize.width / 2, viewportSize.height / 2);
      final Rect cropRect = Rect.fromCenter(
        center: cropCenter,
        width: cropSize,
        height: cropSize,
      );

      // 计算源图像上的裁剪区域
      // 注意：这里需要从图片坐标系转换回原始图像坐标系
      final double srcX = (cropRect.left - _position.dx) / _scale;
      final double srcY = (cropRect.top - _position.dy) / _scale;
      final double srcWidth = cropRect.width / _scale;
      final double srcHeight = cropRect.height / _scale;

      // 确保不超出原图范围
      final double clampedSrcX =
          math.max(0, math.min(srcX, _imageSize.width - 1));
      final double clampedSrcY =
          math.max(0, math.min(srcY, _imageSize.height - 1));
      final double clampedSrcWidth =
          math.min(_imageSize.width - clampedSrcX, srcWidth);
      final double clampedSrcHeight =
          math.min(_imageSize.height - clampedSrcY, srcHeight);

      final Rect srcRect = Rect.fromLTWH(
        clampedSrcX,
        clampedSrcY,
        clampedSrcWidth,
        clampedSrcHeight,
      );

      print(
          '裁剪参数 - 裁剪框: $cropRect, 源区域: $srcRect, 图片位置: $_position, 缩放: $_scale');

      // 创建一个PictureRecorder绘制裁剪后的图像
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 设置输出尺寸
      final double outputSize = 300.0; // 缩小输出尺寸为300px

      // 圆形裁剪
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(
            center: Offset(outputSize / 2, outputSize / 2),
            radius: outputSize / 2));

      canvas.clipPath(clipPath);

      // 绘制图像
      final Paint paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      canvas.drawImageRect(
        _image!,
        srcRect,
        Rect.fromLTWH(0, 0, outputSize, outputSize),
        paint,
      );

      // 转换为图像
      final picture = recorder.endRecording();
      final img = await picture.toImage(outputSize.toInt(), outputSize.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final buffer = byteData.buffer.asUint8List();

      // 保存到临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(buffer);

      return tempFile;
    } catch (e) {
      print('裁剪图片失败: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('调整头像'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: _imageLoaded && _image != null
                  ? _buildCropperUI()
                  : Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('重置'),
                    onPressed: _initPosition,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check),
                    label: Text('确定'),
                    onPressed: () async {
                      final croppedFile = await _cropImage();
                      if (!mounted) return;
                      if (croppedFile != null) {
                        Navigator.of(this.context).pop(croppedFile);
                      } else {
                        showSnackbar(
                            message: '裁剪失败，请重试', type: SnackbarType.error);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建裁剪UI
  Widget _buildCropperUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cropSize =
            math.min(constraints.maxWidth, constraints.maxHeight) * _cropRatio;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 图片和手势层
            GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              child: CustomPaint(
                painter: _CropPainter(
                  image: _image!,
                  position: _position,
                  scale: _scale,
                  cropRatio: _cropRatio,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ),

            // 裁剪圆形指示
            Positioned.fill(
              child: Center(
                child: Container(
                  width: cropSize,
                  height: cropSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),

            // 提示文本
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '捏合或拖动以调整',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 裁剪画布
class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Offset position;
  final double scale;
  final double cropRatio;

  _CropPainter({
    required this.image,
    required this.position,
    required this.scale,
    required this.cropRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制图像
    final Paint imagePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    final Rect srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    final Rect destRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      image.width.toDouble() * scale,
      image.height.toDouble() * scale,
    );

    // 首先绘制图像
    canvas.drawImageRect(image, srcRect, destRect, imagePaint);

    // 然后绘制暗色蒙版
    final Paint maskPaint = Paint()
      ..color = Colors.black.withSafeOpacity(0.7) // 增加暗色蒙版的不透明度
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 裁剪区域尺寸
    final double cropSize = math.min(size.width, size.height) * cropRatio;

    // 完整区域路径
    final Path fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 裁剪区域（中心圆形）
    final Path cropPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: cropSize,
        height: cropSize,
      ));

    // 从完整区域减去裁剪区域，得到蒙版
    final Path maskPath = Path.combine(
      PathOperation.difference,
      fullPath,
      cropPath,
    );

    // 绘制蒙版
    canvas.drawPath(maskPath, maskPaint);

    // 加强白色边框
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), cropSize / 2, borderPaint);
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.position != position ||
        oldDelegate.scale != scale;
  }
}
