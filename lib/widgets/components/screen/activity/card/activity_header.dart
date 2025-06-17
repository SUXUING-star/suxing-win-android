// lib/widgets/components/screen/activity/card/activity_header.dart

/// 该文件定义了 ActivityHeader 组件，用于显示动态卡片或详情的头部信息。
/// ActivityHeader 负责展示用户信息、活动类型、时间戳和操作菜单。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:suxingchahui/constants/activity/activity_constants.dart'; // 动态类型常量
import 'package:suxingchahui/models/user/user.dart'; // 用户模型
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息 Provider
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件
import 'dart:math' as math; // 数学函数
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 日期时间格式化工具
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart'; // 样式化弹出菜单按钮
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法

/// `ActivityHeader` 类：活动卡片或详情的头部组件。
///
/// 该组件显示活动创建者的信息、活动类型、创建时间、编辑状态和可执行的操作菜单。
class ActivityHeader extends StatelessWidget {
  final String userId; // 活动创建者/所有者的用户 ID
  final User? currentUser; // 当前登录用户
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息 Provider
  final DateTime createTime; // 活动创建时间
  final DateTime? updateTime; // 活动最后更新时间
  final bool isEdited; // 活动是否被编辑过
  final String activityType; // 活动类型字符串
  final bool isAlternate; // 是否使用交替布局
  final double cardHeight; // 卡片高度因子，用于微调内部元素大小
  final VoidCallback? onEdit; // 编辑按钮的回调
  final VoidCallback? onDelete; // 删除按钮的回调

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [userId]：活动创建者/所有者的用户 ID。
  /// [currentUser]：当前登录用户。
  /// [infoProvider]：用户信息 Provider。
  /// [followService]：用户关注服务。
  /// [createTime]：活动创建时间。
  /// [updateTime]：活动最后更新时间。
  /// [isEdited]：活动是否被编辑过。
  /// [activityType]：活动类型字符串。
  /// [isAlternate]：是否使用交替布局。
  /// [cardHeight]：卡片高度因子。
  /// [onEdit]：编辑按钮的回调。
  /// [onDelete]：删除按钮的回调。
  const ActivityHeader({
    super.key,
    required this.userId,
    required this.currentUser,
    required this.infoService,
    required this.followService,
    required this.createTime,
    this.updateTime,
    this.isEdited = false,
    required this.activityType,
    this.isAlternate = false,
    this.cardHeight = 1.0,
    this.onEdit,
    this.onDelete,
  });

  /// 构建 Widget。
  ///
  /// 根据活动信息和权限渲染头部内容。
  @override
  Widget build(BuildContext context) {
    final String timeAgo =
        DateTimeFormatter.formatTimeAgo(createTime); // 格式化创建时间
    final currentUserId = currentUser?.id; // 当前用户 ID
    final isAdmin = currentUser?.isAdmin ?? false; // 当前用户是否为管理员
    final theme = Theme.of(context); // 当前主题

    final bool canEdit = onEdit != null &&
        currentUserId != null &&
        currentUserId == userId; // 判断是否可编辑
    final bool canDelete = onDelete != null &&
        currentUserId != null &&
        (currentUserId == userId || isAdmin); // 判断是否可删除

    return Column(
      crossAxisAlignment: isAlternate
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start, // 根据布局样式设置交叉轴对齐
      children: [
        Row(
          textDirection: isAlternate
              ? TextDirection.rtl
              : TextDirection.ltr, // 根据布局样式设置文本方向
          children: [
            Expanded(
              child: UserInfoBadge(
                targetUserId: userId, // 目标用户 ID
                currentUser: currentUser, // 当前用户
                infoService: infoService, // 用户信息 Provider
                followService: followService, // 用户关注服务
                showFollowButton: false, // 不显示关注按钮
                mini: true, // 使用紧凑模式
                showLevel: true, // 显示用户等级
                backgroundColor: Colors.transparent, // 背景透明
              ),
            ),

            if (!isAlternate) _buildTimeAgoText(timeAgo), // 非交替布局时显示时间
            const SizedBox(width: 8.0), // 间距

            _buildActivityTypeChip(), // 构建活动类型 Chip

            if (isAlternate) const SizedBox(width: 8.0), // 间距
            if (isAlternate) _buildTimeAgoText(timeAgo), // 交替布局时显示时间

            if (canEdit || canDelete) // 可编辑或可删除时显示操作菜单
              _buildActionMenu(context, theme, canEdit, canDelete),
            if (!canEdit && !canDelete) const SizedBox(width: 4), // 无操作时留出空间
          ],
        ),

        if (isEdited && updateTime != null)
          _buildEditTimeText(context), // 编辑过且有更新时间时显示编辑时间
      ],
    );
  }

  /// 构建时间文本 Widget。
  ///
  /// [timeAgo]：格式化后的时间字符串。
  /// 返回包含时间文本的 Padding Widget。
  Widget _buildTimeAgoText(String timeAgo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // 水平内边距
      child: Text(
        timeAgo, // 时间文本
        style: TextStyle(
          fontSize: 11 * math.sqrt(cardHeight * 0.8), // 字体大小
          color: Colors.grey.shade600, // 字体颜色
        ),
        overflow: TextOverflow.ellipsis, // 溢出时显示省略号
      ),
    );
  }

  /// 构建活动类型 Chip Widget。
  ///
  /// 返回包含活动类型文本的 Container Widget。
  Widget _buildActivityTypeChip() {
    final displayInfo = ActivityTypeUtils.getActivityTypeDisplayInfo(
        activityType); // 获取活动类型显示信息
    double fontSize =
        math.min(math.max(10, 10 * math.sqrt(cardHeight * 0.7)), 11.5); // 字体大小
    double horizontalPadding =
        math.min(math.max(5, 5 * cardHeight * 0.8), 7); // 水平内边距
    double verticalPadding =
        math.min(math.max(2, 2 * cardHeight * 0.8), 3.5); // 垂直内边距
    double borderRadius =
        math.min(math.max(8, 8 * cardHeight * 0.8), 10); // 边框圆角

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: displayInfo.backgroundColor.withSafeOpacity(0.85), // 背景颜色
        borderRadius: BorderRadius.circular(borderRadius), // 边框圆角
      ),
      child: Text(
        displayInfo.text, // 活动类型文本
        style: TextStyle(
          fontSize: fontSize, // 字体大小
          color: displayInfo.textColor, // 字体颜色
          fontWeight: FontWeight.w500, // 字体粗细
        ),
      ),
    );
  }

  /// 构建操作菜单 Widget。
  ///
  /// [context]：Build 上下文。
  /// [theme]：当前主题数据。
  /// [canEdit]：是否可编辑。
  /// [canDelete]：是否可删除。
  /// 返回一个样式化的弹出菜单按钮。
  Widget _buildActionMenu(
      BuildContext context, ThemeData theme, bool canEdit, bool canDelete) {
    return StylishPopupMenuButton<String>(
      icon: Icons.more_vert, // 更多操作图标
      iconSize: 16 * math.sqrt(cardHeight * 0.8), // 图标尺寸
      iconColor: Colors.grey.shade600, // 图标颜色
      tooltip: '更多操作', // 提示文本
      triggerPadding: const EdgeInsets.all(4.0), // 触发区域内边距
      offset: const Offset(0, 25), // 偏移量
      menuColor: theme.canvasColor, // 菜单颜色
      elevation: 2.0, // 阴影
      itemHeight: 36, // 菜单项高度
      items: [
        if (canEdit) // 可编辑时显示编辑菜单项
          StylishMenuItemData(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined,
                  size: 16, color: theme.colorScheme.primary), // 编辑图标
              const SizedBox(width: 8), // 间距
              const Text('编辑'), // 编辑文本
            ]),
          ),
        if (canEdit && canDelete) // 可编辑且可删除时显示分割线
          const StylishMenuDividerData(), // 分割线
        if (canDelete) // 可删除时显示删除菜单项
          StylishMenuItemData(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline,
                  size: 16, color: theme.colorScheme.error), // 删除图标
              const SizedBox(width: 8), // 间距
              Text('删除',
                  style: TextStyle(color: theme.colorScheme.error)), // 删除文本
            ]),
          ),
      ],
      onSelected: (value) {
        // 菜单项选中回调
        if (value == 'edit') {
          onEdit?.call(); // 调用编辑回调
        } else if (value == 'delete') {
          onDelete?.call(); // 调用删除回调
        }
      },
    );
  }

  /// 构建编辑时间文本 Widget。
  ///
  /// [context]：Build 上下文。
  /// 返回包含编辑时间文本的 Padding Widget。
  Widget _buildEditTimeText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0), // 顶部内边距
      child: Row(
        mainAxisSize: MainAxisSize.min, // 最小尺寸
        textDirection:
            isAlternate ? TextDirection.rtl : TextDirection.ltr, // 文本方向
        children: [
          Icon(
            Icons.edit_note, // 编辑图标
            size: 10 * math.sqrt(cardHeight * 0.7), // 图标尺寸
            color: Colors.grey.shade500, // 图标颜色
          ),
          const SizedBox(width: 4), // 间距
          Text(
            '编辑于 ${DateTimeFormatter.formatRelative(updateTime!)}', // 编辑时间文本
            style: TextStyle(
              fontSize: 10 * math.sqrt(cardHeight * 0.7), // 字体大小
              color: Colors.grey.shade500, // 字体颜色
              fontStyle: FontStyle.italic, // 斜体
            ),
            overflow: TextOverflow.ellipsis, // 溢出时显示省略号
          ),
        ],
      ),
    );
  }
}
