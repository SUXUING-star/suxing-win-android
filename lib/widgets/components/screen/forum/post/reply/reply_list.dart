import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../services/main/user/user_service.dart';
import '../../../../../../services/main/forum/forum_service.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import 'reply_item.dart';
import 'empty_replies.dart';

class ReplyList extends StatefulWidget {
  final String postId;

  const ReplyList({Key? key, required this.postId}) : super(key: key);

  @override
  _ReplyListState createState() => _ReplyListState();
}

class _ReplyListState extends State<ReplyList> {
  final ForumService _forumService = ForumService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Reply>>(
      stream: _forumService.getReplies(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('加载失败：${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final replies = snapshot.data!;

        return Container(

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 全部回复标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  '全部回复',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),

              // 回复列表或无回复时的占位符
              Expanded(
                child: replies.isEmpty
                    ? const EmptyReplies()
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: replies.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) => ReplyItem(
                    reply: replies[index],
                    floor: index + 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}