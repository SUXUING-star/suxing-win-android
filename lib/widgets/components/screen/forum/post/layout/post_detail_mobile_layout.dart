import 'package:flutter/material.dart';
import 'package:suxingchahui/models/post/user_post_actions.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import '../../../../../../models/post/post.dart';
import '../post_content.dart';
import '../reply/reply_list.dart';

class PostDetailMobileLayout extends StatelessWidget {
  final Post post;
  final UserPostActions userActions;
  final String postId;
  // 添加交互成功回调
  final Function(Post,UserPostActions) onPostUpdated;

  const PostDetailMobileLayout({
    super.key,
    required this.post,
    required this.userActions,
    required this.postId,
    required this.onPostUpdated,
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
            userActions: userActions,
            post: post,
            onPostUpdated: onPostUpdated,
          ),
        ),
        const Divider(height: 1), // 分隔线无动画

        // --- ReplyList 的容器带动画 ---
        FadeInItem( // 使用纯淡入
          key: ValueKey('reply_list_mob_${post.id}'), // Key
          duration: replyListDuration,
          delay: baseDelay + replyDelay, // 稍后出现
          child: SizedBox(
            // 保持原有高度计算
            height: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top -
                80,
            child: ReplyList(postId: postId),
          ),
        ),
      ],
    );
  }
}