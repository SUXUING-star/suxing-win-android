import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/models/post/post.dart';
import '../post_content.dart';
import '../reply/post_reply_list.dart';

class PostDetailMobileLayout extends StatelessWidget {
  final Post post;
  final AuthProvider authProvider;
  final UserInfoProvider infoProvider;
  final InputStateService inputStateService;
  final UserFollowService followService;
  final ForumService forumService;
  final UserPostActions userActions;
  final String postId;
  final Function(Post, UserPostActions) onPostUpdated;
  final Function(BuildContext context, String tagString)? onTagTap;

  const PostDetailMobileLayout({
    super.key,
    required this.post,
    required this.infoProvider,
    required this.inputStateService,
    required this.forumService,
    required this.followService,
    required this.authProvider,
    required this.userActions,
    required this.postId,
    required this.onPostUpdated,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    // 定义动画参数
    const Duration contentDuration = Duration(milliseconds: 400);
    const Duration replyListDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50); // 起始延迟
    const Duration replyDelay = Duration(milliseconds: 150); // 回复列表延迟
    // 修复滚动问题，使用 ListView 替代 Column
    return ListView(
      children: [
        // --- PostContent 带动画 ---
        FadeInSlideUpItem(
          key: ValueKey('post_content_mob_${post.id}'), // Key
          duration: contentDuration,
          delay: baseDelay, // 先出现
          child: PostContent(
            forumService: forumService,
            currentUser: authProvider.currentUser,
            followService:  followService,
            infoProvider: infoProvider,
            userActions: userActions,
            post: post,
            onTagTap: onTagTap,
            onPostUpdated: onPostUpdated,
          ),
        ),
        const Divider(height: 1), // 分隔线无动画

        // --- ReplyList 的容器带动画 ---
        FadeInItem(
          // 使用纯淡入
          key: ValueKey('reply_list_mob_${post.id}'), // Key
          duration: replyListDuration,
          delay: baseDelay + replyDelay, // 稍后出现

          child: PostReplyList(
            infoProvider: infoProvider,
            inputStateService: inputStateService,
            followService: followService,
            forumService: forumService,
            authProvider: authProvider,
            currentUser: authProvider.currentUser,
            postId: postId,
          ),
        ),
      ],
    );
  }
}
