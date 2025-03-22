import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../common/image/safe_cached_image.dart';
import 'game_category_tag.dart';
import 'game_stats_widget.dart';
import 'game_tag_list.dart';
import 'game_collection_dialog.dart';

/// 基础游戏卡片组件，提供共享的UI结构和功能
class BaseGameCard extends StatelessWidget {
  final Game game;
  final bool isGridItem;
  final bool adaptForPanels;
  final bool showTags;
  final int maxTags;
  final bool forceCompact;
  final bool showCollectionStats;

  const BaseGameCard({
    Key? key,
    required this.game,
    this.isGridItem = true,
    this.adaptForPanels = false,
    this.showTags = true,
    this.maxTags = 2,
    this.forceCompact = false,
    this.showCollectionStats = true,
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
                    onError: (url, error) {
                      print('游戏封面加载失败: $url, 错误: $error');
                    },
                  ),

                  // 类别标签
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GameCategoryTag(category: game.category),
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
                    child: GestureDetector(
                      onTap: () {
                        if (showCollectionStats && game.totalCollections > 0) {
                          showGameCollectionDialog(context, game);
                        }
                      },
                      child: GameStatsWidget(
                        game: game,
                        showCollectionStats: showCollectionStats,
                        isGrid: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 游戏信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildGridInfoSection(context),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: GameCategoryTag(category: game.category),
        ),
      ],
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
          GameTagList(tags: game.tags, maxTags: maxTags),

        Spacer(),

        // 底部统计信息
        GestureDetector(
          onTap: () {
            if (showCollectionStats && game.totalCollections > 0) {
              showGameCollectionDialog(context, game);
            }
          },
          child: GameStatsWidget(
            game: game,
            showCollectionStats: showCollectionStats,
            isGrid: false,
          ),
        ),
      ],
    );
  }

  // 网格布局的信息区域
  Widget _buildGridInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          game.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          game.summary,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // 标签区域
        if (showTags && game.tags.isNotEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: GameTagList(
                tags: game.tags,
                maxTags: maxTags,
                isScrollable: true,
              ),
            ),
          ),
      ],
    );
  }

  // 卡片点击事件
  void _onCardTap(BuildContext context) {
    Navigator.pushNamed(
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