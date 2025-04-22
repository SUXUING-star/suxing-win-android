import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import '../../../../../../models/post/post.dart';
import '../post_content.dart';
import '../reply/reply_list.dart';
import '../community_guidelines.dart';
import '../recent_global_replies.dart';

class PostDetailDesktopLayout extends StatelessWidget {
  final Post post;
  final String postId;
  final Widget replyInput;
  final VoidCallback? onInteractionSuccess;

  const PostDetailDesktopLayout({
    super.key,
    required this.post,
    required this.postId,
    required this.replyInput,
    this.onInteractionSuccess,
  });

  @override
  Widget build(BuildContext context) {
    // 定义动画参数
    const Duration primaryDuration = Duration(milliseconds: 400);
    const Duration secondaryDuration = Duration(milliseconds: 350);
    const Duration baseDelay = Duration(milliseconds: 50);
    const Duration incrementDelay = Duration(milliseconds: 75); // 延迟增量

    int leftDelayIndex = 0;
    int rightDelayIndex = 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 左侧面板带动画 ---
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              // 保持 SingleChildScrollView
              child: Column(
                children: [
                  // PostContent
                  FadeInSlideUpItem(
                    key: ValueKey('post_content_desk_${post.id}'),
                    duration: primaryDuration,
                    delay: baseDelay + (incrementDelay * leftDelayIndex++),
                    child: PostContent(
                      post: post,
                      onInteractionSuccess: onInteractionSuccess,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // CommunityGuidelines
                  FadeInItem(
                    key: ValueKey('guidelines_desk_${post.id}'),
                    duration: secondaryDuration,
                    delay: baseDelay + (incrementDelay * leftDelayIndex++),
                    child: const CommunityGuidelines(useSeparateCard: true),
                  ),
                  const SizedBox(height: 16),
                  // RecentGlobalReplies
                  FadeInItem(
                    key: ValueKey('recent_replies_desk_${post.id}'),
                    duration: secondaryDuration,
                    delay: baseDelay + (incrementDelay * leftDelayIndex++),
                    child: const RecentGlobalReplies(limit: 5),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1), // 分隔线无动画

          // --- 右侧面板带动画 ---
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // Reply Input
                FadeInSlideUpItem(
                  // 输入框也用滑动
                  key: ValueKey('reply_input_desk_${post.id}'),
                  duration: primaryDuration,
                  // 右侧第一个元素稍微延迟一点
                  delay: baseDelay +
                      (incrementDelay * rightDelayIndex++) +
                      incrementDelay,
                  child: replyInput,
                ),
                const SizedBox(height: 16),
                // Reply List
                Expanded(
                  child: FadeInItem(
                    // 回复列表用淡入
                    key: ValueKey('reply_list_desk_${post.id}'),
                    duration: secondaryDuration,
                    delay: baseDelay +
                        (incrementDelay * rightDelayIndex++) +
                        incrementDelay,
                    child: ReplyList(postId: postId),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
