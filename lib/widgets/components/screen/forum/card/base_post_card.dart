/// 该文件定义了 BasePostCard 组件，一个用于展示论坛帖子预览的卡片。
/// BasePostCard 展示帖子标题、标签、用户信息、统计数据，并提供操作菜单。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 导入用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 导入用户关注服务
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart'; // 导入自定义弹出菜单按钮

import 'package:suxingchahui/models/post/post.dart'; // 导入帖子模型
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 导入用户信息徽章
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

import 'post_statistics_row.dart'; // 导入帖子统计行组件
import 'post_tag_row.dart'; // 导入帖子标签行组件

/// `BasePostCard` 类：论坛帖子卡片组件。
///
/// 该组件展示单个帖子的预览信息，并提供导航到详情页、编辑和删除等操作入口。
class BasePostCard extends StatelessWidget {
  final Post post; // 要展示的帖子数据模型
  final User? currentUser; // 当前登录用户
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息提供者
  final double availableWidth;
  final Future<void> Function(Post post)? onDeleteAction; // 删除操作回调
  final void Function(Post post)? onEditAction; // 编辑操作回调
  final Future<void> Function(Post post)? onToggleLockAction; // 切换锁定状态回调
  final bool showPinnedStatus; // 是否显示帖子的置顶状态高亮

  final int? contentMaxLines;
  static const double thresholdWidth = 400.0; // 宽度阈值
  // 为标签行预留的固定高度，确保布局稳定
  static const double _tagRowHeight = 28.0;

  /// 构造函数。
  ///
  /// [currentUser]：当前用户。
  /// [post]：帖子数据。
  /// [followService]：关注服务。
  /// [infoProvider]：用户信息 Provider。
  /// [isDesktopLayout]：是否桌面布局。
  /// [onDeleteAction]：删除回调。
  /// [onEditAction]：编辑回调。
  /// [onToggleLockAction]：切换锁定回调。
  /// [showPinnedStatus]：是否显示置顶状态。
  ///  [contentMaxLines] : 显示内容的行数.
  const BasePostCard({
    super.key,
    required this.currentUser,
    required this.post,
    required this.followService,
    required this.infoService,
    required this.availableWidth,
    this.onDeleteAction,
    this.onEditAction,
    this.onToggleLockAction,
    this.showPinnedStatus = false,
    this.contentMaxLines = 2,
  });

  /// 构建帖子卡片。
  ///
  /// 该方法根据帖子数据和用户权限构建卡片 UI。
  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = DeviceUtils.isDesktopScreen(context);
    final isAndroidLayout = !isDesktopLayout;

    final String? currentUserId = currentUser?.id;
    final bool isAdmin = currentUser?.isAdmin ?? false;
    final bool canPotentiallyModify =
        (post.authorId.toString() == currentUserId) || isAdmin;

    final bool showContent = contentMaxLines != null &&
        contentMaxLines! > 0 &&
        post.content.isNotEmpty;

    // 估算底部信息栏的高度，为内容区域留出足够的 padding
    // 窄屏下是 Column，高一些；宽屏下是 Row，矮一些。取一个最大安全值。
    const double footerHeight = 64.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withSafeOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.postDetail,
              arguments: post.id,
            );
          },
          // 使用 Stack 布局，这是最稳妥的解决方案
          child: Stack(
            children: [
              // 主要内容区域（标题 + 内容）
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部：标题和标签
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(40, 12, 12,
                            post.tags.isNotEmpty ? _tagRowHeight : 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                post.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isAndroidLayout ? 14 : 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (post.tags.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          left: 12,
                          right: 12,
                          child: PostTagsRow(
                            tags: post.tags,
                            isAndroidPortrait: isAndroidLayout,
                          ),
                        ),
                    ],
                  ),
                  // 内容区域
                  if (showContent)
                    Padding(
                      // 底部留出空间，防止被 footer 覆盖
                      padding:
                          const EdgeInsets.fromLTRB(12, 8, 12, footerHeight),
                      child: Text(
                        post.content,
                        maxLines: contentMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isAndroidLayout ? 13 : 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),

              // 底部信息栏，使用 Positioned 将其钉在底部
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: availableWidth >= thresholdWidth
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: UserInfoBadge(
                                targetUserId: post.authorId.toString(),
                                infoService: infoService,
                                followService: followService,
                                showFollowButton: false,
                                currentUser: currentUser,
                                mini: true,
                                showLevel: false,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PostStatisticsRow(
                              replyCount: post.replyCount,
                              likeCount: post.likeCount,
                              favoriteCount: post.favoriteCount,
                              isSmallScreen: availableWidth < 320,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserInfoBadge(
                              targetUserId: post.authorId.toString(),
                              followService: followService,
                              infoService: infoService,
                              showFollowButton: false,
                              currentUser: currentUser,
                              mini: true,
                              showLevel: false,
                            ),
                            const SizedBox(height: 6),
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
                        ),
                ),
              ),

              // 操作菜单，放在顶层，避免被 InkWell 覆盖点击
              Positioned(
                top: 4,
                right: 2,
                child: _buildPopupMenu(
                    context, canPotentiallyModify, isAdmin, currentUserId),
              ),

              // 置顶图标
              if (showPinnedStatus && post.isPinned)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withSafeOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(-2, 2),
                          ),
                        ]),
                    child: const Icon(
                      Icons.push_pin,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建帖子操作弹出菜单。
  ///
  /// [context]：Build 上下文。
  /// [canPotentiallyModify]：是否拥有潜在修改权限。
  /// [isAdmin]：是否管理员。
  /// [currentUserId]：当前用户ID。
  /// 返回一个包含编辑、删除、锁定/解锁等操作的弹出菜单。
  Widget _buildPopupMenu(BuildContext context, bool canPotentiallyModify,
      bool isAdmin, String? currentUserId) {
    final bool canModifyContent =
        (post.authorId.toString() == currentUserId); // 是否可修改内容
    final bool showEditDeletePermission =
        canModifyContent || isAdmin; // 是否显示编辑删除权限
    final bool showLockUnlockPermission = isAdmin; // 是否显示锁定解锁权限

    final bool canShowEdit =
        showEditDeletePermission && onEditAction != null; // 是否可显示编辑
    final bool canShowDelete =
        showEditDeletePermission && onDeleteAction != null; // 是否可显示删除
    final bool canShowLock =
        showLockUnlockPermission && onToggleLockAction != null; // 是否可显示锁定

    if (!canShowEdit && !canShowDelete && !canShowLock) {
      // 无可用操作时返回空组件
      return const SizedBox.shrink();
    }

    return StylishPopupMenuButton<String>(
      icon: Icons.more_horiz, // 图标
      iconSize: 20, // 大小
      iconColor: Colors.grey[600], // 颜色
      menuColor: Colors.white, // 菜单背景色
      tooltip: '帖子选项', // 提示
      onSelected: (value) => _handleMenuItemSelected(context, value), // 选中回调
      items: [
        if (canShowEdit) // 显示编辑选项
          StylishMenuItemData(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary), // 图标
                const SizedBox(width: 10), // 间距
                const Text('编辑'), // 文本
              ],
            ),
          ),
        if (canShowDelete) // 显示删除选项
          StylishMenuItemData(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline,
                    size: 18, color: Colors.red[700]), // 图标
                const SizedBox(width: 10), // 间距
                Text('删除', style: TextStyle(color: Colors.red[700])), // 文本
              ],
            ),
          ),
        if (canShowLock) // 显示锁定/解锁选项
          StylishMenuItemData(
            value: 'toggle_lock',
            child: Row(
              children: [
                Icon(
                  post.status == PostStatus.locked
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline, // 图标
                  size: 18, // 大小
                  color: post.status == PostStatus.locked
                      ? Colors.green[700]
                      : Colors.orange[800], // 颜色
                ),
                const SizedBox(width: 10), // 间距
                Text(post.status == PostStatus.locked ? '解锁' : '锁定'), // 文本
              ],
            ),
          ),
      ],
    );
  }

  /// 处理菜单项选择。
  ///
  /// [context]：Build 上下文。
  /// [value]：选中项的值。
  /// 根据选中项的值调用相应的操作回调。
  void _handleMenuItemSelected(BuildContext context, String value) async {
    if (value == 'edit') {
      if (onEditAction != null) {
        onEditAction!(post); // 执行编辑回调
      }
    } else if (value == 'delete') {
      final callback = onDeleteAction;
      if (callback != null) {
        try {
          await callback(post); // 执行删除回调
        } catch (e) {
          // 错误处理
        }
      }
    } else if (value == 'toggle_lock') {
      final callback = onToggleLockAction;
      if (callback != null) {
        try {
          await callback(post); // 执行切换锁定回调
        } catch (e) {
          // 错误处理
        }
      }
    }
  }
}
