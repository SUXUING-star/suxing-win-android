// lib/widgets/components/screen/forum/post/layout/post_detail_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/community_guidelines.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/post_content.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/recent_global_replies.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/reply/post_replies_list_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';

class PostDetailLayout extends StatelessWidget {
  final bool isDesktop;
  final Post post;
  final UserFollowService followService;
  final UserInfoProvider infoProvider;
  final Function(BuildContext context, String tagString)? onTagTap;
  final InputStateService inputStateService;
  final PostService postService;
  final AuthProvider authProvider;
  final UserPostActions userActions;
  final String postId;
  final Function(Post, UserPostActions) onPostUpdated;

  const PostDetailLayout({
    super.key,
    required this.isDesktop,
    required this.post,
    required this.followService,
    required this.infoProvider,
    this.onTagTap,
    required this.inputStateService,
    required this.postService,
    required this.authProvider,
    required this.userActions,
    required this.postId,
    required this.onPostUpdated,
  });

  // --- Section Builder Methods ---

  Widget _buildPostContentSection(Duration duration, Duration delay, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration: duration,
      delay: delay,
      child: PostContent(
        onTagTap: onTagTap,
        postService: postService,
        infoProvider: infoProvider,
        followService: followService,
        currentUser: authProvider.currentUser,
        userActions: userActions,
        post: post,
        onPostUpdated: onPostUpdated,
      ),
    );
  }

  Widget _buildCommunityGuidelinesSection(
      Duration duration, Duration delay, Key key) {
    return FadeInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: const CommunityGuidelines(useSeparateCard: true),
    );
  }

  Widget _buildRecentGlobalRepliesSection(
      Duration duration, Duration delay, Key key) {
    return FadeInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: RecentGlobalReplies(
        infoProvider: infoProvider,
        followService: followService,
        limit: 5,
        post: post,
        currentUser: authProvider.currentUser,
        postService: postService,
      ),
    );
  }

  Widget _buildPostReplyListSection(Duration duration, Duration delay, Key key,
      {bool isScrollableInternally = false}) {
    return FadeInItem(
      key: key,
      duration: duration,
      delay: delay,
      child: PostRepliesListItem(
        inputStateService: inputStateService,
        currentUser: authProvider.currentUser,
        followService: followService,
        infoProvider: infoProvider,
        postService: postService,
        authProvider: authProvider,
        postId: postId,
        isScrollableInternally: isScrollableInternally, // For desktop layout
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 统一 key 前缀，确保 game.id 变化时整个内容区重建，触发动画
    final String keyPrefix = 'post_detail_layout_${post.id}';

    if (isDesktop) {
      return _buildDesktopLayout(context, keyPrefix);
    } else {
      return _buildMobileLayout(context, keyPrefix);
    }
  }

  Widget _buildDesktopLayout(BuildContext context, String keyPrefix) {
    const Duration primaryDuration = Duration(milliseconds: 400);
    const Duration secondaryDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration incrementDelay = Duration(milliseconds: 75);
    int leftDelayIndex = 0;
    int rightDelayIndex = 0;

    final postContentKey = ValueKey('${keyPrefix}_post_content_desk');
    final guidelinesKey = ValueKey('${keyPrefix}_guidelines_desk');
    final recentRepliesKey = ValueKey('${keyPrefix}_recent_replies_desk');
    final replyListKey = ValueKey('${keyPrefix}_reply_list_desk');

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
                    postContentKey,
                  ),
                  const SizedBox(height: 24),
                  _buildCommunityGuidelinesSection(
                    secondaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                    guidelinesKey,
                  ),
                  const SizedBox(height: 16),
                  _buildRecentGlobalRepliesSection(
                    secondaryDuration,
                    baseDelay + (incrementDelay * leftDelayIndex++),
                    recentRepliesKey,
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
                const SizedBox(
                    height:
                        16), // Placeholder for potential reply input above list
                Expanded(
                  child: _buildPostReplyListSection(
                    secondaryDuration,
                    baseDelay +
                        (incrementDelay * rightDelayIndex++) +
                        incrementDelay,
                    replyListKey,
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

  Widget _buildMobileLayout(BuildContext context, String keyPrefix) {
    const Duration contentDuration = Duration(milliseconds: 400);
    const Duration replyListDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration replyDelay =
        Duration(milliseconds: 150); // Delay for reply list after content

    final postContentKey = ValueKey('${keyPrefix}_post_content_mob');
    final replyListKey = ValueKey('${keyPrefix}_reply_list_mob');

    return ListView(
      children: [
        _buildPostContentSection(
          contentDuration,
          baseDelay,
          postContentKey,
        ),
        const Divider(height: 1),
        _buildPostReplyListSection(
          replyListDuration,
          baseDelay + replyDelay,
          replyListKey,
          // isScrollableInternally for mobile PostReplyList is typically false, handled by outer ListView
        ),
      ],
    );
  }
}
