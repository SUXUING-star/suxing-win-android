// lib/widgets/components/screen/game/header/game_header.dart

/// 该文件定义了 GameHeader 组件，用于显示游戏详情页的头部信息。
/// GameHeader 负责展示游戏标题、简介、标签、分类和用户互动状态。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/models/game/game.dart'; // 游戏模型
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 日期时间格式化工具
import 'package:suxingchahui/widgets/components/screen/game/category/game_category_tag.dart'; // 游戏分类标签组件
import 'package:suxingchahui/widgets/components/screen/game/tag/game_tags.dart'; // 游戏标签组件
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载指示器组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 应用文本组件

/// `GameHeader` 类：游戏详情页的头部组件。
///
/// 该组件展示游戏的标题、简介、分类、标签、作者信息、浏览量、点赞数、投币数、
/// 收藏数、评分以及发布和更新时间。
class GameHeader extends StatelessWidget {
  final bool isDesktop; // 是否为桌面平台
  final Game game; // 游戏数据
  final User? currentUser; // 当前登录用户
  final UserInfoProvider infoProvider; // 用户信息 Provider
  final UserFollowService followService; // 用户关注服务
  final Function(BuildContext context, String category)?
      onClickFilterGameCategory; // 点击游戏分类的回调
  final Function(BuildContext context, String tag)?
      onClickFilterGameTag; // 点击游戏标签的回调
  final bool? isLiked; // 游戏是否被当前用户点赞
  final bool? isCoined; // 游戏是否被当前用户投币
  final bool isTogglingLike; // 点赞状态是否正在切换
  final bool isTogglingCoin; // 投币状态是否正在切换
  final VoidCallback? onToggleLike; // 切换点赞状态的回调
  final VoidCallback? onToggleCoin; // 切换投币状态的回调
  final int likeCount;
  final int coinsCount;

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [isDesktop]：是否为桌面平台。
  /// [game]：游戏数据。
  /// [currentUser]：当前登录用户。
  /// [infoProvider]：用户信息 Provider。
  /// [followService]：用户关注服务。
  /// [onClickFilterGameCategory]：点击游戏分类的回调。
  /// [onClickFilterGameTag]：点击游戏标签的回调。
  /// [isLiked]：游戏是否被当前用户点赞。
  /// [isCoined]：游戏是否被当前用户投币。
  /// [onToggleLike]：切换点赞状态的回调。
  /// [onToggleCoin]：切换投币状态的回调。
  /// [isTogglingLike]：点赞状态是否正在切换。
  /// [isTogglingCoin]：投币状态是否正在切换。
  const GameHeader({
    super.key,
    required this.isDesktop,
    required this.game,
    required this.currentUser,
    required this.infoProvider,
    required this.followService,
    this.onClickFilterGameCategory,
    this.onClickFilterGameTag,
    this.isLiked,
    this.isCoined,
    this.likeCount = 0,
    this.coinsCount = 0,
    this.onToggleLike,
    this.onToggleCoin,
    this.isTogglingLike = false,
    this.isTogglingCoin = false,
  });

  /// 构建 Widget。
  ///
  /// 渲染游戏头部信息，包括分类、标题、简介、标签和元数据。
  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 主轴对齐
            children: [
              GameCategoryTag(
                // 游戏分类标签
                needOnClick: true,
                onClickFilterGameCategory: onClickFilterGameCategory,
                category: game.category,
                isMini: false,
              ),
              _buildTopRightActions(context), // 右上角交互区域
            ],
          ),
          const SizedBox(height: 16), // 间距
          AppText(
            game.title, // 游戏标题
            fontSize: isDesktop ? 24 : 18,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          const SizedBox(height: 8), // 间距
          Text(
            game.summary, // 游戏简介
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
          if (game.tags.isNotEmpty) ...[
            // 游戏标签不为空时显示
            const SizedBox(height: 12), // 间距
            GameTags(
              onClickFilterGameTag: onClickFilterGameTag,
              game: game,
              wrap: false,
              maxTags: 5,
              needOnClick: true,
            ),
          ],
          const SizedBox(height: 12), // 间距
          Divider(color: Colors.grey[200]), // 分割线
          const SizedBox(height: 12), // 间距
          _buildMetaInfo(context), // 元数据信息区域
        ],
      ),
    );
  }

  /// 构建右上角的交互按钮和评分区域。
  ///
  /// [context]：Build 上下文。
  /// 返回包含点赞、投币按钮和评分的 Widget。
  Widget _buildTopRightActions(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary; // 主题主色
    final Color greyColor = Colors.grey.shade600; // 灰色

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 内边距
      decoration: BoxDecoration(
        color: Colors.grey.withSafeOpacity(0.08), // 背景颜色
        borderRadius: BorderRadius.circular(20), // 圆角
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 最小尺寸
        children: [
          _buildInteractionButton(
            // 点赞按钮
            isLoading: isTogglingLike,
            isDone: isLiked,
            doneIcon: Icons.favorite,
            undoneIcon: Icons.favorite_border,
            doneColor: primaryColor,
            undoneColor: greyColor,
            onPressed: onToggleLike,
            tooltip: isLiked == true ? '取消点赞' : '点赞',
          ),
          const SizedBox(width: 4), // 间距
          _buildInteractionButton(
            // 投币按钮
            isLoading: isTogglingCoin,
            isDone: isCoined,
            doneIcon: Icons.monetization_on,
            undoneIcon: Icons.monetization_on_outlined,
            doneColor: Colors.orange.shade700,
            undoneColor: greyColor,
            onPressed: onToggleCoin, // 已投币则禁用
            tooltip: isCoined == true
                ? (currentUser?.id == game.authorId ? '作者无法给自己投币' : '已投币')
                : '投币',
          ),
          const SizedBox(width: 8), // 间距
          const Icon(Icons.star, color: Colors.amber, size: 18), // 评分星标
          const SizedBox(width: 4), // 间距
          Text(
            game.rating.toString(), // 评分文本
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建通用交互按钮。
  ///
  /// [isLoading]：是否正在加载。
  /// [isDone]：操作是否已完成。
  /// [doneIcon]：操作完成时的图标。
  /// [undoneIcon]：操作未完成时的图标。
  /// [doneColor]：操作完成时的颜色。
  /// [undoneColor]：操作未完成时的颜色。
  /// [onPressed]：按钮点击回调。
  /// [tooltip]：提示文本。
  /// 返回一个 IconButton 或 LoadingWidget。
  Widget _buildInteractionButton({
    required bool isLoading,
    required bool? isDone,
    required IconData doneIcon,
    required IconData undoneIcon,
    required Color doneColor,
    required Color undoneColor,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    if (isLoading) {
      // 正在加载时显示加载指示器
      return const Padding(
        padding: EdgeInsets.all(8.0), // 内边距
        child: SizedBox(width: 20, height: 20, child: LoadingWidget()), // 加载指示器
      );
    }
    if (isDone == null) {
      // 状态未加载时不显示
      return const SizedBox.shrink(); // 返回空 Widget
    }
    return IconButton(
      icon: Icon(
        isDone ? doneIcon : undoneIcon, // 根据状态显示不同图标
        color: isDone ? doneColor : undoneColor, // 根据状态显示不同颜色
        size: 20,
      ),
      onPressed: onPressed, // 按钮点击回调
      tooltip: tooltip, // 提示文本
      padding: EdgeInsets.zero, // 无内边距
      constraints: const BoxConstraints(), // 无约束
    );
  }

  /// 构建元数据信息区域。
  ///
  /// [context]：Build 上下文。
  /// 返回包含作者、浏览量、点赞数、投币数、收藏数、评分、发布时间和更新时间的 Widget。
  Widget _buildMetaInfo(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 13,
      color: Colors.grey[600],
      height: 1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐
      children: [
        Wrap(
          // 自动换行布局
          spacing: 12, // 水平间距
          runSpacing: 8, // 垂直间距
          alignment: WrapAlignment.start, // 对齐方式
          crossAxisAlignment: WrapCrossAlignment.center, // 交叉轴对齐方式
          children: [
            UserInfoBadge(
              // 用户信息徽章
              infoProvider: infoProvider,
              followService: followService,
              targetUserId: game.authorId,
              currentUser: currentUser,
              mini: false,
              showLevel: true,
            ),
            Container(width: 1, height: 12, color: Colors.grey[300]), // 分隔线
            _buildMetaItem(
                Icons.remove_red_eye_outlined, // 浏览量
                '${game.viewCount} 次浏览',
                textStyle),
            _buildMetaItem(
                Icons.thumb_up_off_alt_outlined, // 点赞数
                likeCount != 0 ? '$likeCount 人点赞' : '${game.likeCount} 人点赞',
                textStyle),
            _buildMetaItem(
                Icons.monetization_on_outlined, // 投币数
                coinsCount != 0 ? '$coinsCount 人投币' : '${game.coinsCount} 人投币',
                textStyle),
            _buildMetaItem(
                Icons.bookmark_added_outlined, // 收藏数
                '${game.totalCollections} 人收藏',
                textStyle),
            _buildMetaItem(Icons.star_border_outlined, '评分值 ${game.rating}',
                textStyle), // 评分
          ],
        ),
        const SizedBox(height: 8), // 间距
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]), // 时间图标
            const SizedBox(width: 4), // 间距
            Text(
                '发布于 ${DateTimeFormatter.formatTimeAgo(game.createTime)}', // 发布时间
                style: textStyle),
            const SizedBox(width: 8), // 间距
            Text('·', style: textStyle), // 分隔符
            const SizedBox(width: 8), // 间距
            Text(
                '更新于 ${DateTimeFormatter.formatTimeAgo(game.updateTime)}', // 更新时间
                style: textStyle),
          ],
        ),
      ],
    );
  }

  /// 构建元数据项。
  ///
  /// [icon]：图标。
  /// [text]：文本。
  /// [style]：文本样式。
  /// 返回一个包含图标和文本的 Row Widget。
  Widget _buildMetaItem(IconData icon, String text, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 最小尺寸
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]), // 图标
        const SizedBox(width: 4), // 间距
        AppText(text, style: style), // 文本
      ],
    );
  }
}
