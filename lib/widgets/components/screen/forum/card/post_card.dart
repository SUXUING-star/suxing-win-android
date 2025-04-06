// 文件路径: lib/widgets/components/screen/forum/card/post_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 用于获取 AuthProvider

import '../../../../../models/post/post.dart';
import '../../../../../providers/auth/auth_provider.dart'; // 用于获取当前用户信息和权限
import '../../../../../routes/app_routes.dart';
import '../../../../../utils/device/device_utils.dart';
import '../../../../../utils/navigation/navigation_utils.dart'; // 用于导航
import '../../../../ui/badges/user_info_badge.dart'; // 用户信息徽章
import '../../../../ui/buttons/custom_popup_menu_button.dart'; // 自定义弹出菜单按钮
// 注意：不再需要导入 ForumService 或 ConfirmDialog (如果确认逻辑移到父级)

import 'post_statistics_row.dart'; // 帖子统计行
import 'post_tag_row.dart'; // 帖子标签行

/// 论坛帖子卡片 Widget
///
/// 负责展示单个帖子的预览信息，并提供导航到详情页、编辑和删除的操作入口（通过回调）。
class PostCard extends StatelessWidget {
  /// 要展示的帖子数据模型。
  final Post post;

  /// 是否采用桌面布局样式。
  final bool isDesktopLayout;

  /// 当用户触发删除操作时调用的回调函数。
  /// 父组件应在此回调中处理确认对话框和实际的删除逻辑。
  /// 参数为要删除的帖子的 ID。
  final Future<void> Function(String postId) onDeleteAction;

  /// 当用户触发编辑操作时调用的回调函数。
  /// 父组件应在此回调中处理导航到编辑页面等逻辑。
  /// 参数为要编辑的帖子对象。
  final void Function(Post post) onEditAction;

  const PostCard({
    Key? key,
    required this.post,
    this.isDesktopLayout = false,
    required this.onDeleteAction, // 强制要求传入删除回调
    required this.onEditAction,   // 强制要求传入编辑回调
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取设备和屏幕信息，用于调整布局
    final isAndroidPortrait = DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // final isSmallScreen = screenWidth < 360; // 这个判断条件可以根据 LayoutBuilder 调整

    // 获取认证信息以判断用户权限
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final isAdmin = authProvider.currentUser?.isAdmin ?? false;
    // 判断当前用户是否有权修改此帖子（作者本人或管理员）
    // 注意：确保比较的是字符串 ID
    final canModify = (post.authorId.toString() == currentUserId) || isAdmin;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // --- 点击卡片导航到详情页 ---
        onTap: () async {
          print("PostCard onTap: Navigating to post detail for ${post.id}");
          final result = await NavigationUtils.pushNamed(
            context,
            AppRoutes.postDetail,
            arguments: post.id, // 传递帖子 ID
          );
          print("PostCard onTap: Returned from post detail with result: $result");

          // --- 处理从详情页返回的结果 ---
          if (!context.mounted) return; // 检查 context 是否仍然有效

          if (result is Map) {
            if (result['deleted'] == true) {
              print("PostCard onTap: Detail page indicated deletion. Parent should handle refresh via its own logic or onDeleteAction if necessary.");
              // ForumScreen 的 _navigateToPostDetail 应该已经处理了删除后的刷新
              // 这里通常不需要再调用 onDeleteAction，避免重复操作或逻辑冲突
              // 如果确实需要在 ForumScreen._navigateToPostDetail 之外也处理，可以取消注释下一行
              // await onDeleteAction(post.id.toString());
            } else if (result['updated'] == true) {
              print("PostCard onTap: Detail page indicated update. Parent should handle refresh via its own logic or onEditAction if necessary.");
              // ForumScreen 的 _navigateToPostDetail 应该已经处理了编辑后的刷新
              // 这里通常不需要再调用 onEditAction
              // 如果确实需要，可以取消注释下一行
              // onEditAction(post);
            }
          } else if (result == true) {
            // 处理来自 PostDetailScreen dispose 的通用交互信号 (比如回复后返回)
            print("PostCard onTap: Detail page returned generic interaction (true). Assuming ForumScreen._navigateToPostDetail handles refresh.");
            // 通用交互通常也由 ForumScreen 的 _navigateToPostDetail 刷新逻辑覆盖
            // 如果需要特定处理，可以在这里添加或依赖父级
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 标题区域 ---
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 帖子标题（靠左）
                  Expanded(
                    child: Text(
                      post.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isAndroidPortrait ? 14 : 16, // 适应不同设备
                      ),
                      maxLines: 2, // 最多显示两行
                      overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                    ),
                  ),
                  // 操作菜单（靠右，仅在有权限时显示）
                  if (canModify) _buildPopupMenu(context),
                ],
              ),
            ),


            // --- 标签行（如果标签不为空） ---
            if (post.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: PostTagRow(
                  tags: post.tags,
                  isAndroidPortrait: isAndroidPortrait,
                ),
              ),

            // --- 底部信息栏（作者信息和统计数据） ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50], // 浅灰色背景
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12), // 底部圆角
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!, // 顶部细分割线
                    width: 1,
                  ),
                ),
              ),
              // 使用 LayoutBuilder 动态调整布局
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 定义宽度阈值，用于切换 Row/Column 布局
                  const double thresholdWidth = 280.0; // 可根据实际效果调整

                  if (constraints.maxWidth >= thresholdWidth) {
                    // 宽度足够，使用 Row 布局
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 用户信息徽章（允许扩展）
                        Expanded(
                          child: UserInfoBadge(
                            userId: post.authorId.toString(), // 确保传递字符串 ID
                            showFollowButton: false,
                            mini: true,
                            showLevel: false,
                          ),
                        ),
                        const SizedBox(width: 8), // 添加一些间距
                        // 帖子统计数据
                        PostStatisticsRow(
                          replyCount: post.replyCount,
                          likeCount: post.likeCount,
                          favoriteCount: post.favoriteCount,
                          isSmallScreen: constraints.maxWidth < 320, // 基于实际宽度判断是否为小屏幕样式
                        ),
                      ],
                    );
                  } else {
                    // 宽度不足，使用 Column 布局
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 用户信息徽章
                        UserInfoBadge(
                          userId: post.authorId.toString(),
                          showFollowButton: false,
                          mini: true,
                          showLevel: false,
                        ),
                        const SizedBox(height: 6),
                        // 帖子统计数据（靠右对齐）
                        Align(
                          alignment: Alignment.centerRight,
                          child: PostStatisticsRow(
                            replyCount: post.replyCount,
                            likeCount: post.likeCount,
                            favoriteCount: post.favoriteCount,
                            isSmallScreen: true, // 窄模式强制使用小屏幕样式
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

  /// 构建帖子操作的弹出菜单（仅在有权限时调用）。
  Widget _buildPopupMenu(BuildContext context) {
    return CustomPopupMenuButton<String>(
      icon: Icons.more_horiz, // 水平三点图标
      iconSize: 20, // 图标大小
      iconColor: Colors.grey[600], // 图标颜色
      padding: const EdgeInsets.all(4.0), // 按钮内边距
      tooltip: '帖子选项', // 提示文本
      splashRadius: 18, // 点击效果半径
      // 当菜单项被选择时调用
      onSelected: (value) => _handleMenuItemSelected(context, value),
      // 构建菜单项
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // 编辑选项
        PopupMenuItem<String>(
          value: 'edit',
          height: 40, // 菜单项高度
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              const Text('编辑'),
            ],
          ),
        ),
        // 分割线
        const PopupMenuDivider(height: 1),
        // 删除选项
        PopupMenuItem<String>(
          value: 'delete',
          height: 40,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
              const SizedBox(width: 10),
              Text('删除', style: TextStyle(color: Colors.red[700])),
            ],
          ),
        ),
      ],
    );
  }

  /// 处理弹出菜单项的选择事件。
  /// 此方法现在只调用父组件传递的回调函数。
  void _handleMenuItemSelected(BuildContext context, String value) async {
    if (value == 'edit') {
      // --- 用户点击编辑 ---
      print("PostCard: Edit option selected for post ${post.id}. Calling onEditAction.");
      // 调用父组件传入的编辑回调，将 post 对象传递出去
      onEditAction(post);
    } else if (value == 'delete') {
      // --- 用户点击删除 ---
      print("PostCard: Delete option selected for post ${post.id}. Calling onDeleteAction.");
      // 调用父组件传入的删除回调，将 postId 传递出去
      // 父组件 (ForumScreen) 会负责弹出确认对话框和执行实际删除
      // 注意：这里是异步调用，但 PostCard 不关心其结果，父组件处理
      try {
        await onDeleteAction(post.id.toString());
        print("PostCard: onDeleteAction call initiated for post ${post.id}.");
      } catch (e) {
        // 一般来说，父组件的回调应该自己处理异常，这里只是以防万一
        print("PostCard: Error occurred during onDeleteAction call: $e");
        // 不建议在这里显示 SnackBar，因为父组件应该已经处理或正在处理
      }
    }
  }
}