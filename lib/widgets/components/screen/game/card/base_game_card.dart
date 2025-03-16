// lib/widgets/components/screen/game/card/base_game_card.dart
import 'package:flutter/material.dart';
import '../../../../../models/game/game.dart';
import '../../../../common/animated_card_container.dart';
import '../../../../../utils/device/device_utils.dart';
import '../tag/game_tags.dart';
import '../../../../common/image/safe_cached_image.dart';

/// 基础游戏卡片组件
///
/// 提供可配置的游戏卡片，以适应不同场景需求
class BaseGameCard extends StatelessWidget {
  final Game game;
  final double? imageHeight;
  final bool adaptForPanels;
  final bool showTags;
  final int maxTags;
  final bool forceCompact;

  /// 构造函数
  ///
  /// [game] 游戏数据模型
  /// [imageHeight] 可选的图片高度，默认为自动计算
  /// [adaptForPanels] 是否为带面板的布局适配尺寸
  /// [showTags] 是否显示标签
  /// [maxTags] 最多显示几个标签
  /// [forceCompact] 是否强制使用紧凑布局
  BaseGameCard({
    required this.game,
    this.imageHeight,
    this.adaptForPanels = false,
    this.showTags = true,
    this.maxTags = 2,
    this.forceCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // 获取设备信息
    final isAndroidPortrait = DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);

    // 计算每行卡片数量（用于动态调整布局）
    final cardsPerRow = DeviceUtils.calculateCardsPerRow(
        context,
        withPanels: adaptForPanels
    );

    // 确定是否使用紧凑布局
    final compact = forceCompact || (cardsPerRow > 3) || (cardsPerRow == 3 && adaptForPanels);

    // 计算图片高度
    final double actualImageHeight = imageHeight ?? (compact ? 140.0 : 160.0);

    // 计算内容区域最大行数
    final summaryMaxLines = _getSummaryMaxLines(isAndroidPortrait, compact);

    return AnimatedCardContainer(
      onTap: () {
        Navigator.pushNamed(context, '/game/detail', arguments: game);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片部分
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                child: SafeCachedImage(
                  imageUrl: game.coverImage,
                  height: actualImageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 480, // 适合大多数设备宽度的2倍
                  backgroundColor: Colors.grey[200],
                  onError: (url, error) {
                    print('游戏卡片图片加载失败: $url, 错误: $error');
                  },
                ),
              ),

              // 在图片上方显示类别标签
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 8,
                      vertical: compact ? 3 : 4
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.category,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 内容部分 - 使用 Padding 代替 ConstrainedBox 来避免溢出问题
          Padding(
            padding: EdgeInsets.all(compact ? 6 : 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  game.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _getTitleFontSize(isAndroidPortrait, compact),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 2 : 4),

                // 摘要
                Text(
                  game.summary,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: _getSummaryFontSize(isAndroidPortrait, compact),
                    height: 1.2,
                  ),
                  maxLines: summaryMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),

                // 标签部分 - 根据showTags和空间情况决定是否显示
                if (showTags && game.tags.isNotEmpty && summaryMaxLines > 0) ...[
                  SizedBox(height: compact ? 2 : 4),
                  GameTags(
                    game: game,
                    wrap: false,
                    maxTags: compact ? 1 : maxTags,
                    fontSize: compact ? 10 : 11,
                  ),
                ],

                // 底部统计信息
                SizedBox(height: compact ? 2 : 4),
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: compact ? 12 : (isAndroidPortrait ? 14 : 16),
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      game.likeCount.toString(),
                      style: TextStyle(fontSize: compact ? 10 : 12),
                    ),
                    SizedBox(width: 8),
                    Spacer(),
                    Icon(
                      Icons.remove_red_eye_outlined,
                      size: compact ? 12 : 14,
                      color: Colors.lightBlueAccent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      game.viewCount.toString(),
                      style: TextStyle(fontSize: compact ? 10 : 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取标题字体大小
  double _getTitleFontSize(bool isAndroidPortrait, bool compact) {
    if (compact) {
      return isAndroidPortrait ? 12 : 14;
    } else {
      return isAndroidPortrait ? 14 : 16;
    }
  }

  /// 获取摘要字体大小
  double _getSummaryFontSize(bool isAndroidPortrait, bool compact) {
    if (compact) {
      return isAndroidPortrait ? 10 : 12;
    } else {
      return isAndroidPortrait ? 12 : 14;
    }
  }

  /// 获取摘要最大行数 - 根据空间情况自动调整
  int _getSummaryMaxLines(bool isAndroidPortrait, bool compact) {
    if (compact) {
      // 紧凑模式时，Android竖屏只显示1行，其他情况显示1行
      return isAndroidPortrait ? 1 : 1;
    } else {
      // 标准模式时，Android竖屏显示1行，其他情况显示2行
      return isAndroidPortrait ? 1 : 2;
    }
  }
}