// lib/screens/forum/forum_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post/post.dart';
import '../../services/main/forum/forum_service.dart';
import '../../services/main/user/user_service.dart';
import '../../providers/auth/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/load/loading_route_observer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/components/screen/forum/post_card.dart';
import '../../widgets/components/screen/forum/tag_filter.dart';

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

  // 定义桌面端断点
  final double _desktopBreakpoint = 900.0;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    return Scaffold(
      appBar: CustomAppBar(
        title: '论坛',
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn) {
                return IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
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
          TagFilter(
            tags: _tags,
            selectedTag: _selectedTag,
            onTagSelected: (tag) {
              setState(() {
                _selectedTag = tag;
              });
              _loadPosts();
            },
          ),
          Expanded(
            child: _buildPostsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(bool isDesktop) {
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
      child: isDesktop
          ? _buildDesktopPostsGrid()
          : _buildMobilePostsList(),
    );
  }

  // 移动端帖子列表（垂直排列）
  Widget _buildMobilePostsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        return PostCard(
          post: post,
          userService: _userService,
          isDesktopLayout: false,
        );
      },
    );
  }

  // 桌面端帖子网格（并排排列）
  Widget _buildDesktopPostsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 每行2个
        childAspectRatio: 2.5, // 宽高比
        crossAxisSpacing: 16, // 水平间距
        mainAxisSpacing: 16, // 垂直间距
      ),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        return PostCard(
          post: post,
          userService: _userService,
          isDesktopLayout: true,
        );
      },
    );
  }
}