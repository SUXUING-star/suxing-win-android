// lib/widgets/components/screen/forum/post/layout/post_detail_layout.dart

/// 该文件定义了 PostDetailLayout 组件，一个用于展示帖子详情的布局。
/// PostDetailLayout 根据桌面或移动端布局，组织帖子内容、社区指南、最新回复和评论列表。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/post/post.dart'; // 导入帖子模型
import 'package:suxingchahui/models/post/user_post_actions.dart'; // 导入用户帖子操作模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 导入用户信息服务
import 'package:suxingchahui/services/main/forum/post_service.dart'; // 导入帖子服务
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/widgets/components/screen/forum/post/section/community_guidelines.dart'; // 导入社区指南组件
import 'package:suxingchahui/widgets/components/screen/forum/post/content/post_content.dart'; // 导入帖子内容组件
import 'package:suxingchahui/widgets/components/screen/forum/post/section/recent_global_replies.dart'; // 导入最新全局回复组件
import 'package:suxingchahui/widgets/components/screen/forum/post/reply/post_replies_list_item.dart'; // 导入帖子回复列表项组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件

/// `PostDetailLayout` 类：帖子详情布局组件。
///
/// 该组件根据桌面或移动端布局，组织帖子内容、社区指南、最新全局回复和帖子回复列表。
class PostDetailLayout extends StatelessWidget {
  /// 是否为桌面布局。
  final bool isDesktop;

  /// 帖子数据。
  final Post post;

  /// 帖子服务。
  final PostService postService;

  /// 用户关注服务。
  final UserFollowService followService;

  /// 用户信息服务。
  final UserInfoService infoService;

  /// 标签点击回调。
  final Function(BuildContext context, String tagString)? onTagTap;

  /// 输入状态服务。
  final InputStateService inputStateService;

  /// 认证服务。
  final AuthProvider authProvider;

  /// 用户帖子操作状态。
  final UserPostActions userActions;

  /// 帖子 ID。
  final String postId;

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
  /// [isDesktop]：是否桌面。
  /// [post]：帖子数据。
  /// [followService]：关注服务。
  /// [infoService]：用户信息服务。
  /// [onTagTap]：标签点击回调。
  /// [inputStateService]：输入状态服务。
  /// [postService]：帖子服务。
  /// [authProvider]：认证服务。
  /// [userActions]：用户操作。
  /// [postId]：帖子ID。
  const PostDetailLayout({
    super.key,
    required this.postService,
    required this.isDesktop,
    required this.post,
    required this.followService,
    required this.infoService,
    this.onTagTap,
    required this.inputStateService,
    required this.authProvider,
    required this.userActions,
    required this.postId,
    required this.isLiking,
    required this.isAgreeing,
    required this.isFavoriting,
    required this.onToggleLike,
    required this.onToggleAgree,
    required this.onToggleFavorite,
  });

  /// 构建帖子内容区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildPostContentSection(Duration duration, Duration delay, Key key) {
    return FadeInSlideUpItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: PostContent(
        onTagTap: onTagTap, // 标签点击回调
        infoService: infoService, // 用户信息服务
        followService: followService, // 关注服务
        currentUser: authProvider.currentUser, // 当前用户
        userActions: userActions, // 用户操作
        post: post, // 帖子数据
        isAgreeing: isAgreeing,
        onToggleAgree: onToggleAgree,
        isFavoriting: isFavoriting,
        onToggleFavorite: onToggleFavorite,
        isLiking: isLiking,
        onToggleLike: onToggleLike,
      ),
    );
  }

  /// 构建社区指南区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildCommunityGuidelinesSection(
      Duration duration, Duration delay, Key key) {
    return FadeInItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: const CommunityGuidelines(useSeparateCard: true), // 社区指南组件
    );
  }

  /// 构建最新全局回复区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  Widget _buildRecentGlobalRepliesSection(
      Duration duration, Duration delay, Key key) {
    return FadeInItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: RecentGlobalReplies(
        infoService: infoService, // 用户信息服务
        followService: followService, // 关注服务
        limit: 5, // 限制数量
        post: post, // 帖子数据
        currentUser: authProvider.currentUser, // 当前用户
        postService: postService, // 帖子服务
      ),
    );
  }

  /// 构建帖子回复列表区域。
  ///
  /// [duration]：动画时长。
  /// [delay]：动画延迟。
  /// [key]：组件键。
  /// [isScrollableInternally]：是否内部可滚动。
  Widget _buildPostReplyListSection(Duration duration, Duration delay, Key key,
      {bool isScrollableInternally = false}) {
    return FadeInItem(
      key: key, // 组件键
      duration: duration, // 动画时长
      delay: delay, // 动画延迟
      child: PostRepliesListItem(
        inputStateService: inputStateService, // 输入状态服务
        currentUser: authProvider.currentUser, // 当前用户
        followService: followService, // 关注服务
        infoService: infoService, // 用户信息服务
        postService: postService, // 帖子服务
        authProvider: authProvider, // 认证服务
        postId: postId, // 帖子 ID
        isScrollableInternally: isScrollableInternally, // 是否内部可滚动
      ),
    );
  }

  /// 构建帖子详情布局。
  ///
  /// [context]：Build 上下文。
  /// [keyPrefix]：键前缀。
  /// 根据 [isDesktop] 参数构建桌面或移动端布局。
  @override
  Widget build(BuildContext context) {
    final String keyPrefix = 'post_detail_layout_${post.id}'; // 统一键前缀

    if (isDesktop) {
      return _buildDesktopLayout(context, keyPrefix); // 构建桌面布局
    } else {
      return _buildMobileLayout(context, keyPrefix); // 构建移动端布局
    }
  }

  /// 构建桌面布局。
  ///
  /// [context]：Build 上下文。
  /// [keyPrefix]：键前缀。
  Widget _buildDesktopLayout(BuildContext context, String keyPrefix) {
    const Duration primaryDuration = Duration(milliseconds: 400);
    const Duration secondaryDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration incrementDelay = Duration(milliseconds: 75);
    int leftDelayIndex = 0;
    int rightDelayIndex = 0;

    final postContentKey = ValueKey('${keyPrefix}_post_content_desk'); // 帖子内容键
    final guidelinesKey = ValueKey('${keyPrefix}_guidelines_desk'); // 指南键
    final recentRepliesKey =
        ValueKey('${keyPrefix}_recent_replies_desk'); // 最新回复键
    final replyListKey = ValueKey('${keyPrefix}_reply_list_desk'); // 回复列表键

    return Padding(
      padding: const EdgeInsets.all(16.0), // 内边距
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
        children: [
          Expanded(
            flex: 4, // 比例
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPostContentSection(
                    primaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                    postContentKey,
                  ),
                  const SizedBox(height: 24), // 间距
                  _buildCommunityGuidelinesSection(
                    secondaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                    guidelinesKey,
                  ),
                  const SizedBox(height: 16), // 间距
                  _buildRecentGlobalRepliesSection(
                    secondaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                    recentRepliesKey,
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1), // 垂直分隔线
          Expanded(
            flex: 6, // 比例
            child: Column(
              children: [
                const SizedBox(height: 16), // 顶部间距
                Expanded(
                  child: _buildPostReplyListSection(
                    secondaryDuration,
                    baseDelay +
                        (incrementDelay * rightDelayIndex++) +
                        incrementDelay,
                    replyListKey,
                    isScrollableInternally: true, // 内部可滚动
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建移动端布局。
  ///
  /// [context]：Build 上下文。
  /// [keyPrefix]：键前缀。
  Widget _buildMobileLayout(BuildContext context, String keyPrefix) {
    const Duration contentDuration = Duration(milliseconds: 400);
    const Duration replyListDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration replyDelay = Duration(milliseconds: 150);

    final postContentKey = ValueKey('${keyPrefix}_post_content_mob'); // 帖子内容键
    final replyListKey = ValueKey('${keyPrefix}_reply_list_mob'); // 回复列表键

    return ListView(
      children: [
        _buildPostContentSection(
          contentDuration,
          baseDelay,
          postContentKey,
        ),
        const Divider(height: 1), // 分隔线
        _buildPostReplyListSection(
          replyListDuration,
          baseDelay + replyDelay,
          replyListKey,
        ),
      ],
    );
  }
}
