// lib/widgets/components/screen/forum/post/post_content.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/post_interaction_buttons.dart';
import 'package:suxingchahui/widgets/components/screen/forum/post/tag/post_tags.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';

class PostContent extends StatelessWidget {
  final Post post;
  final PostService postService;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final User? currentUser;
  final UserPostActions userActions;
  final Function(Post, UserPostActions) onPostUpdated;
  final Function(BuildContext context, String tagString)? onTagTap;

  const PostContent({
    super.key,
    required this.currentUser,
    required this.postService,
    required this.infoProvider,
    required this.followService,
    required this.userActions,
    required this.post,
    required this.onPostUpdated,
    required this.onTagTap,
  });


  @override
  Widget build(BuildContext context) {
    final bool isDesktop = DeviceUtils.isDesktop ||
        DeviceUtils.isWeb ||
        DeviceUtils.isTablet(context);

    return Opacity(
      opacity: 0.9,
      child: Container(
        margin: isDesktop ? EdgeInsets.zero : const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDesktop
              ? [] // No shadow for desktop
              : [
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
            // 标题栏
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24, // Slightly larger for desktop
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    post.title, // 使用 post
                    style: TextStyle(
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 作者信息栏
            _buildAuthorRow(context, isDesktop),
            const SizedBox(height: 20),

            // 标签栏
            if (post.tags.isNotEmpty)
              PostTags(
                post: post,
                isMini: !isDesktop,
                onTagTap: onTagTap,
              ),
            if (post.tags.isNotEmpty) const SizedBox(height: 20),
            // 内容栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDesktop ? Colors.grey[50] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: isDesktop ? Border.all(color: Colors.grey[200]!) : null,
              ),
              child: Text(
                post.content, // 使用 post
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 15,
                  height: 1.8,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // 添加交互按钮
            const SizedBox(height: 16),
            PostInteractionButtons(
              postService: postService,
              userActions: userActions, // 使用 userActions
              post: post, // 使用 post
              currentUser: currentUser,
              onPostUpdated: onPostUpdated, // 使用 onPostUpdated
            ),

            // Post statistics
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.remove_red_eye,
                        size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.viewCount}', // 使用 post
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${post.replyCount}', // 使用 post
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context, bool isDesktop) {
    final userId = post.authorId; // 使用 post

    return Row(
      children: [
        // 使用UserInfoBadge替换原有的用户信息显示
        Expanded(
          child: UserInfoBadge(
            currentUser: currentUser, // 使用 currentUser
            infoProvider: infoProvider,
            followService: followService,
            targetUserId: userId,
            showFollowButton: false,
            mini: !isDesktop,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),
        // 楼主标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withSafeOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '楼主',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 发布时间
        Text(
          DateTimeFormatter.formatRelative(post.createTime), // 使用 post
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
