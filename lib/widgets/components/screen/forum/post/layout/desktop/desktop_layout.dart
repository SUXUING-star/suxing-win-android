import 'package:flutter/material.dart';
import '../../../../../../../models/post/post.dart';
import '../../post_content.dart';
import '../../reply/reply_list.dart';
import '../../community_guidelines.dart';
import '../../recent_global_replies.dart';

class DesktopLayout extends StatelessWidget {
  final Post post;
  final String postId;
  final Widget replyInput;
  // 添加交互成功回调
  final VoidCallback? onInteractionSuccess;

  const DesktopLayout({
    Key? key,
    required this.post,
    required this.postId,
    required this.replyInput,
    this.onInteractionSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧面板 - 帖子内容和社区规则 (40% 宽度)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 将交互回调传递给PostContent
                  PostContent(
                    post: post,
                    onInteractionSuccess: onInteractionSuccess,
                  ),
                  const SizedBox(height: 24),
                  // 社区规则卡片
                  const CommunityGuidelines(useSeparateCard: true),
                  const SizedBox(height: 16),
                  const RecentGlobalReplies(limit: 5),
                ],
              ),
            ),
          ),

          // 面板间的分隔线
          const VerticalDivider(width: 1),

          // 右侧面板 - 回复输入框和回复列表 (60% 宽度)
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // 回复输入框放在顶部
                replyInput,
                const SizedBox(height: 16),
                // 回复列表
                Expanded(
                  child: ReplyList(postId: postId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}