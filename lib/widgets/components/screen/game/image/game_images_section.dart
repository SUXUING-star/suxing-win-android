// lib/widgets/components/screen/game/image/game_images_section.dart

/// 该文件定义了 [GameImagesSection] 组件，用于显示游戏截图列表。
/// [GameImagesSection] 在水平滚动视图中展示游戏截图，并支持点击预览大图。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法
import 'package:suxingchahui/models/game/game.dart'; // 游戏模型
import 'package:suxingchahui/widgets/ui/image/images_preview_screen.dart'; // 图片预览屏幕
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 安全缓存图片组件

/// [GameImagesSection] 类：游戏截图显示组件。
///
/// 该组件负责在卡片中显示游戏截图列表，并提供点击预览功能。
class GameImagesSection extends StatelessWidget {
  final Game game; // 游戏数据

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [game]：要显示截图的游戏数据。
  const GameImagesSection({
    super.key,
    required this.game,
  });

  /// 构建 Widget。
  ///
  /// 如果游戏截图列表为空，返回空 Widget。
  /// 否则，显示“游戏截图”标题和水平滚动的截图列表。
  @override
  Widget build(BuildContext context) {
    if (game.images.isEmpty) {
      // 游戏截图列表为空时
      return const SizedBox.shrink(); // 返回空 Widget
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16), // 垂直外边距
      padding: const EdgeInsets.all(16), // 内边距
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9), // 背景颜色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor, // 主题色
                  borderRadius: BorderRadius.circular(2), // 圆角
                ),
              ),
              const SizedBox(width: 8), // 间距
              Text(
                '游戏截图', // 标题文本
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // 间距
          SizedBox(
            height: 180, // 固定高度
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // 水平滚动
              padding: const EdgeInsets.symmetric(horizontal: 12), // 水平内边距
              itemCount: game.images.length, // 列表项数量
              itemBuilder: (context, index) =>
                  _buildImageItem(context, index), // 构建图片项
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个游戏截图项。
  ///
  /// [context]：Build 上下文。
  /// [index]：截图索引。
  /// 返回一个包含缓存图片和阴影的 GestureDetector Widget。
  Widget _buildImageItem(BuildContext context, int index) {
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
        onTap: () => _showImagePreview(context, index), // 点击时显示图片预览
        child: Hero(
          // Hero 动画
          tag: 'game_image_$index', // 动画标签
          child: ClipRRect(
            // 圆角裁剪
            borderRadius: BorderRadius.circular(12),
            child: SafeCachedImage(
              imageUrl: game.images[index], // 图片 URL
              width: 280, // 宽度
              height: 180, // 高度
              fit: BoxFit.cover, // 填充模式
              memCacheWidth: 560, // 内存缓存宽度（2倍于显示宽度）
              onError: (url, error) {
                // 图片加载错误回调
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 显示图片预览。
  ///
  /// [context]：Build 上下文。
  /// [initialIndex]：初始显示图片的索引。
  /// 导航到 `ImagePreviewScreen`。
  void _showImagePreview(BuildContext context, int initialIndex) {
    NavigationUtils.push(
      // 导航到新路由
      context,
      MaterialPageRoute(
        builder: (_) => ImagesPreviewScreen(
          images: game.images, // 图片列表
          initialIndex: initialIndex, // 初始索引
          allowDownload: true,
        ),
      ),
    );
  }
}
