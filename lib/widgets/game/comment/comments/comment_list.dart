// lib/widgets/game/comment/comment_list.dart
import 'package:flutter/material.dart';
import '../../../../models/comment/comment.dart';
import '../../../../services/comment_service.dart';
import 'comment_item.dart'; // Import the CommentItem widget

class CommentList extends StatelessWidget {
  final String gameId;
  final CommentService _commentService = CommentService();

  CommentList({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comment>>(
      stream: _commentService.getGameComments(gameId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载评论失败：${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return const Center(child: Text('暂无评论'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) => CommentItem(comment: comments[index], gameId: gameId,), // Use the CommentItem widget
        );
      },
    );
  }
}