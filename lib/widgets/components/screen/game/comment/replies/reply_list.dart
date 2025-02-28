// lib/widgets/game/comment/replies/reply_list.dart
import 'package:flutter/material.dart';
import '../../../../../../models/comment/comment.dart';
import 'reply_item.dart';

class ReplyList extends StatelessWidget {
  final List<Comment> replies;
  final VoidCallback? onReplyChanged; // 添加回调函数

  const ReplyList({
    Key? key,
    required this.replies,
    this.onReplyChanged, // 初始化回调
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: replies.length,
      itemBuilder: (context, index) => ReplyItem(
        reply: replies[index],
        onReplyChanged: onReplyChanged, // 传递回调
      ),
    );
  }
}