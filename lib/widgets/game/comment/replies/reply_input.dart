// lib/widgets/game/comment/reply_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth/auth_provider.dart';
import '../../../../services/comment_service.dart';

class ReplyInput extends StatefulWidget {
  final String gameId;
  final String parentId;

  const ReplyInput({Key? key, required this.gameId, required this.parentId}) : super(key: key);

  @override
  State<ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<ReplyInput> {
  final TextEditingController _controller = TextEditingController();
  final CommentService _commentService = CommentService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '回复评论...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              if (_controller.text.trim().isEmpty) return;

              try {
                await _commentService.addComment(
                  widget.gameId,
                  _controller.text.trim(),
                  parentId: widget.parentId,
                );
                _controller.clear();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('回复评论失败：$e')),
                );
              }
            },
            child: const Text('回复'),
          ),
        ],
      ),
    );
  }
}