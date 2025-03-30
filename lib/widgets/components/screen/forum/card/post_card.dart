// post_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/buttons/custom_popup_menu_button.dart';
import '../../../../../models/post/post.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../services/main/forum/forum_service.dart';
import '../../../../ui/badges/user_info_badge.dart';
import 'post_statistics_row.dart';
import 'post_tag_row.dart';
import '../../../../ui/dialogs/confirm_dialog.dart'; // 确保路径正确

class PostCard extends StatelessWidget {
  final Post post;
  final bool isDesktopLayout;
  final VoidCallback? onDeleted; // 用于删除成功后通知列表刷新

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
    final isSmallScreen = screenWidth < 360;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // 跳转到详情页的逻辑保持不变
          final result = await Navigator.pushNamed(
              context,
              AppRoutes.postDetail,
              arguments: post.id
          );

          // 如果从详情页返回时带有删除标记，则触发回调
          // （注意：这里的 result==true 可能需要根据详情页的实现调整）
          if (result == true && onDeleted != null) {
            onDeleted!();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title area
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left title
                  Expanded(
                    child: Text(
                      post.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isAndroidPortrait ? 14 : 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Right operation menu - 保持不变
                  _buildPopupMenu(context),
                ],
              ),
            ),

            // Content preview - 保持不变
            if (post.content.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  post.content,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: isAndroidPortrait ? 12 : 14,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Tags row (if available) - 保持不变
            if (post.tags.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: PostTagRow(
                  tags: post.tags,
                  isAndroidPortrait: isAndroidPortrait,
                ),
              ),

            // Bottom interaction info bar - 保持不变
// PostCard.dart -> build 方法 -> 底部的 Container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              // 使用 LayoutBuilder 来获取可用宽度
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 定义一个阈值，低于这个宽度就切换布局
                  // 这个值需要根据你的 UserInfoBadge 和 PostStatisticsRow
                  // 并排时看起来舒适的最小宽度来调整。可以从 250-300 左右开始尝试。
                  const double thresholdWidth = 280.0;

                  // 判断可用宽度是否足够并排显示
                  if (constraints.maxWidth >= thresholdWidth) {
                    // --- 宽度足够：保持原来的 Row 布局 ---
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // User info (保持 Expanded)
                        Expanded(
                          child: UserInfoBadge(
                            userId: post.authorId,
                            showFollowButton: false,
                            mini: true,
                            showLevel: false,
                          ),
                        ),
                        // Interaction statistics (直接放置)
                        PostStatisticsRow(
                          replyCount: post.replyCount,
                          likeCount: post.likeCount,
                          favoriteCount: post.favoriteCount,
                          isSmallScreen: isSmallScreen, // 这个isSmallScreen可以考虑废弃或基于constraints
                        ),
                      ],
                    );
                  } else {
                    // --- 宽度不足：切换为 Column 布局 (或者其他紧凑布局) ---
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 内容靠左对齐
                      children: [
                        // User info (占据一行)
                        UserInfoBadge(
                          userId: post.authorId,
                          showFollowButton: false,
                          mini: true,
                          showLevel: false,
                        ),
                        // 添加一点垂直间距
                        SizedBox(height: 6),
                        // Interaction statistics (占据下一行，可以考虑让它靠右)
                        Align( // 使用 Align 控制统计信息的水平位置
                          alignment: Alignment.centerRight,
                          child: PostStatisticsRow(
                            replyCount: post.replyCount,
                            likeCount: post.likeCount,
                            favoriteCount: post.favoriteCount,
                            isSmallScreen: true, // 窄模式下强制使用 smallScreen 样式
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Popup menu - 保持不变
  Widget _buildPopupMenu(BuildContext context) {
    // 使用新的 CustomPopupMenuButton
    return CustomPopupMenuButton<String>(
      // --- 自定义外观 ---
      icon: Icons.more_horiz,   // 尝试用水平的点点点
      iconSize: 18,             // 图标小一点
      iconColor: Colors.grey[700], // 图标颜色深一点
      padding: const EdgeInsets.all(4.0), // 减少按钮的内边距，使其更紧凑
      tooltip: '帖子选项',        // 添加提示文本
      elevation: 5,              // 菜单阴影大一点
      splashRadius: 18,          // 控制点击效果范围
      // shape: RoundedRectangleBorder( ... ), // 可以自定义菜单形状
      // menuBackgroundColor: Colors.white, // 可以自定义菜单背景色

      // --- 核心逻辑 ---
      onSelected: (value) => _handleMenuItemSelected(context, value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // 编辑选项
        PopupMenuItem<String>(
          value: 'edit',
          height: 40, // 可以调整菜单项高度
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Colors.blue[700]), // 使用 outlined 图标
              const SizedBox(width: 10),
              const Text('编辑'),
            ],
          ),
        ),
        // 分隔线
        const PopupMenuDivider(height: 1),
        // 删除选项
        PopupMenuItem<String>(
          value: 'delete',
          height: 40, // 可以调整菜单项高度
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red[700]), // 使用 outlined 图标
              const SizedBox(width: 10),
              Text('删除', style: TextStyle(color: Colors.red[700])), // 文本颜色也调整
            ],
          ),
        ),
      ],
    );
  }


  // Handle menu item selection - **修改此方法**
  void _handleMenuItemSelected(BuildContext context, String value) async {
    if (value == 'edit') {
      // 编辑逻辑保持不变
      final result = await Navigator.pushNamed(
          context,
          AppRoutes.editPost,
          arguments: post.id
      );
      // 如果编辑成功，触发回调（可能需要改为 onEdited 回调？）
      // 注意：目前用的是 onDeleted，可能需要调整
      if (result == true && onDeleted != null) {
        onDeleted!();
      }
    } else if (value == 'delete') {
      // 使用 ConfirmDialog 替换 AlertDialog
      try {
        await CustomConfirmDialog.show(
          context: context,
          title: '确认删除',
          message: '确定要删除此帖子【${post.title}】吗？此操作无法撤销。', // 可以在消息中包含帖子标题
          confirmButtonText: '删除',
          confirmButtonColor: Colors.red, // 保持删除按钮为红色
          cancelButtonText: '取消',
          // 将删除逻辑放入 onConfirm 回调
          onConfirm: () async {
            // ConfirmDialog 内部会处理按钮的 loading 状态，无需额外显示加载框
            final forumService = ForumService();
            await forumService.deletePost(post.id.toString());

            // 删除成功后的操作
            // 检查 context 是否仍然有效 (mounted)
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('帖子已删除')),
            );

            // 触发外部传入的删除回调
            onDeleted?.call(); // 使用 ?.call() 更安全
          },
        );
        // 如果 ConfirmDialog.show 成功执行且 onConfirm 没有抛出异常，则流程正常结束
      } catch (e) {
        // 捕获 onConfirm 中（即 forumService.deletePost）抛出的异常
        // 检查 context 是否仍然有效
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }
}