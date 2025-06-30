// lib/widgets/components/screen/forum/post/section/content/post_content.dart

/// 该文件定义了 PostContent 组件，用于显示帖子的详细内容。
/// 该组件包含了帖子的标题、作者信息、标签、正文和交互按钮。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/post/user_post_actions.dart'; // 用户帖子交互状态模型
import 'package:suxingchahui/models/user/user/user.dart'; // 用户模型
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/utils/dart/func_extension.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/section/action/post_actions_buttons.dart'; // 帖子交互按钮组件
import 'package:suxingchahui/widgets/components/screen/forum/post/section/tags/post_tags.dart'; // 帖子标签组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法
import 'package:suxingchahui/models/post/post.dart'; // 帖子模型
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 日期时间格式化工具
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件

/// `PostContent` 类：显示帖子详细内容的 UI 组件。
///
/// 该组件是无状态的，其渲染和交互功能依赖于传入的属性和回调。
class PostContentSection extends StatelessWidget {
  final Post post; // 当前帖子数据

  final UserInfoService infoService; // 用户信息服务实例

  final UserFollowService followService; // 用户关注服务实例

  final User? currentUser; // 当前登录用户

  final UserPostActions userActions; // 当前用户对帖子的交互状态

  final Function(BuildContext context, String tagString)? onTagTap; // 标签点击回调

  final bool isSharing;

  final bool hasShared;

  final FutureVoidCallback onShare;

  final bool isLiking; // 点赞操作是否正在进行

  final bool isAgreeing; // 赞同操作是否正在进行

  final bool isFavoriting; // 收藏操作是否正在进行

  final FutureVoidCallback onToggleLike; // 点击“点赞”按钮的回调

  final FutureVoidCallback onToggleAgree; // 点击“赞同”按钮的回调

  final FutureVoidCallback onToggleFavorite; // 点击“收藏”按钮的回调

  /// 构造函数。
  ///
  /// [currentUser]：当前登录用户。
  /// [infoService]：用户信息服务。
  /// [followService]：用户关注服务。
  /// [userActions]：用户帖子交互状态。
  /// [post]：帖子数据。
  /// [onTagTap]：标签点击回调。
  /// [isLiking]：点赞加载状态。
  /// [isAgreeing]：赞同加载状态。
  /// [isFavoriting]：收藏加载状态。
  /// [onToggleLike]：点赞回调。
  /// [onToggleAgree]：赞同回调。
  /// [onToggleFavorite]：收藏回调。
  const PostContentSection({
    super.key,
    required this.currentUser,
    required this.infoService,
    required this.followService,
    required this.userActions,
    required this.post,
    required this.onTagTap,
    required this.isSharing,
    required this.onShare,
    required this.hasShared,
    required this.isLiking,
    required this.isAgreeing,
    required this.isFavoriting,
    required this.onToggleLike,
    required this.onToggleAgree,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop ||
        DeviceUtils.isWeb ||
        DeviceUtils.isTablet(context); // 判断是否为桌面或平板等宽屏设备

    return Container(
      margin:
          isDesktop ? EdgeInsets.zero : const EdgeInsets.all(16), // 根据设备类型设置外边距
      padding: const EdgeInsets.all(16), // 内边距
      decoration: BoxDecoration(
        color: Colors.white.withSafeOpacity(0.9), // 背景颜色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: isDesktop
            ? [] // 桌面端无阴影
            : [
                BoxShadow(
                  color: Colors.black.withSafeOpacity(0.05), // 阴影颜色
                  blurRadius: 10, // 模糊半径
                  offset: const Offset(0, 2), // 阴影偏移
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
        children: [
          // 标题栏
          Row(
            children: [
              Container(
                width: 4, // 装饰条宽度
                height: 24, // 装饰条高度
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor, // 装饰条颜色
                  borderRadius: BorderRadius.circular(2), // 装饰条圆角
                ),
              ),
              const SizedBox(width: 12), // 间距
              Expanded(
                child: Text(
                  post.title, // 帖子标题
                  style: TextStyle(
                    fontSize: isDesktop ? 22 : 18, // 字体大小
                    fontWeight: FontWeight.bold, // 字体粗细
                    color: const Color(0xFF333333), // 字体颜色
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // 间距

          // 作者信息栏
          _buildAuthorRow(context, isDesktop), // 构建作者信息行

          const SizedBox(height: 20), // 间距

          // 标签栏
          if (post.tags.isNotEmpty) // 存在标签时显示
            PostTags(
              post: post, // 帖子数据
              isMini: !isDesktop, // 是否为迷你模式
              onTagTap: onTagTap, // 标签点击回调
            ),
          if (post.tags.isNotEmpty) const SizedBox(height: 20), // 标签下间距
          // 内容栏
          Container(
            width: double.infinity, // 宽度填充
            padding: const EdgeInsets.all(16), // 内边距
            decoration: BoxDecoration(
              color: isDesktop ? Colors.grey[50] : Colors.white, // 背景颜色
              borderRadius: BorderRadius.circular(8), // 圆角
              border: isDesktop
                  ? Border.all(color: Colors.grey[200]!)
                  : null, // 桌面端边框
            ),
            child: Text(
              post.content, // 帖子内容
              style: TextStyle(
                fontSize: isDesktop ? 16 : 15, // 字体大小
                height: 1.8, // 行高
                color: Colors.grey[800], // 字体颜色
              ),
            ),
          ),

          // 交互按钮
          const SizedBox(height: 16), // 间距
          PostActionsButtons(
            userActions: userActions, // 用户交互状态
            post: post, // 帖子数据
            isSharing: isSharing,
            hasShared: hasShared,
            onShare: onShare,
            isAgreeing: isAgreeing, // 赞同加载状态
            onToggleAgree: onToggleAgree, // 赞同回调
            isFavoriting: isFavoriting, // 收藏加载状态
            onToggleFavorite: onToggleFavorite, // 收藏回调
            isLiking: isLiking, // 点赞加载状态
            onToggleLike: onToggleLike, // 点赞回调
          ),

          // 帖子统计数据
          if (isDesktop) // 桌面端显示
            Padding(
              padding: const EdgeInsets.only(top: 16), // 顶部内边距
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // 右对齐
                children: [
                  Icon(Icons.remove_red_eye,
                      size: 16, color: Colors.grey[500]), // 浏览图标
                  const SizedBox(width: 4), // 间距
                  Text(
                    '${post.viewCount}', // 浏览计数
                    style: TextStyle(
                      fontSize: 14, // 字体大小
                      color: Colors.grey[500], // 字体颜色
                    ),
                  ),
                  const SizedBox(width: 16), // 间距
                  Icon(Icons.comment,
                      size: 16, color: Colors.grey[500]), // 评论图标
                  const SizedBox(width: 4), // 间距
                  Text(
                    '${post.replyCount}', // 评论计数
                    style: TextStyle(
                      fontSize: 14, // 字体大小
                      color: Colors.grey[500], // 字体颜色
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建帖子作者信息行。
  ///
  /// [context]：Build 上下文。
  /// [isDesktop]：是否为桌面模式。
  Widget _buildAuthorRow(BuildContext context, bool isDesktop) {
    final userId = post.authorId; // 帖子作者 ID

    return Row(
      children: [
        Expanded(
          child: UserInfoBadge(
            currentUser: currentUser, // 当前用户
            infoService: infoService, // 用户信息服务
            followService: followService, // 关注服务
            targetUserId: userId, // 目标用户 ID
            showFollowButton: false, // 不显示关注按钮
            mini: !isDesktop, // 是否为迷你模式
            padding: EdgeInsets.zero, // 内边距
          ),
        ),
        const SizedBox(width: 8), // 间距
        // 楼主标签
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 内边距
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withSafeOpacity(0.1), // 背景颜色
            borderRadius: BorderRadius.circular(4), // 圆角
          ),
          child: Text(
            '楼主', // 标签文本
            style: TextStyle(
              fontSize: 12, // 字体大小
              color: Theme.of(context).primaryColor, // 字体颜色
            ),
          ),
        ),
        const SizedBox(width: 12), // 间距
        // 发布时间
        Text(
          DateTimeFormatter.formatRelative(post.createTime), // 格式化发布时间
          style: TextStyle(
            fontSize: 12, // 字体大小
            color: Colors.grey[600], // 字体颜色
          ),
        ),
      ],
    );
  }
}
