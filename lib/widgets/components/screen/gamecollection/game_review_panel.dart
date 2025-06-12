// lib/widgets/components/screen/gamecollection/game_review_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/game/game_constants.dart';
import 'dart:ui';

import 'package:suxingchahui/models/game/game_with_collection.dart';
import 'package:suxingchahui/models/game/game_collection.dart';
import 'package:suxingchahui/models/game/game.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_icon_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_category_tag_view.dart';
import 'package:suxingchahui/widgets/ui/components/game/game_tag_list.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';

class GameReviewPanel extends StatelessWidget {
  final GameWithCollection gameWithCollection;
  final VoidCallback onClose;

  const GameReviewPanel({
    super.key,
    required this.gameWithCollection,
    required this.onClose,
  });

  // 辅助方法：构建带图标的区域标题
  Widget _buildSectionTitle(BuildContext context, String title,
      {IconData? icon, EdgeInsetsGeometry? padding}) {
    final theme = Theme.of(context);
    final titleColor = theme.colorScheme.onSurface;
    final iconColor = titleColor.withSafeOpacity(0.7);

    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法：构建内容展示区域卡片 (评测/笔记)
  Widget _buildContentCard(
      BuildContext context, String? content, String emptyMessage) {
    final theme = Theme.of(context);
    final bool isEmpty = content == null || content.isEmpty;
    final contentColor = theme.colorScheme.onSurface;
    final emptyContentColor =
        theme.colorScheme.onSurfaceVariant.withSafeOpacity(0.65);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
          color: isEmpty
              ? Colors.transparent
              : theme.colorScheme.surfaceContainer.withSafeOpacity(0.8),
          borderRadius: BorderRadius.circular(8.0),
          border: isEmpty
              ? null
              : Border.all(
                  color: theme.dividerColor.withSafeOpacity(0.25), width: 0.5)),
      child: Text(
        isEmpty ? emptyMessage : content,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: isEmpty ? emptyContentColor : contentColor,
        ),
        textAlign: isEmpty ? TextAlign.start : TextAlign.justify,
      ),
    );
  }

  // 辅助方法：构建游戏信息项 (图标-标签-值)
  Widget _buildGameInfoRow(
      BuildContext context, IconData icon, String label, Widget valueWidget) {
    final theme = Theme.of(context);
    final labelColor = theme.colorScheme.onSurfaceVariant.withSafeOpacity(0.85);
    final iconColor = labelColor.withSafeOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 55, // 固定标签宽度，确保对齐
            child: Text(
              '$label:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  // 构建我的收藏状态及更新时间部分
  Widget _buildMyCollectionStatus(
      BuildContext context, GameCollectionItem collectionItem) {
    // 从统一的工具类获取主题
    final statusTheme =
        GameCollectionStatusUtils.getTheme(collectionItem.status);
    final statusLabel = statusTheme.text;
    final statusIcon = statusTheme.icon;
    final statusColor = statusTheme.textColor;

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '我的收藏状态',
            icon: Icons.bookmark_rounded,
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Chip(
              avatar: Icon(statusIcon, size: 16, color: statusColor),
              label: Text(statusLabel,
                  style: textTheme.labelMedium?.copyWith(
                      color: statusColor, fontWeight: FontWeight.bold)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              backgroundColor: statusColor.withSafeOpacity(0.12),
              visualDensity: VisualDensity.comfortable,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: statusColor.withSafeOpacity(0.35))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('上次更新',
                    style: textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withSafeOpacity(0.6))),
                Text(
                  DateTimeFormatter.formatRelative(collectionItem.updateTime),
                  style: textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 构建我的评分部分
  Widget _buildMyRating(
      BuildContext context, GameCollectionItem collectionItem) {
    if (collectionItem.status != GameCollectionStatus.played ||
        collectionItem.rating == null ||
        collectionItem.rating! <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '我的评分',
            icon: Icons.stars_rounded,
            padding: const EdgeInsets.only(top: 16.0, bottom: 4.0)),
        Row(
          children: [
            ...List.generate(5, (index) {
              double starValue = collectionItem.rating! / 2.0;
              IconData iconData;
              Color starFillColor = Colors.amber.shade600;
              if (index < starValue.floor()) {
                iconData = Icons.star_rounded;
              } else if (index < starValue && (starValue - index) >= 0.25) {
                iconData = Icons.star_half_rounded;
              } else {
                iconData = Icons.star_border_rounded;
                starFillColor = theme.colorScheme.outline.withSafeOpacity(0.5);
              }
              return Icon(iconData, size: 20, color: starFillColor);
            }),
            const SizedBox(width: 8),
            Text('(${collectionItem.rating!.toStringAsFixed(1)}/10)',
                style: textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500))
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTag(Game game) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          child: GameCategoryTagView(
            category: game.category,
            isMini: true,
          ),
        ),
      ],
    );
  }

  // 构建游戏基本信息部分
  Widget _buildGameInfo(BuildContext context, Game game) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // 分隔线
          padding: const EdgeInsets.only(top: 20.0, bottom: 4.0),
          child: Divider(
              thickness: 0.5, color: theme.dividerColor.withSafeOpacity(0.5)),
        ),
        _buildSectionTitle(context, '游戏基本信息',
            icon: Icons.videogame_asset_outlined,
            padding: const EdgeInsets.only(top: 4.0, bottom: 10.0)),
        if (game.category.isNotEmpty)
          _buildGameInfoRow(
              context, Icons.category_outlined, '类型', _buildCategoryTag(game)),
        if (game.tags.isNotEmpty)
          _buildGameInfoRow(context, Icons.local_offer_outlined, '标签',
              GameTagsRow(tags: game.tags, maxTags: 4, isScrollable: false)),
        _buildSectionTitle(context, '游戏统计',
            icon: Icons.analytics_outlined,
            padding: const EdgeInsets.only(top: 16.0, bottom: 4.0)),
        _buildGameInfoRow(
            context,
            Icons.people_outline,
            '想玩',
            Text('${game.wantToPlayCount}',
                style: textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        _buildGameInfoRow(
            context,
            Icons.play_circle_outline,
            '在玩',
            Text('${game.playingCount}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        _buildGameInfoRow(
            context,
            Icons.check_circle_outline,
            '玩过',
            Text('${game.playedCount}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        _buildGameInfoRow(
            context,
            Icons.collections_bookmark_outlined,
            '总收藏',
            Text('${game.totalCollections}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        _buildGameInfoRow(
            context,
            Icons.thumb_up_alt_outlined,
            '点赞',
            Text('${game.likeCount}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        _buildGameInfoRow(
            context,
            Icons.remove_red_eye_outlined,
            '浏览',
            Text('${game.viewCount}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        _buildGameInfoRow(
            context,
            Icons.star_outline_rounded,
            '评分人数',
            Text('${game.ratingCount}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
        if (game.summary.isNotEmpty) ...[
          _buildSectionTitle(context, '游戏简介',
              icon: Icons.article_outlined,
              padding: const EdgeInsets.only(top: 16.0, bottom: 6.0)),
          Text(
            game.summary,
            style: textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withSafeOpacity(0.9),
                height: 1.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ]
      ],
    );
  }

  // --- 主构建方法 ---

  @override
  Widget build(BuildContext context) {
    final collectionItem = gameWithCollection.collection;
    final Game? game = gameWithCollection.game;
    final theme = Theme.of(context);
    // final textTheme = theme.textTheme; // textTheme在辅助方法中已通过context获取

    return ClipRRect(
      // 裁剪圆角
      borderRadius: BorderRadius.circular(12.0),
      child: Stack(
        children: [
          // 1. 背景图片层 (只作用于本 Stack，不扩散到整个画面)
          if (game != null && game.coverImage.isNotEmpty)
            Positioned.fill(
              child: SafeCachedImage(
                imageUrl: game.coverImage,
                fit: BoxFit.fitWidth, // 确保宽度占满，高度按比例缩放，不拉伸
                alignment: Alignment.topCenter, // 顶部对齐，如果高度不够，裁剪底部
                memCacheWidth: 300,
                memCacheHeight:
                    (MediaQuery.of(context).size.height * 0.5).round(),
                onError: (url, error) {
                  // Error is handled by SafeCachedImage itself, but can log here.
                },
              ),
            ),

          // 2. 高斯模糊和半透明覆盖层 (作用于背景图，确保内容可读性)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // 调整为5.0，你要求的
              child: Container(
                color: theme.colorScheme.surface
                    .withSafeOpacity(0.8), // 覆盖层透明度调整为0.8，你要求的
              ),
            ),
          ),

          // 3. 前景内容层 (所有文字、卡片、按钮等)
          Column(
            children: [
              // 顶部栏：游戏标题和关闭按钮
              Material(
                // Material 确保顶部栏自身不被模糊
                elevation: 1.0,
                color: theme.colorScheme.surfaceContainerLowest
                    .withSafeOpacity(0.9), // 顶部栏背景色
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 8.0, top: 8.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          game?.title ?? '我的游戏收藏',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    // 直接获取 Theme.of(context)
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      FunctionalIconButton(
                        icon: Icons.close_rounded,
                        onPressed: onClose,
                        tooltip: '关闭',
                        iconSize: 22,
                        iconColor: theme.colorScheme.onSurfaceVariant,
                      )
                    ],
                  ),
                ),
              ),

              // 内容区：可滚动
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMyCollectionStatus(context, collectionItem),
                      _buildMyRating(context, collectionItem),
                      _buildSectionTitle(context, '我的评测内容',
                          icon: Icons.rate_review_outlined),
                      _buildContentCard(
                          context, collectionItem.review, '尚未填写评测。'),
                      _buildSectionTitle(context, '我的私人笔记',
                          icon: Icons.edit_note_outlined),
                      _buildContentCard(
                          context, collectionItem.notes, '尚未添加笔记。'),

                      if (game != null) _buildGameInfo(context, game),

                      // 底部元数据
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '首次收藏: ${DateTimeFormatter.formatShort(collectionItem.createTime)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant
                                        .withSafeOpacity(
                                            0.6)), // 直接获取 Theme.of(context)
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 跳转到游戏详情页按钮
                      if (game != null)
                        SizedBox(
                          // 使用 SizedBox 配合 width: double.infinity 让 FunctionalButton 占满宽度
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: FunctionalButton(
                              label: '查看游戏详情',
                              onPressed: () {
                                onClose(); // 先关闭当前Review面板
                                NavigationUtils.pushNamed(
                                  context,
                                  AppRoutes.gameDetail,
                                  arguments: game,
                                );
                              },
                              icon: Icons.info_outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
