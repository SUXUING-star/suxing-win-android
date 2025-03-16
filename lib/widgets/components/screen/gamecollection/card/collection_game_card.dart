// lib/widgets/components/screen/game/collection/layout/collection_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../../../models/game/game.dart';
import '../../../../../../common/animated_card_container.dart';
import '../../../../../../../utils/device/device_utils.dart';
import '../../../tag/game_tags.dart';
import '../../../../../../common/image/safe_cached_image.dart';

/// 游戏收藏屏幕专用紧凑型游戏卡片
///
/// 为了解决并排显示时的空间限制问题，此卡片比标准GameCard更紧凑
class CollectionGameCard extends StatelessWidget {
  final Game game;
  final bool isMobile; // 是否为移动设备布局

  CollectionGameCard({
    Key? key,
    required this.game,
    this.isMobile = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据是否为移动设备选择构建方法
    return isMobile ? _buildMobileCard(context) : _buildDesktopCard(context);
  }

  // 移动设备布局 - 垂直卡片
  Widget _buildMobileCard(BuildContext context) {
    return AnimatedCardContainer(
      onTap: () {
        Navigator.pushNamed(context, '/game/detail', arguments: game);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片部分
          _buildCardImage(context, 140.0),

          // 内容部分
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  game.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),

                // 底部统计信息
                Row(
                  children: [
                    // 点赞数
                    Icon(Icons.thumb_up, size: 14, color: Colors.redAccent),
                    SizedBox(width: 4),
                    Text(game.likeCount.toString(), style: TextStyle(fontSize: 12)),
                    SizedBox(width: 8),

                    // 查看数
                    Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.lightBlueAccent),
                    SizedBox(width: 4),
                    Text(game.viewCount.toString(), style: TextStyle(fontSize: 12)),

                    // 状态指示器 (根据实际业务逻辑调整)
                    Spacer(),
                    _buildCollectionStatusIndicator(context),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 桌面设备布局 - 更紧凑的垂直卡片
  Widget _buildDesktopCard(BuildContext context) {
    return AnimatedCardContainer(
      onTap: () {
        Navigator.pushNamed(context, '/game/detail', arguments: game);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片部分
          _buildCardImage(context, 120.0),

          // 内容部分 - 更紧凑
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  game.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),

                // 单行标签
                if (game.tags.isNotEmpty)
                  GameTags(
                    game: game,
                    wrap: false,
                    maxTags: 1,
                    fontSize: 10,
                  ),

                SizedBox(height: 3),

                // 底部统计信息
                Row(
                  children: [
                    Icon(Icons.thumb_up, size: 12, color: Colors.redAccent),
                    SizedBox(width: 2),
                    Text(game.likeCount.toString(), style: TextStyle(fontSize: 11)),
                    SizedBox(width: 6),
                    Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.lightBlueAccent),
                    SizedBox(width: 2),
                    Text(game.viewCount.toString(), style: TextStyle(fontSize: 11)),
                    Spacer(),
                    _buildCollectionStatusIndicator(context, isDesktop: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建卡片图片
  Widget _buildCardImage(BuildContext context, double height) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          child: SafeCachedImage(
            imageUrl: game.coverImage,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            memCacheWidth: 320, // 由于紧凑布局，使用更小的缓存尺寸
            backgroundColor: Colors.grey[200],
            onError: (url, error) {
              print('游戏收藏卡片图片加载失败: $url, 错误: $error');
            },
          ),
        ),

        // 在图片上方显示类别标签
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              game.category,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建收藏状态指示器
  Widget _buildCollectionStatusIndicator(BuildContext context, {bool isDesktop = false}) {
    // 这里可以根据游戏的收藏状态显示不同的图标
    // 假设game对象有一个属性表示收藏状态
    IconData statusIcon;
    Color statusColor;

    // 这里模拟不同的收藏状态（实际应用中应该从game对象获取）
    // 例如：根据game.collectionStatus来决定图标
    final collectionStatus = _getCollectionStatus();

    switch (collectionStatus) {
      case 'want_to_play':
        statusIcon = Icons.star_border;
        statusColor = Colors.blue;
        break;
      case 'playing':
        statusIcon = Icons.videogame_asset;
        statusColor = Colors.green;
        break;
      case 'played':
        statusIcon = Icons.check_circle;
        statusColor = Colors.purple;
        break;
      default:
        statusIcon = Icons.bookmark;
        statusColor = Colors.grey;
    }

    return Icon(
      statusIcon,
      size: isDesktop ? 14 : 16,
      color: statusColor,
    );
  }

  // 模拟获取收藏状态的方法
  // 在实际应用中，应该从game对象中获取真实的收藏状态
  String _getCollectionStatus() {
    // 假设根据game.id的末尾数字来模拟不同状态
    int lastDigit = int.tryParse(game.id.toString().substring(game.id.toString().length - 1)) ?? 0;

    if (lastDigit < 3) {
      return 'want_to_play';
    } else if (lastDigit < 7) {
      return 'playing';
    } else {
      return 'played';
    }
  }
}