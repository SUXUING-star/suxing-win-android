// lib/widgets/components/screen/game/collection/collection_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../common/image/safe_cached_image.dart';

/// 为游戏收藏屏幕专门设计的卡片组件
///
/// 使用左图右信息的横向布局，标题在右侧内容区顶部
class CollectionGameCard extends StatelessWidget {
  final Game game;
  final String? collectionStatus; // 收藏状态: want_to_play, playing, played

  const CollectionGameCard({
    Key? key,
    required this.game,
    this.collectionStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 判断是否为桌面布局
    final bool isDesktop = DeviceUtils.isDesktop;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/game/detail', arguments: game);
        },
        child: IntrinsicHeight( // 确保左右两侧高度一致
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧图片
              _buildGameCover(context, isDesktop),

              // 右侧信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _buildGameInfo(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 游戏封面（左侧）
  Widget _buildGameCover(BuildContext context, bool isDesktop) {
    // 根据设备类型调整图片大小
    final coverWidth = isDesktop ? 120.0 : 100.0;

    return Stack(
      children: [
        Container(
          width: coverWidth,
          height: coverWidth * 0.75, // 4:3 比例
          child: SafeCachedImage(
            imageUrl: game.coverImage,
            fit: BoxFit.cover,
            memCacheWidth: isDesktop ? 240 : 200,
            backgroundColor: Colors.grey[200],
            onError: (url, error) {
              print('游戏卡片图片加载失败: $url, 错误: $error');
            },
          ),
        ),

        // 类别标签
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
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

  // 游戏信息（右侧）
  Widget _buildGameInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和收藏状态图标在一行
        Row(
          children: [
            Expanded(
              child: Text(
                game.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (collectionStatus != null)
              _buildStatusIcon(collectionStatus!),
          ],
        ),

        SizedBox(height: 4),


        // 中间可以放简短描述
        if (game.summary != null && game.summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              game.summary,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // 标签
        if (game.tags.isNotEmpty)
          _buildTags(game.tags),

        Spacer(),

        // 底部统计信息
        Row(
          children: [
            // 点赞数
            Icon(Icons.thumb_up, size: 14, color: Colors.redAccent),
            SizedBox(width: 4),
            Text(
              game.likeCount.toString(),
              style: TextStyle(fontSize: 12),
            ),

            SizedBox(width: 12),

            // 查看数
            Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.lightBlueAccent),
            SizedBox(width: 4),
            Text(
              game.viewCount.toString(),
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  // 构建游戏标签
  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.take(2).map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 收藏状态图标
  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'want_to_play':
        icon = Icons.star_border;
        color = Colors.blue;
        break;
      case 'playing':
        icon = Icons.videogame_asset;
        color = Colors.green;
        break;
      case 'played':
        icon = Icons.check_circle;
        color = Colors.purple;
        break;
      default:
        icon = Icons.bookmark;
        color = Colors.grey;
    }

    return Icon(icon, size: 16, color: color);
  }
}