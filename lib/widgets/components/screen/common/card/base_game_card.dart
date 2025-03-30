// lib/widgets/components/screen/common/card/base_game_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../../models/game/game.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../ui/image/safe_cached_image.dart';
import '../../../../../routes/app_routes.dart';

/// 基础游戏卡片组件，提供共享的UI结构和功能
///
/// 该类实现了横向和网格两种布局模式的游戏卡片，子类可以通过重写特定方法来定制行为
class BaseGameCard extends StatelessWidget {
  final Game game;
  final bool isGridItem;
  final bool adaptForPanels;
  final bool showTags;
  final int maxTags;
  final bool forceCompact;

  const BaseGameCard({
    Key? key,
    required this.game,
    this.isGridItem = true,
    this.adaptForPanels = false,
    this.showTags = true,
    this.maxTags = 2,
    this.forceCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isGridItem ? _buildGridCard(context) : _buildListCard(context);
  }

  // 列表布局卡片（横向布局）
  Widget _buildListCard(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _onCardTap(context),
        child: IntrinsicHeight(
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

  // 网格布局卡片（垂直布局）
  Widget _buildGridCard(BuildContext context) {
    final isCompact = _shouldUseCompactLayout(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onCardTap(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 游戏封面
                  SafeCachedImage(
                    imageUrl: game.coverImage,
                    fit: BoxFit.cover,
                    memCacheWidth: 480,
                    backgroundColor: Colors.grey[200],
                    onError: (url, error) {
                      print('游戏封面加载失败: $url, 错误: $error');
                    },
                  ),

                  // 类别标签
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildCategoryTag(context),
                  ),

                  // 右上角操作区域（由子类实现）
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildGridTopRightAction(context),
                  ),

                  // 统计信息
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildStatsContainer(context, true),
                  ),
                ],
              ),
            ),

            // 游戏信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
                child: _buildGridInfoSection(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 确定是否使用紧凑布局
  bool _shouldUseCompactLayout(BuildContext context) {
    // 获取设备信息
    final isAndroidPortrait = DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);

    // 计算每行卡片数量（用于动态调整布局）
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(
        context,
        withPanels: adaptForPanels
    );

    // 确定是否使用紧凑布局
    return forceCompact || (cardsPerRow > 3) || (cardsPerRow == 3 && adaptForPanels) || isAndroidPortrait;
  }

  // 游戏封面（左侧）- 列表布局
  Widget _buildGameCover(BuildContext context, bool isDesktop) {
    final coverWidth = isDesktop ? 120.0 : 100.0;

    return Stack(
      children: [
        SizedBox(
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
          child: _buildCategoryTag(context),
        ),
      ],
    );
  }

  // 类别标签
  Widget _buildCategoryTag(BuildContext context) {
    final isCompact = _shouldUseCompactLayout(context);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 2 : 4
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        game.category,
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 游戏信息区域 - 列表布局
  Widget _buildGameInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和右侧操作
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
            _buildListTopRightAction(context),
          ],
        ),

        SizedBox(height: 4),

        // 中间可以放简短描述
        if (game.summary.isNotEmpty)
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
        if (showTags && game.tags.isNotEmpty)
          _buildTags(game.tags),

        Spacer(),

        // 底部统计信息
        _buildStatsRow(context),
      ],
    );
  }

  // 网格布局的信息区域
  Widget _buildGridInfoSection(BuildContext context) {
    final isCompact = _shouldUseCompactLayout(context);
    final summaryMaxLines = isCompact ? 1 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          game.title,
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: isCompact ? 2 : 4),

        Text(
          game.summary,
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            color: Colors.grey[700],
            height: 1.2,
          ),
          maxLines: summaryMaxLines,
          overflow: TextOverflow.ellipsis,
        ),

        // 标签区域
        if (showTags && game.tags.isNotEmpty && !isCompact)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: game.tags.take(maxTags).map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Container(
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
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 构建游戏标签 - 列表布局
  Widget _buildTags(List<String> tags) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags.take(maxTags).map((tag) {
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

  // 构建统计信息行 - 列表布局
  Widget _buildStatsRow(BuildContext context) {
    return Row(
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
    );
  }

  // 网格布局的底部统计信息容器
  Widget _buildStatsContainer(BuildContext context, bool isGrid) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thumb_up, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            game.likeCount.toString(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            game.viewCount.toString(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 以下方法由子类重写实现个性化行为

  // 卡片点击事件
  void _onCardTap(BuildContext context) {
    NavigationUtils.pushNamed(
      context,
      '/game/detail',
      arguments: game,
    );
  }

  // 列表布局右上角操作区域 - 子类重写
  Widget _buildListTopRightAction(BuildContext context) {
    return SizedBox.shrink(); // 默认不显示任何内容
  }

  // 网格布局右上角操作区域 - 子类重写
  Widget _buildGridTopRightAction(BuildContext context) {
    return SizedBox.shrink(); // 默认不显示任何内容
  }
}