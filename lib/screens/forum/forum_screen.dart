// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/forum_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';

class ForumScreen extends StatefulWidget {
  final String? tag;

  const ForumScreen({Key? key, this.tag}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  final List<String> _tags = ['全部', '讨论', '攻略', '分享', '求助'];
  String _selectedTag = '全部';

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _selectedTag = widget.tag!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('论坛'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.createPost);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTagFilter(),
          Expanded(
            child: _buildPostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _tags.length,
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final isSelected = tag == _selectedTag;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTag = tag);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<List<Post>>(
      stream: _forumService.getPosts(
        tag: _selectedTag == '全部' ? null : _selectedTag,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorMessage(message: '加载失败: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const LoadingIndicator();
        }

        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return const Center(child: Text('暂无帖子'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(post);
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.postDetail,
            arguments: post.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (post.status == PostStatus.locked)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.lock, size: 16, color: Colors.grey),
                    ),
                  Expanded(
                    child: Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: post.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(
                      post.authorName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(post.authorName),
                  const Spacer(),
                  Icon(Icons.remove_red_eye, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(post.viewCount.toString()),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(post.replyCount.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}