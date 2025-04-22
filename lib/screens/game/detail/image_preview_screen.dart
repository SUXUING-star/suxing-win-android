// lib/screens/image_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
// 1. 导入 CachedNetworkImageProvider
import 'package:cached_network_image/cached_network_image.dart';
// 2. 导入你的 URL 工具类 (如果 SafeCachedImage 里的 UrlUtils 在别处)
import 'package:suxingchahui/utils/network/url_utils.dart'; // 确认路径正确
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
// 3. 不再需要导入 SafeCachedImage 了
// import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class ImagePreviewScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late int currentIndex;
  late PageController pageController;

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${currentIndex + 1}/${widget.images.length}',
          style: TextStyle(color: Colors.white),
        ),
        // 可选：添加关闭按钮
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          // 4. 获取原始 URL
          final String imageUrl = widget.images[index];
          // 5. 使用你的 URL 工具类处理 URL (重要！)
          final String safeUrl = UrlUtils.getSafeUrl(imageUrl);

          return PhotoViewGalleryPageOptions(
            // 6. 直接使用 CachedNetworkImageProvider
            imageProvider: CachedNetworkImageProvider(safeUrl),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            // 可选：如果你想在 PhotoView 层面处理英雄动画 tag
            // heroAttributes: PhotoViewHeroAttributes(tag: safeUrl + index.toString()), // 确保 tag 唯一
          );
        },
        itemCount: widget.images.length,
        // 7. PhotoViewGallery 自带 loadingBuilder，会使用这里的
        loadingBuilder: (context, event) {
          return LoadingWidget.inline();
        },
        pageController: pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        // 可选：背景装饰，默认就是黑的，但可以明确设置
        backgroundDecoration: BoxDecoration(color: Colors.black),
      ),
    );
  }
}