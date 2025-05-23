// 文件路径: lib/widgets/components/screen/forum/card/post_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';

import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 用于导航
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章

import 'post_statistics_row.dart'; // 帖子统计行
import 'post_tag_row.dart'; // 帖子标签行

/// 论坛帖子卡片 Widget
///
/// 负责展示单个帖子的预览信息，并提供导航到详情页、编辑和删除的操作入口（通过回调）。
class PostCard extends StatelessWidget {
  /// 要展示的帖子数据模型。
  final Post post;

  final User? currentUser;

  final UserFollowService followService;

  final UserInfoProvider infoProvider;

  /// 是否采用桌面布局样式。
  final bool isDesktopLayout;

  /// 当用户触发删除操作时调用的回调函数 (可选)。
  /// 父组件应在此回调中处理确认对话框和实际的删除逻辑。
  /// 参数为要删除的帖子的 ID。
  final Future<void> Function(Post post)? onDeleteAction;

  /// 当用户触发编辑操作时调用的回调函数 (可选)。
  /// 父组件应在此回调中处理导航到编辑页面等逻辑。
  /// 参数为要编辑的帖子对象。
  final void Function(Post post)? onEditAction;

  /// 当用户触发锁定/解锁操作时调用的回调函数 (可选)。
  /// 父组件应在此回调中处理实际的锁定/解锁逻辑。
  /// 参数为要操作的帖子的 ID。
  final Future<void> Function(String postId)? onToggleLockAction;

  const PostCard({
    super.key,
    required this.currentUser,
    required this.post,
    required this.followService,
    required this.infoProvider,
    this.isDesktopLayout = false,
    this.onDeleteAction, // 已设为可选
    this.onEditAction, // 已设为可选
    this.onToggleLockAction, // 已设为可选
  });

  @override
  Widget build(BuildContext context) {
    // 获取设备和屏幕信息，用于调整布局
    final isAndroidPortrait =
        DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);

    // 获取认证信息以判断用户权限
    final currentUserId = currentUser?.id;
    final isAdmin = currentUser?.isAdmin ?? false;
    // 判断当前用户是否有权修改此帖子（作者本人或管理员） - 用于显示菜单按钮
    // 注意：确保比较的是字符串 ID
    final canPotentiallyModify =
        (post.authorId.toString() == currentUserId) || isAdmin;

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
          final result = await NavigationUtils.pushNamed(
            context,
            AppRoutes.postDetail,
            arguments: post.id, // 传递帖子 ID
          );

          // --- 处理从详情页返回的结果 ---
          if (!context.mounted) return; // 检查 context 是否仍然有效

          // 这里的逻辑保持不变，依赖父组件通过 _navigateToPostDetail 处理刷新
          if (result is Map) {
            if (result['deleted'] == true) {
              //print(
              //    "PostCard onTap: Detail page indicated deletion. Parent should handle refresh via its own logic.");
            } else if (result['updated'] == true) {
              //print(
              //    "PostCard onTap: Detail page indicated update. Parent should handle refresh via its own logic.");
            } //
          } else if (result == true) {
            //print(
            //    "PostCard onTap: Detail page returned generic interaction (true). Assuming ForumScreen._navigateToPostDetail handles refresh.");
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
                  // 操作菜单（靠右，仅在有权限且有对应回调时显示部分或全部选项）
                  _buildPopupMenu(context, canPotentiallyModify, isAdmin,
                      currentUserId), // 传递权限信息
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
                            targetUserId:
                                post.authorId.toString(), // 确保传递字符串 ID
                            infoProvider: infoProvider,
                            followService: followService,
                            showFollowButton: false,
                            currentUser: currentUser,
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
                          isSmallScreen:
                              constraints.maxWidth < 320, // 基于实际宽度判断是否为小屏幕样式
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
                          targetUserId: post.authorId.toString(),
                          followService: followService,
                          infoProvider: infoProvider,
                          showFollowButton: false,
                          currentUser: currentUser,
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

  /// 构建帖子操作的弹出菜单。
  /// 现在会检查回调是否为 null 来决定是否显示对应菜单项。
  Widget _buildPopupMenu(BuildContext context, bool canPotentiallyModify,
      bool isAdmin, String? currentUserId) {
    // 再次确认权限细节
    final bool canModifyContent = (post.authorId.toString() == currentUserId);
    final bool showEditDeletePermission =
        canModifyContent || isAdmin; // 管理员也能删改
    final bool showLockUnlockPermission = isAdmin; // 只有管理员能锁定

    // --- 检查每个操作是否 *实际可用* (有权限 + 有回调) ---
    final bool canShowEdit = showEditDeletePermission && onEditAction != null;
    final bool canShowDelete =
        showEditDeletePermission && onDeleteAction != null;
    final bool canShowLock =
        showLockUnlockPermission && onToggleLockAction != null;

    // 如果没有任何可用的操作，则不显示菜单按钮
    if (!canShowEdit && !canShowDelete && !canShowLock) {
      return const SizedBox.shrink();
    }

    // 确保在有任何一个可用操作时才构建按钮
    return StylishPopupMenuButton<String>(
      // T is String here
      icon: Icons.more_horiz,
      iconSize: 20,
      iconColor: Colors.grey[600],
      menuColor: Colors.white,

      tooltip: '帖子选项',
      onSelected: (value) => _handleMenuItemSelected(context, value),
      items: [
        // 直接使用 List literal，类型是 List<StylishMenuItemData<String>>
        // 编辑选项 (作者或管理员，并且 onEditAction 可用)
        if (canShowEdit)
          StylishMenuItemData(
            // value is 'edit' (String)
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Text('编辑'),
              ],
            ),
          ),
        // 删除选项 (作者或管理员，并且 onDeleteAction 可用)
        if (canShowDelete)
          StylishMenuItemData(
            // value is 'delete' (String)
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
                const SizedBox(width: 10),
                Text('删除', style: TextStyle(color: Colors.red[700])),
              ],
            ),
          ),

        // --- 锁定/解锁选项 (仅管理员，并且 onToggleLockAction 可用) ---
        if (canShowLock)
          StylishMenuItemData(
            // value is 'toggle_lock' (String)
            value: 'toggle_lock',
            child: Row(
              children: [
                Icon(
                  post.status == PostStatus.locked
                      ? Icons.lock_open_outlined // 解锁图标
                      : Icons.lock_outline, // 锁定图标
                  size: 18,
                  color: post.status == PostStatus.locked
                      ? Colors.green[700] // 解锁颜色
                      : Colors.orange[800], // 锁定颜色
                ),
                const SizedBox(width: 10),
                Text(
                    post.status == PostStatus.locked ? '解锁' : '锁定'), // 根据状态切换文本
              ],
            ),
          ),
        // **** 下面这行删掉 ****
        // ].where((item) => item != null).cast<PopupMenuEntry<String>>().toList(),
      ], // **** 直接结束 List literal ****
    );
  }

  /// 处理弹出菜单项的选择事件。
  /// 现在会在调用回调前检查其是否为 null。
  void _handleMenuItemSelected(BuildContext context, String value) async {
    if (value == 'edit') {
      // 使用空安全调用 ?.call()
      if (onEditAction != null) {
        onEditAction!(post); // 明确知道非空后可以加 !，或者直接用 onEditAction(post)
      } else {
        // print("PostCard: Edit option selected, but onEditAction is null.");
      }
    } else if (value == 'delete') {
      final callback = onDeleteAction; // 存储到局部变量以便检查
      if (callback != null) {
        try {
          await callback(post);
        } catch (e) {
          //
        }
      } else {
        // print("PostCard: Delete option selected, but onDeleteAction is null.");
      }
    } else if (value == 'toggle_lock') {
      final callback = onToggleLockAction; // 存储到局部变量以便检查
      if (callback != null) {
        try {
          await callback(post.id.toString());
          // 可以在这里或者父组件中提示成功
        } catch (e) {
          // print("PostCard: Error occurred during onToggleLockAction call: $e");
          // 可以在这里显示错误提示，或者让父组件处理
          if (context.mounted) {}
        }
      } else {}
    }
  }
}
