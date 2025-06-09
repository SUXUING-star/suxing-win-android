/// 该文件定义了 BasePostCard 组件，一个用于展示论坛帖子预览的卡片。
/// BasePostCard 展示帖子标题、标签、用户信息、统计数据，并提供操作菜单。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 导入用户信息 Provider
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
  final UserInfoProvider infoProvider; // 用户信息提供者
  final double screenWidth;
  final Future<void> Function(Post post)? onDeleteAction; // 删除操作回调
  final void Function(Post post)? onEditAction; // 编辑操作回调
  final Future<void> Function(String postId)? onToggleLockAction; // 切换锁定状态回调
  final bool showPinnedStatus; // 是否显示帖子的置顶状态高亮

  static const double thresholdWidth = 280.0; // 宽度阈值
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
  const BasePostCard({
    super.key,
    required this.currentUser,
    required this.post,
    required this.followService,
    required this.infoProvider,
    required this.screenWidth,
    this.onDeleteAction,
    this.onEditAction,
    this.onToggleLockAction,
    this.showPinnedStatus = false,
  });

  /// 构建帖子卡片。
  ///
  /// 该方法根据帖子数据和用户权限构建卡片 UI。
  @override
  Widget build(BuildContext context) {
    final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
    final isAndroidLayout = !isDesktopLayout;

    final String? currentUserId = currentUser?.id; // 当前用户ID
    final bool isAdmin = currentUser?.isAdmin ?? false; // 是否管理员
    final bool canPotentiallyModify =
        (post.authorId.toString() == currentUserId) || isAdmin; // 判断用户是否有权修改此帖子

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), // 卡片外部间距
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // 卡片背景色
        borderRadius: BorderRadius.circular(12), // 圆角
        boxShadow: [
          // 阴影
          BoxShadow(
            color: Colors.grey.withSafeOpacity(0.2), // 阴影颜色
            spreadRadius: 1, // 扩散半径
            blurRadius: 3, // 模糊半径
            offset: const Offset(0, 2), // 阴影偏移
          ),
        ],
      ),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12), // InkWell 圆角
            onTap: () async {
              // 点击卡片导航到详情页
              await Navigator.pushNamed(
                context,
                AppRoutes.postDetail, // 导航到帖子详情路由
                arguments: post.id, // 传递帖子 ID
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
              children: [
                Stack(
                  children: [
                    // 标题区域，其 Padding 决定了 Stack 的基础尺寸和为标签预留的空间
                    Padding(
                      // 底部 padding 增大，为 Positioned 的标签行腾出空间
                      padding: EdgeInsets.fromLTRB(
                          40, 12, 12, post.tags.isNotEmpty ? _tagRowHeight : 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // 垂直顶部对齐
                        children: [
                          Expanded(
                            child: Text(
                              post.title, // 帖子标题
                              style: TextStyle(
                                fontWeight: FontWeight.w600, // 字体粗细
                                fontSize: isAndroidLayout ? 14 : 16, // 字体大小
                              ),
                              maxLines: 2, // 最大行数
                              overflow: TextOverflow.ellipsis, // 溢出显示省略号
                            ),
                          ),
                          _buildPopupMenu(context, canPotentiallyModify,
                              isAdmin, currentUserId), // 操作菜单
                        ],
                      ),
                    ),

                    // 标签行，使用 Positioned 定位，脱离布局流
                    if (post.tags.isNotEmpty)
                      Positioned(
                        bottom: 4, // 距离底部一点距离
                        left: 12,
                        right: 12,
                        child: PostTagRow(
                          tags: post.tags, // 标签列表
                          isAndroidPortrait: isAndroidLayout, // 是否为 Android 竖屏
                        ),
                      ),
                  ],
                ),

                // 底部信息栏：作者和统计数据
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // 内边距
                  decoration: BoxDecoration(
                    color: Colors.grey[50], // 背景色
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12), // 底部圆角
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!, // 顶部边框颜色
                        width: 1, // 顶部边框宽度
                      ),
                    ),
                  ),
                  child: screenWidth >= thresholdWidth
                      ?
                      // 宽度大于阈值时使用 Row 布局
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween, // 主轴两端对齐
                          children: [
                            Expanded(
                              child: UserInfoBadge(
                                targetUserId: post.authorId.toString(), // 用户ID
                                infoProvider: infoProvider, // 用户信息提供者
                                followService: followService, // 关注服务
                                showFollowButton: false, // 不显示关注按钮
                                currentUser: currentUser, // 当前用户
                                mini: true, // 迷你模式
                                showLevel: false, // 不显示等级
                              ),
                            ),
                            const SizedBox(width: 8), // 间距
                            PostStatisticsRow(
                              replyCount: post.replyCount, // 回复数量
                              likeCount: post.likeCount, // 点赞数量
                              favoriteCount: post.favoriteCount, // 收藏数量
                              isSmallScreen: screenWidth < 320, // 是否为小屏幕
                            ),
                          ],
                        )
                      :
                      // 宽度小于阈值时使用 Column 布局
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // 水平左对齐
                          children: [
                            UserInfoBadge(
                              targetUserId: post.authorId.toString(), // 用户ID
                              followService: followService, // 关注服务
                              infoProvider: infoProvider, // 用户信息提供者
                              showFollowButton: false, // 不显示关注按钮
                              currentUser: currentUser, // 当前用户
                              mini: true, // 迷你模式
                              showLevel: false, // 不显示等级
                            ),
                            const SizedBox(height: 6), // 间距
                            Align(
                              alignment: Alignment.centerRight, // 居右对齐
                              child: PostStatisticsRow(
                                replyCount: post.replyCount, // 回复数量
                                likeCount: post.likeCount, // 点赞数量
                                favoriteCount: post.favoriteCount, // 收藏数量
                                isSmallScreen: true, // 是否为小屏幕
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (showPinnedStatus && post.isPinned) // 条件性显示置顶图标 overlay
            Positioned(
              top: 0, // 顶部对齐
              left: 0, // 左侧对齐
              child: Container(
                padding: const EdgeInsets.all(4), // 内边距
                decoration: BoxDecoration(
                    color: Colors.blue.shade400, // 背景色
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12), // 右上角圆角
                      bottomLeft: Radius.circular(8), // 左下角圆角
                    ),
                    boxShadow: [
                      // 阴影
                      BoxShadow(
                        color: Colors.black.withSafeOpacity(0.2), // 阴影颜色
                        blurRadius: 3, // 模糊半径
                        offset: const Offset(-2, 2), // 偏移
                      ),
                    ]),
                child: const Icon(
                  Icons.push_pin, // 置顶图标
                  size: 18, // 图标大小
                  color: Colors.white, // 颜色
                ),
              ),
            ),
        ],
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
          await callback(post.id.toString()); // 执行切换锁定回调
        } catch (e) {
          // 错误处理
        }
      }
    }
  }
}
