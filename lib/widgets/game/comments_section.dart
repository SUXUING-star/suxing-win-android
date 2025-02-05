// lib/widgets/comments_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/comment.dart';
import '../../services/comment_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';

class CommentsSection extends StatelessWidget {
  final String gameId;
  final CommentService _commentService = CommentService();
  final UserService _userService = UserService();  // 添加这行

  CommentsSection({Key? key, required this.gameId}) : super(key: key);

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
        _buildCommentInput(context),
        _buildCommentsList(),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    final controller = TextEditingController();
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
              controller: controller,
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
              if (controller.text.trim().isEmpty) return;

              try {
                await _commentService.addComment(gameId, controller.text.trim());
                controller.clear();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('发表评论失败：$e')),
                );
              }
            },
            child: const Text('发表'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
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
          itemBuilder: (context, index) => _buildCommentItem(context, comments[index]),
        );
      },
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _buildUserAvatar(comment.userId, comment.username),
            title: Text(comment.username),
            subtitle: Text(
              _formatDate(comment.createTime) +
                  (comment.isEdited ? ' (已编辑)' : ''),
            ),
            trailing: _buildCommentActions(context, comment),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(comment.content),
          ),
          if (comment.replies.isNotEmpty) ...[
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comment.replies.length,
              itemBuilder: (context, index) => _buildReplyItem(context, comment.replies[index]),
            ),
          ],
          _buildReplyInput(context, comment.id),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String userId, String username) {
    return FutureBuilder<String?>(
      future: _userService.getAvatarFromId(userId),
      builder: (context, snapshot) {
        return CircleAvatar(
          backgroundImage: snapshot.data != null
              ? NetworkImage(snapshot.data!)
              : null,
          child: snapshot.data == null
              ? Text(username[0].toUpperCase())
              : null,
        );
      },
    );
  }


  Widget _buildReplyItem(BuildContext context, Comment reply) {
    return Container(
      margin: const EdgeInsets.only(left: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _buildUserAvatar(reply.userId, reply.username),
            title: Text(reply.username),
            subtitle: Text(
              _formatDate(reply.createTime) +
                  (reply.isEdited ? ' (已编辑)' : ''),
            ),
            trailing: _buildCommentActions(context, reply),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(reply.content),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput(BuildContext context, String parentId) {
    final controller = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '回复评论...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              try {
                await _commentService.addComment(
                  gameId,
                  controller.text.trim(),
                  parentId: parentId,
                );
                controller.clear();
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

  Widget _buildCommentActions(BuildContext context, Comment comment) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            _showEditDialog(context, comment);
            break;
          case 'delete':
            _showDeleteDialog(context, comment);
            break;
        }
      },
      itemBuilder: (context) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!authProvider.isLoggedIn) return [];

        return [
          if (comment.userId == authProvider.currentUser?.id) ...[
            const PopupMenuItem(
              value: 'edit',
              child: Text('编辑'),
            ),
          ],
          if (comment.userId == authProvider.currentUser?.id ||
              authProvider.currentUser?.isAdmin == true) ...[
            const PopupMenuItem(
              value: 'delete',
              child: Text('删除'),
            ),
          ],
        ];
      },
    );
  }

  void _showEditDialog(BuildContext context, Comment comment) {
    final controller = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑评论'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '编辑评论内容...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              try {
                await _commentService.updateComment(
                  comment.id,
                  controller.text.trim(),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('编辑评论失败：$e')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _commentService.deleteComment(comment.id);
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除评论失败：$e')),
                );
              }
            },
            child: const Text('删除'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}