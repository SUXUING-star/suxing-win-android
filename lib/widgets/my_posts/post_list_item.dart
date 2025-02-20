// lib/widgets/my_posts/post_list_item.dart
import 'package:flutter/material.dart';
import '../../models/post/post.dart';
import '../../routes/app_routes.dart';

class PostListItem extends StatelessWidget {
  final Post post;
  final VoidCallback onMoreTap;

  const PostListItem({
    Key? key,
    required this.post,
    required this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.remove_red_eye, size: 16),
                SizedBox(width: 4),
                Text('${post.viewCount}'),
                SizedBox(width: 16),
                Icon(Icons.comment, size: 16),
                SizedBox(width: 4),
                Text('${post.replyCount}'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: onMoreTap,
        ),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.postDetail,
          arguments: post.id,
        ),
      ),
    );
  }
}