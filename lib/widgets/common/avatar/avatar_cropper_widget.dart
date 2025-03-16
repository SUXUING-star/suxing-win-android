import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'avatar_cropper_bridge.dart';

class WindowsAvatarCropper {
  // 保存原始图片的引用
  static File? _originalImageFile;
  static final AvatarCropperBridge _bridge = AvatarCropperBridge();

  /// 从相册选择并裁剪头像
  static Future<void> pickAndCropImage(
      BuildContext context, {
        required String? currentAvatarUrl,
        required Function(File) onCropComplete,
      }) async {
    final ImagePicker picker = ImagePicker();

    try {
      // 打开图库选择器
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1500,
        maxHeight: 1500,
      );

      // 如果用户选择了图片，保存原始文件并打开裁剪对话框
      if (pickedFile != null && context.mounted) {
        _originalImageFile = File(pickedFile.path);

        final CropResult? cropResult = await _showCropperUI(
          context,
          _originalImageFile!,
        );

        if (cropResult != null && context.mounted) {
          // 使用C++实现裁剪
          final File? croppedFile = await _bridge.cropAvatarCircle(
            inputFile: _originalImageFile!,
            sourceX: cropResult.sourceX,
            sourceY: cropResult.sourceY,
            sourceWidth: cropResult.sourceWidth,
            sourceHeight: cropResult.sourceHeight,
          );

          if (croppedFile != null && context.mounted) {
            // 显示预览确认对话框
            await _showPreviewDialog(context, croppedFile, onCropComplete);
          }
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

  /// 显示裁剪UI界面
  static Future<CropResult?> _showCropperUI(BuildContext context, File imageFile) async {
    return await showDialog<CropResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CropperDialog(imageFile: imageFile),
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
                    color: Colors.black.withOpacity(0.1),
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
              Navigator.of(context).pop();

              // 重新裁剪时使用原始图片
              if (_originalImageFile != null) {
                _showCropperUI(context, _originalImageFile!).then((result) async {
                  if (result != null && context.mounted) {
                    final File? croppedFile = await _bridge.cropAvatarCircle(
                      inputFile: _originalImageFile!,
                      sourceX: result.sourceX,
                      sourceY: result.sourceY,
                      sourceWidth: result.sourceWidth,
                      sourceHeight: result.sourceHeight,
                    );

                    if (croppedFile != null && context.mounted) {
                      _showPreviewDialog(context, croppedFile, onCropComplete);
                    }
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

/// 裁剪结果数据类
class CropResult {
  final double sourceX;
  final double sourceY;
  final double sourceWidth;
  final double sourceHeight;

  CropResult({
    required this.sourceX,
    required this.sourceY,
    required this.sourceWidth,
    required this.sourceHeight,
  });
}

/// 裁剪对话框
class _CropperDialog extends StatefulWidget {
  final File imageFile;

  const _CropperDialog({
    Key? key,
    required this.imageFile,
  }) : super(key: key);

  @override
  _CropperDialogState createState() => _CropperDialogState();
}

class _CropperDialogState extends State<_CropperDialog> {
  late ImageProvider _imageProvider;
  bool _imageLoaded = false;
  double _scale = 1.0;
  Offset _position = Offset.zero;
  Size _imageSize = Size.zero;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  // 捏合缩放相关变量
  double _startScale = 1.0;

  // 裁剪区域比例，占据视口的50%
  final double _cropRatio = 0.5;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener!);
    super.dispose();
  }

  // 加载图片
  void _loadImage() {
    _imageProvider = FileImage(widget.imageFile);

    // 使用ImageStream加载图片并获取尺寸
    _imageStream = _imageProvider.resolve(ImageConfiguration());
    _imageListener = ImageStreamListener((info, _) {
      setState(() {
        _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
        _imageLoaded = true;
      });

      // 初始化位置和缩放
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initPosition();
      });
    }, onError: (exception, stackTrace) {
      print('加载图片失败: $exception');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载图片失败，请重试')),
        );
      }
    });

    _imageStream!.addListener(_imageListener!);
  }

  // 初始化图片位置和缩放
  void _initPosition() {
    if (!mounted) return;

    // 获取容器尺寸
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size viewportSize = box.size;

    // 计算裁剪区域大小和中心点
    final double cropSize = math.min(viewportSize.width, viewportSize.height) * _cropRatio;
    final Offset viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);

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

  // 计算源图像上的裁剪区域
  CropResult _calculateCropParameters() {
    // 获取视口尺寸
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size viewportSize = box.size;

    // 裁剪区域
    final double cropSize = math.min(viewportSize.width, viewportSize.height) * _cropRatio;
    final Offset cropCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);
    final Rect cropRect = Rect.fromCenter(
      center: cropCenter,
      width: cropSize,
      height: cropSize,
    );

    // 计算源图像上的裁剪区域
    final double srcX = (cropRect.left - _position.dx) / _scale;
    final double srcY = (cropRect.top - _position.dy) / _scale;
    final double srcWidth = cropRect.width / _scale;
    final double srcHeight = cropRect.height / _scale;

    // 确保不超出原图范围
    final double clampedSrcX = math.max(0, math.min(srcX, _imageSize.width - 1));
    final double clampedSrcY = math.max(0, math.min(srcY, _imageSize.height - 1));
    final double clampedSrcWidth = math.min(_imageSize.width - clampedSrcX, srcWidth);
    final double clampedSrcHeight = math.min(_imageSize.height - clampedSrcY, srcHeight);

    return CropResult(
      sourceX: clampedSrcX,
      sourceY: clampedSrcY,
      sourceWidth: clampedSrcWidth,
      sourceHeight: clampedSrcHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: _imageLoaded
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
                    onPressed: () {
                      final cropResult = _calculateCropParameters();
                      Navigator.of(context).pop(cropResult);
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
        final cropSize = math.min(constraints.maxWidth, constraints.maxHeight) * _cropRatio;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 图片和手势层
            GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 图片层
                  Positioned.fill(
                    child: Transform.translate(
                      offset: _position,
                      child: Transform.scale(
                        scale: _scale,
                        alignment: Alignment.topLeft,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.none,
                        ),
                      ),
                    ),
                  ),

                  // 暗色蒙版层（带圆形裁剪区域）
                  CustomPaint(
                    painter: _CropMaskPainter(
                      cropRatio: _cropRatio,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ],
              ),
            ),

            // 裁剪圆形指示器
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

/// 自定义画笔，用于绘制带有透明圆形区域的暗色蒙版
class _CropMaskPainter extends CustomPainter {
  final double cropRatio;

  _CropMaskPainter({
    required this.cropRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    // 绘制暗色蒙版
    final Paint maskPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(maskPath, maskPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}