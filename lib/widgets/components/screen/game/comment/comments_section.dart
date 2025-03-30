// lib/widgets/game/comment/comments_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './comments/comment_input.dart';
import './comments/comment_list.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../widgets/ui/buttons/login_prompt.dart'; // Import the new component

class CommentsSection extends StatefulWidget {
  final String gameId;
  final VoidCallback? onCommentAdded;

  const CommentsSection({
    Key? key,
    required this.gameId,
    this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final ValueNotifier<DateTime> _refreshTrigger = ValueNotifier(DateTime.now());

  void _handleCommentChanged() {
    _refreshTrigger.value = DateTime.now();

    if (widget.onCommentAdded != null) {
      widget.onCommentAdded!();
    }
  }

  @override
  void dispose() {
    _refreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Opacity(
      opacity: 0.9,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '评论区',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 使用新的LoginPrompt组件代替原来的登录提示UI
            authProvider.isLoggedIn
                ? Column(
              children: [
                CommentInput(
                  gameId: widget.gameId,
                  onCommentAdded: _handleCommentChanged,
                ),
                ValueListenableBuilder<DateTime>(
                    valueListenable: _refreshTrigger,
                    builder: (context, dateTime, child) {
                      return CommentList(
                        gameId: widget.gameId,
                        refreshTrigger: dateTime,
                      );
                    }
                ),
              ],
            )
                : LoginPrompt(
              message: '登录后查看和发表评论',
              buttonText: '登录',
              // 可以自定义导航行为，这里使用默认的
            ),
          ],
        ),
      ),
    );
  }
}