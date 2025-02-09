// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/loading_route_observer.dart';
import '../../screens/profile/open_profile_screen.dart';

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
          Navigator.pushNamed(
              context, AppRoutes.postDetail, arguments: post.id);
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
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: post.tags.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 左侧用户信息
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: _userService.getUserInfoById(post.authorId),
                        builder: (context, snapshot) {
                          final username = snapshot.data?['username'] ?? '';
                          final avatarUrl = snapshot.data?['avatar'];

                          return MouseRegion(  // 使用 MouseRegion
                            cursor: SystemMouseCursors.click, // 设置鼠标指针样式为点击样式
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OpenProfileScreen(userId: post.authorId),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundImage: avatarUrl != null ? NetworkImage(
                                    avatarUrl) : null,
                                child: avatarUrl == null && username.isNotEmpty
                                    ? Text(username[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 12))
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _userService.getUserInfoById(post.authorId),
                        builder: (context, snapshot) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 120),
                            child: Text(
                              snapshot.data?['username'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 右侧浏览和评论数
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 16,
                          color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        post.viewCount.toString(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 16,
                          color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        post.replyCount.toString(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}