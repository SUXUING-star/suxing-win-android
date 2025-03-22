import 'package:flutter/material.dart';
import '../../../../../models/post/post.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../services/main/forum/forum_service.dart';
import '../../../badge/info/user_info_badge.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool isDesktopLayout;
  final VoidCallback? onDeleted;

  const PostCard({
    Key? key,
    required this.post,
    this.isDesktopLayout = false,
    this.onDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAndroidPortrait = DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Very small screens like older phones

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
        onTap: () async {
          // 使用 await 等待导航结果
          final result = await Navigator.pushNamed(
              context,
              AppRoutes.postDetail,
              arguments: post.id
          );

          // 如果返回的结果是 true，表示帖子有更新（编辑或删除），触发回调
          if (result == true && onDeleted != null) {
            onDeleted!();
          }
        },
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题和操作菜单
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isAndroidPortrait ? 14 : 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 添加弹出菜单
                  _buildPopupMenu(context),
                ],
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

              // 底部行 - 使用 Row 避免内容溢出
              _buildBottomRow(context, isAndroidPortrait, isSmallScreen),

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

  // 添加弹出菜单
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
      onSelected: (value) => _handleMenuItemSelected(context, value),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('编辑'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('删除', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  // 处理菜单项选择
  void _handleMenuItemSelected(BuildContext context, String value) async {
    if (value == 'edit') {
      // 导航到编辑页面
      final result = await Navigator.pushNamed(
          context,
          AppRoutes.editPost,
          arguments: post.id
      );

      // 如果编辑成功，触发回调
      if (result == true && onDeleted != null) {
        onDeleted!();
      }
    } else if (value == 'delete') {
      // 显示删除确认对话框
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('确认删除'),
          content: Text('确定要删除此帖子吗？此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      // 如果确认删除
      if (confirm == true) {
        try {
          // 显示加载指示器
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text("正在删除..."),
                  ],
                ),
              );
            },
          );

          // 执行删除操作
          final forumService = ForumService();
          await forumService.deletePost(post.id.toString());

          // 关闭加载对话框
          Navigator.pop(context);

          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('帖子已删除')),
          );

          // 触发删除回调
          if (onDeleted != null) {
            onDeleted!();
          }
        } catch (e) {
          // 关闭加载对话框
          Navigator.pop(context);

          // 显示错误消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  // 优化底部行布局，防止溢出
  Widget _buildBottomRow(BuildContext context, bool isAndroidPortrait, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 使用 UserInfoBadge 组件替代自定义的用户头像和名称
        Flexible(
          child: UserInfoBadge(
            userId: post.authorId,
            showFollowButton: false,
            mini: true,
            showLevel: false,
          ),
        ),

        // 统计信息
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem(
              context,
              Icons.remove_red_eye_outlined,
              post.viewCount.toString(),
              isAndroidPortrait,
              isSmallScreen,
            ),
            SizedBox(width: isSmallScreen ? 4 : 8),
            _buildStatItem(
              context,
              Icons.chat_bubble_outline,
              post.replyCount.toString(),
              isAndroidPortrait,
              isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }

  // 优化统计项，减小尺寸以适应小屏幕
  Widget _buildStatItem(BuildContext context, IconData icon, String count, bool isAndroidPortrait, bool isSmallScreen) {
    final iconSize = isSmallScreen ? 12.0 : (isAndroidPortrait ? 14.0 : 16.0);
    final fontSize = isSmallScreen ? 10.0 : (isAndroidPortrait ? 12.0 : 14.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Colors.grey[600],
        ),
        SizedBox(width: isSmallScreen ? 2 : 4),
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

  // 标签行 - 优化布局避免溢出
  Widget _buildTagsRow(BuildContext context, bool isAndroidPortrait) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        children: post.tags.map((tag) {
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2, // 减小垂直间距
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