import 'package:flutter/material.dart';
import '../../../../models/post/post.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/device/device_utils.dart';
import '../../../common/image/safe_user_avatar.dart';
import '../../../../screens/profile/open_profile_screen.dart';
import '../../../../services/main/user/user_service.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final UserService userService;
  final bool isDesktopLayout;

  const PostCard({
    Key? key,
    required this.post,
    required this.userService,
    this.isDesktopLayout = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAndroidPortrait = DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.postDetail, arguments: post.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                post.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isAndroidPortrait ? 14 : 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // 内容预览 (只有当内容不为空时才显示)
              if (post.content.trim().isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  post.content,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isAndroidPortrait ? 12 : 14,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: 8),

              // 底部行
              Row(
                children: [
                  // 用户头像
                  _buildUserAvatar(context, isAndroidPortrait),

                  // 统计信息
                  Spacer(),
                  _buildStatItem(
                    context,
                    Icons.remove_red_eye_outlined,
                    post.viewCount.toString(),
                    isAndroidPortrait,
                  ),
                  SizedBox(width: 8),
                  _buildStatItem(
                    context,
                    Icons.chat_bubble_outline,
                    post.replyCount.toString(),
                    isAndroidPortrait,
                  ),
                ],
              ),

              // 标签 (如果有)
              if (post.tags.isNotEmpty) ...[
                SizedBox(height: 8),
                _buildTagsRow(context, isAndroidPortrait),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 用户头像 - 使用安全头像组件
  Widget _buildUserAvatar(BuildContext context, bool isAndroidPortrait) {
    return FutureBuilder<Map<String, dynamic>>(
      future: userService.getUserInfoById(post.authorId),
      builder: (context, snapshot) {
        final username = snapshot.data?['username'] ?? '';
        final avatarUrl = snapshot.data?['avatar'];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeUserAvatar(
              userId: post.authorId,
              avatarUrl: avatarUrl,
              username: username,
              radius: isAndroidPortrait ? 12 : 14,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              enableNavigation: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OpenProfileScreen(userId: post.authorId),
                ),
              ),
            ),
            SizedBox(width: 6),
            Text(
              username,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isAndroidPortrait ? 12 : 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String count, bool isAndroidPortrait) {
    final iconSize = isAndroidPortrait ? 14.0 : 16.0;
    final fontSize = isAndroidPortrait ? 12.0 : 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Colors.grey[600],
        ),
        SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }

  // 标签行
  Widget _buildTagsRow(BuildContext context, bool isAndroidPortrait) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: post.tags.map((tag) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: isAndroidPortrait ? 10 : 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}