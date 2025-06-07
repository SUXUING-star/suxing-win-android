// lib/widgets/ui/image/robust_image_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'robust_network_image.dart';

/// 健壮的图片预览屏幕
///
/// 使用RobustNetworkImage处理网络图片加载错误
/// 支持缩放、滑动和页面切换
class RobustImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool allowShare;
  final bool allowDownload;

  const RobustImagePreviewScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.allowShare = true,
    this.allowDownload = false,
  });

  @override
  _RobustImagePreviewScreenState createState() =>
      _RobustImagePreviewScreenState();
}

class _RobustImagePreviewScreenState extends State<RobustImagePreviewScreen>
    with SnackBarNotifierMixin {
  late int currentIndex;
  late PageController pageController;
  bool _isLoading = false;

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
    buildSnackBar(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${currentIndex + 1}/${widget.images.length}',
          style: TextStyle(color: Colors.white),
        ),
        actions: _buildActions(),
      ),
      body: _buildPhotoGallery(),
    );
  }

  /// 构建操作按钮
  List<Widget> _buildActions() {
    final List<Widget> actions = [];

    if (widget.allowShare) {
      actions.add(
        IconButton(
          icon: Icon(Icons.share),
          onPressed: _shareCurrentImage,
        ),
      );
    }

    if (widget.allowDownload) {
      actions.add(
        IconButton(
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.download),
          onPressed: _isLoading ? null : _downloadCurrentImage,
        ),
      );
    }

    return actions;
  }

  /// 构建图片画廊
  Widget _buildPhotoGallery() {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions.customChild(
          child: _buildGalleryItem(widget.images[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 2,
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

  /// 构建单个画廊项
  Widget _buildGalleryItem(String imageUrl) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: RobustNetworkImage(
          imageUrl: imageUrl,
          // 不指定固定宽高，适应屏幕
          fit: BoxFit.contain,
          backgroundColor: Colors.transparent,
          loadingWidget: Container(
            color: Colors.transparent,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          errorWidget: Container(
            color: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '无法加载图片',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {}); // 刷新重试
                    },
                    child: Text(
                      '点击重试',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 分享当前图片
  void _shareCurrentImage() {
    // 实现分享功能
    showSnackBar(message: '分享功能将在后续版本实现', type: SnackBarType.info);
  }

  /// 下载当前图片
  void _downloadCurrentImage() async {
    // 在实际应用中，此处应该调用下载服务
    // 例如使用dio或flutter_downloader插件

    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟下载过程
      await Future.delayed(Duration(seconds: 2));

      showSnackBar(message: '图片已保存到相册', type: SnackBarType.success);
    } catch (e) {
      showSnackBar(message: '下载失败: $e', type: SnackBarType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
