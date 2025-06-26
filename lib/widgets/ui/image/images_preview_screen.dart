// lib/widgets/ui/image/images_preview_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // 引入 kIsWeb，虽然这里主要是用 Platform
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart'; // 手机端
import 'package:permission_handler/permission_handler.dart'; // 手机端
import 'package:file_picker/file_picker.dart'; // Windows/Desktop 端
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:path/path.dart' as path; // 用于处理文件路径和扩展名

/// 图片预览屏幕
///
/// 处理网络图片加载错误
/// 支持缩放、滑动和页面切换
/// 支持在移动端和桌面端（Windows/macOS/Linux）下载图片
class ImagesPreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool allowDownload;

  const ImagesPreviewScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.allowDownload = false,
  });

  @override
  _ImagesPreviewScreenState createState() => _ImagesPreviewScreenState();
}

class _ImagesPreviewScreenState extends State<ImagesPreviewScreen> {
  late int currentIndex;
  late PageController pageController;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果不允许下载，或者平台不支持（例如Web），则不显示任何操作按钮
    final bool showActions = widget.allowDownload && !kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withSafeOpacity(0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: AppText(
          '${currentIndex + 1}/${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: showActions ? _buildActions() : null,
      ),
      body: _buildPhotoGallery(),
    );
  }

  List<Widget> _buildActions() {
    return [
      IconButton(
        tooltip: '保存图片',
        icon: _isDownloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.download_rounded),
        onPressed: _isDownloading ? null : _downloadCurrentImage,
      ),
    ];
  }

  Widget _buildPhotoGallery() {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions.customChild(
          child: _buildGalleryItem(widget.images[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 2.5,
          heroAttributes: PhotoViewHeroAttributes(
            tag: 'image_preview_${widget.images[index]}',
          ),
        );
      },
      itemCount: widget.images.length,
      pageController: pageController,
      onPageChanged: (index) {
        setState(() {
          currentIndex = index;
        });
      },
    );
  }

  Widget _buildGalleryItem(String imageUrl) {
    return Center(
      child: SafeCachedImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  /// 下载当前图片（兼容移动端和桌面端）
  Future<void> _downloadCurrentImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        await _downloadForDesktop();
      } else if (Platform.isAndroid || Platform.isIOS) {
        await _downloadForMobile();
      } else {
        // 对于其他不支持的平台
        AppSnackBar.showInfo('当前平台不支持下载功能。');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError('发生未知错误: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  /// 移动端（Android/iOS）下载逻辑
  Future<void> _downloadForMobile() async {
    // 1. 请求权限
    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) {
      AppSnackBar.showWarning('请授予相册权限以便保存图片');
      return;
    }

    // 2. 获取图片文件
    final imageUrl = widget.images[currentIndex];
    final file = await DefaultCacheManager().getSingleFile(imageUrl);

    // 3. 保存到相册
    final result = await ImageGallerySaver.saveFile(file.path);

    if (mounted) {
      if (result['isSuccess'] == true) {
        AppSnackBar.showSuccess('图片已成功保存到相册');
      } else {
        AppSnackBar.showError("保存失败: ${result['errorMessage'] ?? '未知错误'}");
      }
    }
  }

  /// 桌面端（Windows/macOS/Linux）下载逻辑
  Future<void> _downloadForDesktop() async {
    final imageUrl = widget.images[currentIndex];

    // 1. 从URL中猜测一个文件名和扩展名
    String fileName = path.basename(Uri.parse(imageUrl).path);
    if (fileName.isEmpty || !fileName.contains('.')) {
      // 如果URL不规范，给个默认名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = 'image_$timestamp.jpg';
    }

    // 2. 弹出文件保存对话框，让用户选择位置
    final String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '请选择保存位置:',
      fileName: fileName,
    );

    // 如果用户取消了选择，直接返回
    if (outputFile == null) {
      AppSnackBar.showInfo('已取消保存');
      return;
    }

    // 3. 获取缓存文件
    final file = await DefaultCacheManager().getSingleFile(imageUrl);

    // 4. 将缓存文件复制到用户选择的位置
    await file.copy(outputFile);

    if (mounted) {
      AppSnackBar.showSuccess('图片已成功保存到: $outputFile');
    }
  }
}
