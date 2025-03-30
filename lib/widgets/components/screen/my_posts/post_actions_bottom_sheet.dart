// lib/widgets/my_posts/post_actions_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import '../../../../models/post/post.dart';
import '../../../../routes/app_routes.dart';
import '../../../../screens/profile/myposts/blocs/my_posts_bloc.dart';
import '../../../../screens/profile/myposts/blocs/my_posts_event.dart';

class PostActionsBottomSheet extends StatelessWidget {
  final Post post;

  const PostActionsBottomSheet({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('编辑'),
            onTap: () {
              NavigationUtils.pop(context);
              NavigationUtils.pushNamed(
                context,
                AppRoutes.editPost,
                arguments: post,
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('删除', style: TextStyle(color: Colors.red)),
            onTap: () {
              NavigationUtils.pop(context);
              _showDeleteConfirmDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除帖子'),
        content: Text('确定要删除这个帖子吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => NavigationUtils.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              NavigationUtils.pop(context);
              context.read<MyPostsBloc>().add(DeletePostEvent(post.id));
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}