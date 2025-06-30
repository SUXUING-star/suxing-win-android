// lib/widgets/components/screen/forum/post/layout/post_detail_layout.dart

/// 该文件定义了 [PostDetailLayout] 组件，一个用于展示帖子详情的布局。
/// [PostDetailLayout] 根据桌面或移动端布局，组织帖子内容、社区指南、最新回复和评论列表。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/dart/func_extension.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/section/community/community_guidelines.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/section/content/post_content.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/section/recent_replies/recent_global_replies.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/section/reply/post_replies_list_section.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';

/// `PostDetailLayout` 类：帖子详情布局组件。
class PostDetailLayout extends StatelessWidget {
  final bool isDesktop;
  final Post post;
  final PostService postService;
  final UserFollowService followService;
  final UserInfoService infoService;
  final Function(BuildContext context, String tagString)? onTagTap;
  final InputStateService inputStateService;
  final AuthProvider authProvider;
  final UserPostActions userActions;
  final String postId;
  final bool hasShared;
  final bool isSharing;
  final FutureVoidCallback onShare;
  final bool isLiking;
  final bool isAgreeing;
  final bool isFavoriting;
  final FutureVoidCallback onToggleLike;
  final FutureVoidCallback onToggleAgree;
  final FutureVoidCallback onToggleFavorite;

  final String deviceCtx;

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
    required this.hasShared,
    required this.isSharing,
    required this.onShare,
    required this.isLiking,
    required this.isAgreeing,
    required this.isFavoriting,
    required this.onToggleLike,
    required this.onToggleAgree,
    required this.onToggleFavorite,
  }) : deviceCtx = isDesktop ? 'desk' : 'mob';

  /// 构建一个唯一的 [ValueKey]。
  ValueKey _makeValueKey(String mainCtx) =>
      ValueKey('${mainCtx}_${deviceCtx}_${post.id}');

  // --- 【核心重构区】: 所有 _buildXXXSection 方法的签名都被简化 ---

  Widget _buildPostContentSection(Duration duration, Duration delay) {
    return FadeInSlideUpItem(
      key: _makeValueKey('post_content'),
      duration: duration,
      delay: delay,
      child: PostContentSection(
        onTagTap: onTagTap,
        infoService: infoService,
        followService: followService,
        currentUser: authProvider.currentUser,
        userActions: userActions,
        post: post,
        isSharing: isSharing,
        hasShared: hasShared,
        onShare: onShare,
        isAgreeing: isAgreeing,
        onToggleAgree: onToggleAgree,
        isFavoriting: isFavoriting,
        onToggleFavorite: onToggleFavorite,
        isLiking: isLiking,
        onToggleLike: onToggleLike,
      ),
    );
  }

  Widget _buildCommunityGuidelinesSection(Duration duration, Duration delay) {
    return FadeInItem(
      key: _makeValueKey('guidelines'),
      duration: duration,
      delay: delay,
      child: const CommunityGuidelines(useSeparateCard: true),
    );
  }

  Widget _buildRecentGlobalRepliesSection(Duration duration, Duration delay) {
    return FadeInItem(
      key: _makeValueKey('recent_replies'),
      duration: duration,
      delay: delay,
      child: RecentGlobalReplies(
        infoService: infoService,
        followService: followService,
        limit: 5,
        post: post,
        currentUser: authProvider.currentUser,
        postService: postService,
      ),
    );
  }

  Widget _buildPostReplyListSection(Duration duration, Duration delay,
      {bool isScrollableInternally = false}) {
    return FadeInItem(
      key: _makeValueKey('reply_list'),
      duration: duration,
      delay: delay,
      child: PostRepliesListSection(
        inputStateService: inputStateService,
        currentUser: authProvider.currentUser,
        followService: followService,
        infoService: infoService,
        postService: postService,
        authProvider: authProvider,
        postId: postId,
        isScrollableInternally: isScrollableInternally,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    const Duration primaryDuration = Duration(milliseconds: 400);
    const Duration secondaryDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration incrementDelay = Duration(milliseconds: 75);
    int leftDelayIndex = 0;
    int rightDelayIndex = 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPostContentSection(
                    primaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                  ),
                  const SizedBox(height: 24),
                  _buildCommunityGuidelinesSection(
                    secondaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentGlobalRepliesSection(
                    secondaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 6,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: _buildPostReplyListSection(
                    secondaryDuration,
                    baseDelay +
                        (incrementDelay * rightDelayIndex++) +
                        incrementDelay,
                    isScrollableInternally: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    const Duration contentDuration = Duration(milliseconds: 400);
    const Duration replyListDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration replyDelay = Duration(milliseconds: 150);

    return ListView(
      children: [
        _buildPostContentSection(contentDuration, baseDelay),
        const Divider(height: 1),
        _buildPostReplyListSection(
          replyListDuration,
          baseDelay + replyDelay,
        ),
      ],
    );
  }
}
