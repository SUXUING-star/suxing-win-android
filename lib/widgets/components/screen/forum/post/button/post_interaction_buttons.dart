// lib/widgets/components/screen/forum/post/button/post_interaction_buttons.dart

/// 该文件定义了 PostInteractionButtons 组件，用于帖子交互操作。
/// 该组件提供点赞、赞同和收藏按钮，并显示相应的计数。
library;


import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/post/post.dart'; // 帖子模型
import 'package:suxingchahui/models/post/user_post_actions.dart'; // 用户帖子交互状态模型
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件

/// `PostInteractionButtons` 类：帖子交互按钮的 UI 组件。
///
/// 这是一个无状态组件，其 UI 渲染和加载状态完全依赖外部传入的属性。
/// 用户操作通过回调函数通知外部。
class PostInteractionButtons extends StatelessWidget {
  /// 当前帖子数据。
  final Post post;

  /// 当前用户对帖子的交互状态。
  final UserPostActions userActions;

  /// 点赞操作是否正在进行。
  final bool isLiking;

  /// 赞同操作是否正在进行。
  final bool isAgreeing;

  /// 收藏操作是否正在进行。
  final bool isFavoriting;

  /// 点击“点赞”按钮的回调。
  final VoidCallback onToggleLike;

  /// 点击“赞同”按钮的回调。
  final VoidCallback onToggleAgree;

  /// 点击“收藏”按钮的回调。
  final VoidCallback onToggleFavorite;

  /// 构造函数。
  ///
  /// [post]：当前帖子数据。
  /// [userActions]：用户对帖子的交互状态。
  /// [isLiking]：点赞操作加载状态。
  /// [isAgreeing]：赞同操作加载状态。
  /// [isFavoriting]：收藏操作加载状态。
  /// [onToggleLike]：点赞按钮回调。
  /// [onToggleAgree]：赞同按钮回调。
  /// [onToggleFavorite]：收藏按钮回调。
  const PostInteractionButtons({
    super.key,
    required this.post,
    required this.userActions,
    required this.isLiking,
    required this.isAgreeing,
    required this.isFavoriting,
    required this.onToggleLike,
    required this.onToggleAgree,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop; // 判断是否为桌面平台
    final double iconSize = isDesktop ? 20.0 : 18.0; // 图标尺寸
    final double fontSize = isDesktop ? 14.0 : 12.0; // 字体尺寸
    final EdgeInsets padding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6); // 内边距

    final bool isLiked = userActions.liked; // 用户是否已点赞
    final bool isAgreed = userActions.agreed; // 用户是否已赞同
    final bool isFavorited = userActions.favorited; // 用户是否已收藏

    final int likeCount = post.likeCount; // 点赞计数
    final int agreeCount = post.agreeCount; // 赞同计数
    final int favoriteCount = post.favoriteCount; // 收藏计数

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInteractionButton(
          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, // 点赞图标
          label: '$likeCount', // 点赞计数
          color: isLiked ? Theme.of(context).primaryColor : Colors.grey, // 图标颜色
          onTap: onToggleLike, // 点赞回调
          isLoading: isLiking, // 点赞加载状态
          iconSize: iconSize,
          fontSize: fontSize,
          padding: padding,
        ),
        _buildInteractionButton(
          icon: isAgreed
              ? Icons.check_circle
              : Icons.check_circle_outline, // 赞同图标
          label: '$agreeCount', // 赞同计数
          color: isAgreed ? Colors.green : Colors.grey, // 图标颜色
          onTap: onToggleAgree, // 赞同回调
          isLoading: isAgreeing, // 赞同加载状态
          iconSize: iconSize,
          fontSize: fontSize,
          padding: padding,
        ),
        _buildInteractionButton(
          icon: isFavorited ? Icons.star : Icons.star_border, // 收藏图标
          label: '$favoriteCount', // 收藏计数
          color: isFavorited ? Colors.amber : Colors.amber, // 图标颜色
          onTap: onToggleFavorite, // 收藏回调
          isLoading: isFavoriting, // 收藏加载状态
          iconSize: iconSize,
          fontSize: fontSize,
          padding: padding,
        ),
      ],
    );
  }

  /// 构建单个交互按钮的 UI。
  ///
  /// [icon]：按钮图标。
  /// [label]：按钮文本标签。
  /// [color]：按钮图标和文本颜色。
  /// [onTap]：按钮点击回调。
  /// [isLoading]：按钮是否处于加载状态。
  /// [iconSize]：图标尺寸。
  /// [fontSize]：字体尺寸。
  /// [padding]：按钮内边距。
  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
    required double iconSize,
    required double fontSize,
    required EdgeInsets padding,
  }) {
    return IgnorePointer(
      ignoring: isLoading, // 加载状态时忽略指针事件
      child: InkWell(
        onTap: onTap, // 绑定点击回调
        borderRadius: BorderRadius.circular(8), // 圆角
        child: Padding(
          padding: padding, // 内边距
          child: Row(
            mainAxisSize: MainAxisSize.min, // 适应内容大小
            children: [
              if (isLoading) // 如果处于加载状态
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: const LoadingWidget(), // 显示加载组件
                )
              else
                Icon(icon, size: iconSize, color: color), // 显示图标
              const SizedBox(width: 4), // 间距
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isLoading ? Colors.grey : color, // 加载状态时文本颜色变灰
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
