// lib/widgets/game/comments_section.dart
import 'package:flutter/material.dart';
import './comment/comment_input.dart';
import './comment/comment_list.dart';

class CommentsSection extends StatelessWidget {
  final String gameId;

  const CommentsSection({Key? key, required this.gameId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '评论区',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        CommentInput(gameId: gameId),
        CommentList(gameId: gameId),
      ],
    );
  }
}