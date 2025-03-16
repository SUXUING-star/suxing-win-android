// lib/widgets/game/comment/comments_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './comments/comment_input.dart';
import './comments/comment_list.dart';
import '../../../../../../providers/auth/auth_provider.dart';

class CommentsSection extends StatefulWidget {
  final String gameId;
  final VoidCallback? onCommentAdded; // 添加评论回调

  const CommentsSection({
    Key? key,
    required this.gameId,
    this.onCommentAdded, // 初始化回调
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  // 用于在添加评论后强制刷新评论列表
  final ValueNotifier<DateTime> _refreshTrigger = ValueNotifier(DateTime.now());

  void _handleCommentChanged() {
    // 更新时间触发器通知评论列表刷新
    _refreshTrigger.value = DateTime.now();

    // 同时通知父组件有评论变化
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
    // 获取用户登录状态
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

            // 根据登录状态决定显示什么内容
            authProvider.isLoggedIn
                ? Column(
              children: [
                // 传递评论添加回调
                CommentInput(
                  gameId: widget.gameId,
                  onCommentAdded: _handleCommentChanged,
                ),
                // 使用 ValueListenableBuilder 监听刷新触发器
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
                : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '登录后查看和发表评论',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('登录'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}