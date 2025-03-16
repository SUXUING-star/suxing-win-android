import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../models/post/post.dart';
import '../../../../../../providers/auth/auth_provider.dart';
import '../../../../../../utils/font/font_config.dart';

class MobileReplyInput extends StatelessWidget {
  final Post? post;
  final TextEditingController replyController;
  final Function(BuildContext) onSubmitReply;

  const MobileReplyInput({
    Key? key,
    required this.post,
    required this.replyController,
    required this.onSubmitReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isLoggedIn) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text(
                '登录后回复',
                style: TextStyle(fontFamily: FontConfig.defaultFontFamily, fontFamilyFallback: FontConfig.fontFallback),
              ),
            ),
          );
        }

        if (post?.status == PostStatus.locked) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: const Text('该帖子已被锁定，无法回复'),
          );
        }

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyController,
                      decoration: const InputDecoration(
                        hintText: '写下你的回复...',
                        border: InputBorder.none,
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => onSubmitReply(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}