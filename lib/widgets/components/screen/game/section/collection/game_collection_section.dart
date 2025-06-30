// lib/widgets/components/screen/game/section/collection/game_collection_section.dart

/// 该文件定义了 GameCollectionSection 组件，用于显示游戏的收藏和评分信息。
/// GameCollectionSection 包含收藏按钮和各项统计数据。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:intl/intl.dart'; // 国际化格式化所需
import 'package:suxingchahui/models/extension/theme/preset/common_color_theme.dart';
import 'package:suxingchahui/models/game/collection/enrich_collection_status.dart';
import 'package:suxingchahui/models/game/game/game.dart'; // 游戏模型所需
import 'package:suxingchahui/models/game/collection/collection_item.dart'; // 游戏收藏项模型所需
import 'package:suxingchahui/models/user/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 输入状态 Provider 所需
import 'package:suxingchahui/services/main/game/game_collection_service.dart'; // 游戏收藏服务所需
import 'package:suxingchahui/widgets/components/screen/game/section/collection/game_collection_button.dart'; // 游戏收藏按钮组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// `GameCollectionSection` 类：显示游戏收藏和评分信息的 StatelessWidget。
///
/// 该组件展示游戏的收藏数量、评分以及提供收藏操作按钮。
class GameCollectionSection extends StatelessWidget {
  final Game game; // 游戏数据
  final InputStateService inputStateService; // 输入状态服务
  final GameCollectionService gameCollectionService; // 游戏收藏服务
  final User? currentUser; // 当前登录用户
  final CollectionItem? collectionStatus; // 初始收藏状态
  /// 收藏按钮是否处于加载状态。
  final bool? isCollectionLoading;

  /// 收藏按钮被点击时的回调。
  final Future<void> Function()? onCollectionButtonPressed;
  final bool isPreviewMode; // 是否为预览模式

  /// 构造函数。
  const GameCollectionSection({
    super.key,
    required this.game,
    required this.inputStateService,
    required this.gameCollectionService,
    required this.currentUser,
    this.collectionStatus,
    this.isCollectionLoading,
    this.onCollectionButtonPressed,
    this.isPreviewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final wantToPlayCount = game.wantToPlayCount; // 想玩数量
    final playingCount = game.playingCount; // 正在玩数量
    final playedCount = game.playedCount; // 已玩数量
    final totalCollections = game.totalCollections; // 总收藏数量
    final rating = game.rating; // 评分
    final ratingCount = game.ratingCount; // 评分人数

    final formattedRating = rating > 0
        ? NumberFormat('0.0').format(rating)
        : (ratingCount > 0 ? '0.0' : '暂无'); // 格式化后的评分

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withSafeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '收藏与评分',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (!isPreviewMode &&
                  onCollectionButtonPressed != null) // 预览模式下不显示收藏按钮
                GameCollectionButton(
                  collectionItem: collectionStatus,
                  isLoading: isCollectionLoading ?? false,
                  onPressed: onCollectionButtonPressed!,
                  compact: false,
                  isPreview: isPreviewMode,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatContainer(
                  context,
                  EnrichCollectionStatus.wantToPlayTheme,
                  wantToPlayCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatContainer(
                  context,
                  EnrichCollectionStatus.playingTheme,
                  playingCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatContainer(
                  context,
                  EnrichCollectionStatus.playedTheme,
                  playedCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatContainer(
                  context,
                  EnrichCollectionStatus.ratingDisplayTheme,
                  formattedRating,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]), // 分割线
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_alt_outlined,
                  size: 18, color: theme.primaryColor.withSafeOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                '总收藏 $totalCollections 人${ratingCount > 0 ? ' / $ratingCount 人评分' : ''}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor.withSafeOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个统计信息展示块。
  ///
  /// [context]：Build 上下文。
  /// [theme]：收藏状态主题。
  /// [value]：统计数值。
  /// 返回一个包含图标、文本和数值的容器。
  Widget _buildStatContainer(
    BuildContext context,
    CommonColorTheme theme,
    dynamic value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
          color: theme.backgroundColor, borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: theme.textColor.withSafeOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]),
            child:
                Icon(theme.iconData, color: theme.textColor, size: 24), // 状态图标
          ),
          const SizedBox(height: 8),
          Text(theme.textLabel, // 状态文本
              style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value.toString(), // 统计数值
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
