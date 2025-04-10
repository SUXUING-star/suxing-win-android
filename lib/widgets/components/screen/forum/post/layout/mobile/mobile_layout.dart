import 'package:flutter/material.dart';
import '../../../../../../../models/post/post.dart';
import '../../post_content.dart';
import '../../reply/reply_list.dart';

class MobileLayout extends StatelessWidget {
  final Post post;
  final String postId;
  // 添加交互成功回调
  final VoidCallback? onInteractionSuccess;

  const MobileLayout({
    Key? key,
    required this.post,
    required this.postId,
    this.onInteractionSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 修复滚动问题，使用 ListView 替代 Column
    return ListView(
      children: [
        // 帖子内容 - 传递交互成功回调
        PostContent(
          post: post,
          onInteractionSuccess: onInteractionSuccess,
        ),
        const Divider(height: 1),
        // 帖子回复 - 使用固定高度，避免无限高度问题
        Container(
          height: MediaQuery.of(context).size.height -
              kToolbarHeight -
              MediaQuery.of(context).padding.top -
              80, // 估计的回复输入框高度
          child: ReplyList(postId: postId),
        ),
      ],
    );
  }
}