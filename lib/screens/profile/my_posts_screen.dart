// lib/screens/profile/my_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/my_posts/my_posts_bloc.dart';
import '../../blocs/my_posts/my_posts_event.dart';
import '../../blocs/my_posts/my_posts_state.dart';
import '../../services/forum_service.dart';
import '../../services/user_service.dart';
import '../../widgets/my_posts/post_list_item.dart';
import '../../widgets/my_posts/post_actions_bottom_sheet.dart';
import '../../routes/app_routes.dart';
import '../../utils/loading_route_observer.dart';

class MyPostsScreen extends StatefulWidget {
  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late MyPostsBloc _myPostsBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _myPostsBloc = MyPostsBloc(
      context.read<ForumService>(),
      context.read<UserService>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      loadingObserver.showLoading();

      _myPostsBloc.add(LoadMyPostsEvent());

      // 延迟隐藏加载动画
      Future.delayed(Duration(seconds: 1), () {
        loadingObserver.hideLoading();
      });
    });
  }

  @override
  void dispose() {
    _myPostsBloc.close();
    super.dispose();
  }

  Future<void> _refreshPosts() async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      _myPostsBloc.add(LoadMyPostsEvent());
    } finally {
      // 延迟隐藏加载动画
      Future.delayed(Duration(seconds: 1), () {
        loadingObserver.hideLoading();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _myPostsBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('我的帖子'),
        ),
        body: BlocConsumer<MyPostsBloc, MyPostsState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: _refreshPosts,
              child: _buildContent(context, state),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.createPost),
          child: Icon(Icons.add),
          tooltip: '发布新帖',
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyPostsState state) {
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (state.userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('请先登录'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              child: Text('去登录'),
            ),
          ],
        ),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('暂无发帖'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.posts.length,
      itemBuilder: (context, index) {
        final post = state.posts[index];
        return PostListItem(
          post: post,
          onMoreTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => PostActionsBottomSheet(post: post),
            );
          },
        );
      },
    );
  }
}