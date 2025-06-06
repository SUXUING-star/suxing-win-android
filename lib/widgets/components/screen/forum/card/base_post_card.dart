// lib/widgets/components/screen/forum/card/base_post_card.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';

import 'package:suxingchahui/models/post/post.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

import 'post_statistics_row.dart'; // 帖子统计行
import 'post_tag_row.dart'; // 帖子标签行

/// 论坛帖子卡片 Widget
///
/// 负责展示单个帖子的预览信息，并提供导航到详情页、编辑和删除的操作入口（通过回调）。
class BasePostCard extends StatelessWidget {
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

  /// 是否显示帖子的置顶状态高亮。
  final bool showPinnedStatus; // 添加这一行

  const BasePostCard({
    super.key,
    required this.currentUser,
    required this.post,
    required this.followService,
    required this.infoProvider,
    this.isDesktopLayout = false,
    this.onDeleteAction,
    this.onEditAction,
    this.onToggleLockAction,
    this.showPinnedStatus = false, // 添加这一行，设置默认值不显示
  });

  @override
  Widget build(BuildContext context) {
    // 获取设备信息
    final isAndroidPortrait =
        DeviceUtils.isAndroid && DeviceUtils.isPortrait(context);

    // 获取权限信息
    final currentUserId = currentUser?.id;
    final isAdmin = currentUser?.isAdmin ?? false;
    // 判断用户是否有权修改此帖子
    final canPotentiallyModify =
        (post.authorId.toString() == currentUserId) || isAdmin;

    // 使用 Container 实现卡片样式和 Stack 叠加置顶图标
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), // 卡片外部间距
      decoration: BoxDecoration(
        // Card 的视觉效果
        color: Theme.of(context).cardColor, // 使用主题卡片背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [
          // 模拟 Card 阴影
          BoxShadow(
            color: Colors.grey.withSafeOpacity(0.2), // 阴影颜色
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2), // 阴影偏移
          ),
        ],
      ),
      // Stack 叠加卡片内容和置顶图标
      child: Stack(
        children: [
          // 主要内容
          InkWell(
            borderRadius: BorderRadius.circular(12), // InkWell 圆角
            // 点击卡片导航到详情页
            onTap: () async {
              await Navigator.pushNamed(
                // 导航到详情页
                context,
                AppRoutes.postDetail,
                arguments: post.id, // 传递帖子 ID
              );

              // 处理从详情页返回的结果
              if (!context.mounted) return;
              // Result is handled by the calling widget, not here
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 12, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 帖子标题
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
                      // 操作菜单
                      _buildPopupMenu(context, canPotentiallyModify, isAdmin,
                          currentUserId),
                    ],
                  ),
                ),

                // 标签行
                if (post.tags.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 8), // 内部 padding
                    child: PostTagRow(
                      tags: post.tags,
                      isAndroidPortrait: isAndroidPortrait,
                    ),
                  ),

                // 底部信息栏
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // 内部 padding
                  decoration: BoxDecoration(
                    // 底部区域背景和圆角
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    border: Border(
                      // 顶部分割线
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double thresholdWidth = 280.0;

                      if (constraints.maxWidth >= thresholdWidth) {
                        // Row 布局
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 用户信息徽章
                            Expanded(
                              child: UserInfoBadge(
                                targetUserId:
                                    post.authorId.toString(), // 传递字符串 ID
                                infoProvider: infoProvider,
                                followService: followService,
                                showFollowButton: false,
                                currentUser: currentUser,
                                mini: true,
                                showLevel: false,
                              ),
                            ),
                            const SizedBox(width: 8), // 间距
                            // 帖子统计数据
                            PostStatisticsRow(
                              replyCount: post.replyCount,
                              likeCount: post.likeCount,
                              favoriteCount: post.favoriteCount,
                              isSmallScreen: constraints.maxWidth < 320,
                            ),
                          ],
                        );
                      } else {
                        // Column 布局
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
                            const SizedBox(height: 6), // 间距
                            // 帖子统计数据
                            Align(
                              alignment: Alignment.centerRight,
                              child: PostStatisticsRow(
                                replyCount: post.replyCount,
                                likeCount: post.likeCount,
                                favoriteCount: post.favoriteCount,
                                isSmallScreen: true,
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
          // 条件性显示的置顶图标 overlay
          if (showPinnedStatus && post.isPinned)
            Positioned(
              // 定位在右上角
              top: 0,
              left: 0,
              child: Container(
                // 包裹图标，加背景圆角阴影
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.blue.shade400, // 置顶图标背景色
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12), // 右上角圆角
                      bottomLeft: Radius.circular(8), // 左下角圆角
                    ),
                    boxShadow: [
                      // 图标阴影
                      BoxShadow(
                        color: Colors.black.withSafeOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(-2, 2),
                      ),
                    ]),
                child: const Icon(
                  Icons.push_pin, // 置顶图标
                  size: 18, // 图标大小
                  color: Colors.white, // 图标颜色
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建帖子操作弹出菜单。
  /// 检查回调是否为 null。
  Widget _buildPopupMenu(BuildContext context, bool canPotentiallyModify,
      bool isAdmin, String? currentUserId) {
    // 权限细节
    final bool canModifyContent = (post.authorId.toString() == currentUserId);
    final bool showEditDeletePermission =
        canModifyContent || isAdmin; // 管理员也能删改
    final bool showLockUnlockPermission = isAdmin; // 只有管理员能锁定

    // 检查操作是否可用
    final bool canShowEdit = showEditDeletePermission && onEditAction != null;
    final bool canShowDelete =
        showEditDeletePermission && onDeleteAction != null;
    final bool canShowLock =
        showLockUnlockPermission && onToggleLockAction != null;

    // 没有可用操作不显示菜单
    if (!canShowEdit && !canShowDelete && !canShowLock) {
      return const SizedBox.shrink();
    }

    // 构建按钮
    return StylishPopupMenuButton<String>(
      icon: Icons.more_horiz,
      iconSize: 20,
      iconColor: Colors.grey[600],
      menuColor: Colors.white,
      tooltip: '帖子选项',
      onSelected: (value) => _handleMenuItemSelected(context, value),
      items: [
        // 编辑选项
        if (canShowEdit)
          StylishMenuItemData(
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
        // 删除选项
        if (canShowDelete)
          StylishMenuItemData(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.red[700]),
                const SizedBox(width: 10),
                Text('删除', style: TextStyle(color: Colors.red[700])),
              ],
            ),
          ),

        // 锁定/解锁选项
        if (canShowLock)
          StylishMenuItemData(
            value: 'toggle_lock',
            child: Row(
              children: [
                Icon(
                  post.status == PostStatus.locked
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                  size: 18,
                  color: post.status == PostStatus.locked
                      ? Colors.green[700]
                      : Colors.orange[800],
                ),
                const SizedBox(width: 10),
                Text(post.status == PostStatus.locked ? '解锁' : '锁定'),
              ],
            ),
          ),
      ],
    );
  }

  /// 处理菜单项选择。
  /// 调用回调前检查 null。
  void _handleMenuItemSelected(BuildContext context, String value) async {
    if (value == 'edit') {
      if (onEditAction != null) {
        onEditAction!(post);
      }
    } else if (value == 'delete') {
      final callback = onDeleteAction;
      if (callback != null) {
        try {
          await callback(post);
        } catch (e) {
          // 处理错误
        }
      }
    } else if (value == 'toggle_lock') {
      final callback = onToggleLockAction;
      if (callback != null) {
        try {
          await callback(post.id.toString());
          // 操作成功后，父组件需要刷新列表或更新状态
        } catch (e) {
          // 处理错误
          if (context.mounted) {
            // 显示错误 Snackbar
          }
        }
      }
    }
  }
}
