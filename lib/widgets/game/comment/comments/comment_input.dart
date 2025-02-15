// lib/widgets/game/comment/comment_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../services/comment_service.dart';
import '../../../../providers/auth/auth_provider.dart';
import '../../../common/toaster.dart';

class CommentInput extends StatefulWidget {
  final String gameId;

  const CommentInput({Key? key, required this.gameId}) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
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

    if (!authProvider.isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: const Text('登录后发表评论'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '发表评论...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () async {
              if (_controller.text.trim().isEmpty) return;

              try {
                await _commentService.addComment(widget.gameId, _controller.text.trim());
                Toaster.success(context, "成功发表评论");
                _controller.clear();
              } catch (e) {
                Toaster.error(context, "成功发表评论");
              }
            },
            child: const Text('发表'),
          ),
        ],
      ),
    );
  }
}