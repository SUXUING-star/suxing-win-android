// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/loading_route_observer.dart';

class ForumScreen extends StatefulWidget {
  final String? tag;

  const ForumScreen({Key? key, this.tag}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  final UserService _userService = UserService();
  final List<String> _tags = ['全部', '讨论', '攻略', '分享', '求助'];
  String _selectedTag = '全部';
  List<Post>? _posts;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _selectedTag = widget.tag!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _loadPosts().then((_) {
        loadingObserver.hideLoading();
      });
    });
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _forumService.getPosts(
        tag: _selectedTag == '全部' ? null : _selectedTag,
      ).first;

      setState(() {
        _posts = posts;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _posts = [];
      });
    }
  }

  Future<void> _refreshData() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      await _loadPosts();
    } finally {
      loadingObserver.hideLoading();
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
                  _loadPosts();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList() {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_posts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts!.isEmpty) {
      return const Center(child: Text('暂无帖子'));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts!.length,
        itemBuilder: (context, index) {
          final post = _posts![index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.postDetail, arguments: post.id);
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
                  FutureBuilder<String?>(
                    future: _userService.getAvatarFromId(post.authorId),
                    builder: (context, snapshot) {
                      return CircleAvatar(
                        radius: 12,
                        backgroundImage: snapshot.data != null
                            ? NetworkImage(snapshot.data!)
                            : null,
                        child: snapshot.data == null
                            ? Text(post.authorName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12))
                            : null,
                      );
                    },
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