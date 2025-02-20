// lib/widgets/game/comment/reply_list.dart
import 'package:flutter/material.dart';
import '../../../../models/comment/comment.dart';
import 'reply_item.dart';

class ReplyList extends StatelessWidget {
  final List<Comment> replies;
  const ReplyList({Key? key, required this.replies}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: replies.length,
      itemBuilder: (context, index) => ReplyItem(reply: replies[index]),
    );
  }
}