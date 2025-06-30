// lib/widgets/components/screen/game/section/random/random_game_card.dart

/// 该文件定义了 [RandomGameCard] 组件，用于显示随机游戏卡片。
/// [RandomGameCard] 包含游戏封面、统计信息和标题。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/routes/app_routes.dart'; // 应用路由所需
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类所需
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导航工具类所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需
import 'package:suxingchahui/models/game/game/game.dart'; // 游戏模型所需
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart'; // 安全缓存图片组件所需

/// [RandomGameCard] 类：显示随机游戏卡片的 StatelessWidget。
///
/// 该组件展示游戏的封面、点赞数、浏览数和标题，并提供点击跳转游戏详情的功能。
class RandomGameCard extends StatelessWidget {
  final Game game; // 游戏数据
  final VoidCallback? onTap; // 卡片点击回调

  /// 构造函数。
  ///
  /// [game]：游戏数据。
  /// [onTap]：卡片点击回调。
  const RandomGameCard({
    super.key,
    required this.game,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // 鼠标悬停时显示点击手势
      child: InkWell(
        borderRadius: BorderRadius.circular(12), // 圆角边框
        onTap: onTap ?? // 卡片点击回调，如果未提供则跳转游戏详情页
            () {
              NavigationUtils.pushReplacementNamed(
                context,
                AppRoutes.gameDetail,
                arguments: game.id,
              );
            },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGameCoverWithStats(context), // 游戏封面和统计信息
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: _buildGameTitle(), // 游戏标题
            ),
          ],
        ),
      ),
    );
  }

  /// 构建游戏封面和统计信息区域。
  ///
  /// [context]：Build 上下文。
  /// 返回一个包含游戏封面、点赞数和浏览数的 Stack Widget。
  Widget _buildGameCoverWithStats(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktopScreen(context); // 判断是否为桌面屏幕
    return AspectRatio(
      aspectRatio: 4 / 3, // 宽高比
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), // 圆角边框
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12), // 圆角裁剪
          child: Stack(
            fit: StackFit.expand, // 填充父容器
            children: [
              SafeCachedImage(
                // 游戏封面图片
                imageUrl: game.coverImage,
                fit: BoxFit.cover,
                memCacheWidth: isDesktop ? 320 : 240, // 内存缓存宽度
              ),

              // 底部渐变遮罩
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withSafeOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 8,
                left: 8,
                child: _buildLikesIndicator(), // 点赞数指示器
              ),

              Positioned(
                bottom: 8,
                right: 8,
                child: _buildViewsIndicator(), // 浏览数指示器
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建点赞数指示器。
  ///
  /// 返回一个包含点赞图标和数量的容器。
  Widget _buildLikesIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withSafeOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.thumb_up,
            color: Colors.pink,
            size: 14,
          ),
          const SizedBox(width: 4), // 间距
          Text(
            game.likeCount.toString(), // 点赞数量
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建浏览数指示器。
  ///
  /// 返回一个包含浏览图标和数量的容器。
  Widget _buildViewsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withSafeOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_red_eye,
            color: Colors.lightBlue,
            size: 14,
          ),
          const SizedBox(width: 4), // 间距
          Text(
            game.viewCount.toString(), // 浏览数量
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建游戏标题。
  ///
  /// 返回一个包含游戏标题的 Text Widget。
  Widget _buildGameTitle() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 40), // 最大高度
      child: Text(
        game.title, // 游戏标题
        maxLines: 2, // 最大行数
        overflow: TextOverflow.ellipsis, // 溢出时显示省略号
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          height: 1.2,
        ),
      ),
    );
  }
}
