// lib/widgets/components/screen/game/section/image/game_image_item.dart

import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/image/images_preview_screen.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';

class GameImageItem extends StatelessWidget {
  final int imageIndex;
  final List<String> gameImages;
  const GameImageItem({
    super.key,
    required this.imageIndex,
    required this.gameImages,
  });

  /// 显示图片预览。
  ///
  /// [context]：Build 上下文。
  /// [initialIndex]：初始显示图片的索引。
  /// 导航到 `ImagePreviewScreen`。
  void _showImagePreview(BuildContext context) {
    NavigationUtils.push(
      // 导航到新路由
      context,
      MaterialPageRoute(
        builder: (_) => ImagesPreviewScreen(
          images: gameImages, // 图片列表
          initialIndex: imageIndex, // 初始索引
          allowDownload: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), // 水平外边距
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _showImagePreview(context), // 点击时显示图片预览
        child: Hero(
          // Hero 动画
          tag: 'game_image_$imageIndex', // 动画标签
          child: ClipRRect(
            // 圆角裁剪
            borderRadius: BorderRadius.circular(12),
            child: SafeCachedImage(
              imageUrl: gameImages[imageIndex],
              // 图片 URL
              width: 280,
              // 宽度
              height: 180,
              // 高度
              fit: BoxFit.cover,
              // 填充模式
              memCacheWidth: 560,
              // 内存缓存宽度（2倍于显示宽度）
              onError: (url, error) {
                // 图片加载错误回调
              },
            ),
          ),
        ),
      ),
    );
  }
}
