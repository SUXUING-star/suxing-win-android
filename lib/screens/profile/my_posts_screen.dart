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

class MyPostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyPostsBloc(
        context.read<ForumService>(),
        context.read<UserService>(),
      )..add(LoadMyPostsEvent()),
      child: MyPostsView(),
    );
  }
}

class MyPostsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state.userId == null) {
            return Center(child: Text('请先登录'));
          }

          if (state.posts.isEmpty) {
            return Center(child: Text('暂无发帖'));
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createPost),
        child: Icon(Icons.add),
        tooltip: '发布新帖',
      ),
    );
  }
}