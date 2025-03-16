// lib/widgets/components/screen/game/comment/comment_list.dart
import 'package:flutter/material.dart';
import '../../../../../../models/comment/comment.dart';
import '../../../../../../services/main/game/comment/comment_service.dart';
import 'comment_item.dart';

class CommentList extends StatefulWidget {
  final String gameId;
  final DateTime? refreshTrigger; // 可选的刷新触发器

  const CommentList({
    Key? key,
    required this.gameId,
    this.refreshTrigger, // 初始化刷新触发器
  }) : super(key: key);

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  final CommentService _commentService = CommentService();
  // 使用ValueNotifier来强制刷新评论列表
  final ValueNotifier<DateTime> _internalRefreshTrigger = ValueNotifier(DateTime.now());
  late Stream<List<Comment>> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = _commentService.getGameComments(widget.gameId);
  }

  @override
  void didUpdateWidget(CommentList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果refreshTrigger变化，更新内部触发器
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _internalRefreshTrigger.value = DateTime.now();
      // 重新获取评论流
      _commentsStream = _commentService.getGameComments(widget.gameId);
    }
  }

  @override
  void dispose() {
    _internalRefreshTrigger.dispose();
    super.dispose();
  }

  // 处理评论变化的回调
  void _handleCommentChanged() {
    // 更新内部触发器
    _internalRefreshTrigger.value = DateTime.now();
    // 重新获取评论流
    setState(() {
      _commentsStream = _commentService.getGameComments(widget.gameId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
        valueListenable: _internalRefreshTrigger,
        builder: (context, refreshTime, child) {
          return StreamBuilder<List<Comment>>(
            key: ValueKey('comment_list_${refreshTime.millisecondsSinceEpoch}'),
            stream: _commentsStream,
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

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) => CommentItem(
                    comment: comments[index],
                    gameId: widget.gameId,
                    onCommentChanged: _handleCommentChanged, // 添加评论变化回调
                  ),
                ),
              );
            },
          );
        }
    );
  }
}