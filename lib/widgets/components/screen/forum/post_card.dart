import 'package:flutter/material.dart';
import '../../../../models/post/post.dart';
import '../../../../routes/app_routes.dart';
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
    return Card(
      margin: EdgeInsets.zero,
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
          padding: const EdgeInsets.all(16),
          child: isDesktopLayout
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
      ),
    );
  }

  // 移动端布局（纵向排列）
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        _buildTitleRow(context),
        const SizedBox(height: 12),

        // 内容预览
        _buildContentPreview(context),
        const SizedBox(height: 16),

        // 标签行
        if (post.tags.isNotEmpty) ...[
          _buildTagsRow(context),
          const SizedBox(height: 16),
        ],

        // 底部信息行
        _buildBottomInfoRow(context),
      ],
    );
  }

  // 桌面端布局（更紧凑）
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        _buildTitleRow(context),
        const SizedBox(height: 8),

        // 内容预览（在桌面布局中只显示一行）
        _buildContentPreview(context, maxLines: 1),
        const SizedBox(height: 8),

        // 底部行（标签和统计信息并排显示）
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 左侧：用户信息
              Expanded(
                flex: 3,
                child: _buildUserInfo(context),
              ),

              // 中间：标签（水平滚动）
              if (post.tags.isNotEmpty)
                Expanded(
                  flex: 4,
                  child: _buildTagsRow(context, maxWidth: 150),
                ),

              // 右侧：统计信息
              Expanded(
                flex: 2,
                child: _buildStats(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 标题行
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        if (post.status == PostStatus.locked)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '已锁定',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Text(
            post.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: isDesktopLayout ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 内容预览
  Widget _buildContentPreview(BuildContext context, {int maxLines = 2}) {
    return Text(
      post.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.grey[600],
        height: 1.5,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  // 标签行
  Widget _buildTagsRow(BuildContext context, {double? maxWidth}) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: SingleChildScrollView(
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
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 底部信息行
  Widget _buildBottomInfoRow(BuildContext context) {
    return Row(
      children: [
        // 用户信息
        _buildUserInfo(context),
        const Spacer(),

        // 统计信息
        _buildStats(context),
      ],
    );
  }

  // 用户信息
  Widget _buildUserInfo(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: userService.getUserInfoById(post.authorId),
      builder: (context, snapshot) {
        final username = snapshot.data?['username'] ?? '';
        final avatarUrl = snapshot.data?['avatar'];

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OpenProfileScreen(
                    userId: post.authorId,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: isDesktopLayout ? 12 : 16,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null && username.isNotEmpty
                      ? Text(
                    username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: isDesktopLayout ? 10 : 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktopLayout ? 80 : 120),
                  child: Text(
                    username,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: isDesktopLayout ? 12 : 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 统计信息
  Widget _buildStats(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildStatItem(
          context,
          Icons.remove_red_eye_outlined,
          post.viewCount.toString(),
        ),
        SizedBox(width: isDesktopLayout ? 8 : 16),
        _buildStatItem(
          context,
          Icons.chat_bubble_outline,
          post.replyCount.toString(),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String count) {
    final iconSize = isDesktopLayout ? 14.0 : 16.0;
    final fontSize = isDesktopLayout ? 12.0 : 14.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
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
}