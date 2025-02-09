// lib/widgets/forum/post_content.dart
import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../services/user_service.dart';
import '../../screens/profile/open_profile_screen.dart';

class PostContent extends StatelessWidget {
  final Post post;
  final UserService _userService = UserService();

  PostContent({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildAuthorRow(context),
          const SizedBox(height: 16),
          Text(post.content),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userService.getUserInfoById(post.authorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final userInfo = snapshot.data!;
        final avatarUrl = userInfo['avatar'];
        final username = userInfo['username'];

        return Row(
          children: [
            MouseRegion(  // 添加 MouseRegion
              cursor: SystemMouseCursors.click, // 设置指针样式
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OpenProfileScreen(userId: post.authorId),
                  ),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null ? Text(username[0].toUpperCase()) : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(username),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '楼主',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ),
            const Spacer(),
            Text(post.createTime.toString().substring(0, 16)),
          ],
        );
      },
    );
  }
}