import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/activity/activity_constants.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 核心依赖
import 'dart:math' as math;
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/buttons/popup/stylish_popup_menu_button.dart';


/// 活动卡片/详情的头部组件
///
/// 负责显示用户信息 (通过 UserInfoBadge)、活动类型、创建时间、编辑状态和操作菜单。
class ActivityHeader extends StatelessWidget {
  /// 活动创建者/所有者的用户 ID。 **必须提供**。
  final String userId;
  /// 活动创建时间。
  final DateTime createTime;
  /// 活动最后更新时间 (如果 isEdited 为 true)。
  final DateTime? updateTime;
  /// 活动是否被编辑过。
  final bool isEdited;
  /// 活动类型字符串 (例如 "game_comment", "post_create")。
  final String activityType;
  /// 是否使用交替布局 (影响头像、时间和菜单的左右顺序)。
  final bool isAlternate;
  /// 卡片高度因子，用于微调内部元素大小 (可选, 默认为 1.0)。
  final double cardHeight;
  /// 编辑按钮的回调 (如果当前用户有权编辑)。
  final VoidCallback? onEdit;
  /// 删除按钮的回调 (如果当前用户有权删除)。
  final VoidCallback? onDelete;

  const ActivityHeader({
    super.key,
    required this.userId, // *** 改为接收 userId ***
    required this.createTime,
    this.updateTime,
    this.isEdited = false,
    required this.activityType,
    this.isAlternate = false,
    this.cardHeight = 1.0, // 提供默认值
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String timeAgo = DateTimeFormatter.formatRelative(createTime);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUserId;
    final isAdmin = authProvider.isAdmin;
    final theme = Theme.of(context);

    // --- 使用 widget.userId 进行权限判断 ---
    final bool canEdit = onEdit != null &&
        authProvider.isLoggedIn &&
        currentUserId == userId; // 使用传入的 userId
    final bool canDelete = onDelete != null &&
        authProvider.isLoggedIn &&
        (currentUserId == userId || isAdmin); // 使用传入的 userId

    return Column(
      crossAxisAlignment:
      isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // --- 永远使用 UserInfoBadge ---
            Expanded(
              child: UserInfoBadge(
                userId: userId, // *** 直接传递 userId ***
                showFollowButton: false,
                mini: true, // 使用紧凑模式
                showLevel: true, // 可配置是否显示等级
                backgroundColor: Colors.transparent, // 透明背景，融入父级
              ),
            ),

            // --- 时间 (根据 isAlternate 决定位置) ---
            if (!isAlternate) _buildTimeAgoText(timeAgo),
            const SizedBox(width: 8.0), // 时间和类型之间的固定间距

            // --- 活动类型 Chip ---
            _buildActivityTypeChip(),

            // --- 时间 (交替布局时) ---
            if (isAlternate) const SizedBox(width: 8.0), // 类型和时间之间的固定间距
            if (isAlternate) _buildTimeAgoText(timeAgo),

            // --- 操作菜单按钮 ---
            if (canEdit || canDelete) _buildActionMenu(context, theme, canEdit, canDelete),
            // 如果没有操作，留一点空间防止 Chip 紧贴边缘
            if (!canEdit && !canDelete) const SizedBox(width: 4),
          ],
        ),

        // --- 编辑时间显示 ---
        if (isEdited && updateTime != null) _buildEditTimeText(context),
      ],
    );
  }

  // --- Helper Widget: 构建时间文本 ---
  Widget _buildTimeAgoText(String timeAgo) {
    return Padding(
      // 轻微调整 Padding，使其更通用
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        timeAgo,
        style: TextStyle(
          // 使用 cardHeight 微调大小
          fontSize: 11 * math.sqrt(cardHeight * 0.8),
          color: Colors.grey.shade600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // --- Helper Widget: 构建活动类型 Chip ---
  Widget _buildActivityTypeChip() {
    final displayInfo = ActivityTypeUtils.getActivityTypeDisplayInfo(activityType);
    // 使用 cardHeight 微调大小
    double fontSize = math.min(math.max(10, 10 * math.sqrt(cardHeight * 0.7)), 11.5); // 略微减小基础值
    double horizontalPadding = math.min(math.max(5, 5 * cardHeight * 0.8), 7); // 略微减小
    double verticalPadding = math.min(math.max(2, 2 * cardHeight * 0.8), 3.5); // 略微减小
    double borderRadius = math.min(math.max(8, 8 * cardHeight * 0.8), 10); // 略微减小

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: displayInfo.backgroundColor.withOpacity(0.85), // 稍微降低透明度
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        displayInfo.text,
        style: TextStyle(
          fontSize: fontSize,
          color: displayInfo.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- Helper Widget: 构建操作菜单 ---
  Widget _buildActionMenu(BuildContext context, ThemeData theme, bool canEdit, bool canDelete) {
    return StylishPopupMenuButton<String>(
      icon: Icons.more_vert,

      iconSize: 16 * math.sqrt(cardHeight * 0.8), // 使用 cardHeight 调整大小
      iconColor: Colors.grey.shade600,
      tooltip: '更多操作',
      triggerPadding: const EdgeInsets.all(4.0),
      offset: const Offset(0, 25),
      menuColor: theme.canvasColor, // 使用传入的 theme
      elevation: 2.0,
      itemHeight: 36,
      items: [
        if (canEdit)
          StylishMenuItemData(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('编辑'),
            ]),
          ),
        if (canEdit && canDelete) const StylishMenuDividerData(), // 仅在两者都存在时显示分割线
        if (canDelete)
          StylishMenuItemData(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Text('删除', style: TextStyle(color: theme.colorScheme.error)),
            ]),
          ),
      ],
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call(); // 安全调用
        } else if (value == 'delete') {
          onDelete?.call(); // 安全调用
        }
      },
    );
  }

  // --- Helper Widget: 构建编辑时间文本 ---
  Widget _buildEditTimeText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(
            Icons.edit_note,
            // 使用 cardHeight 调整大小
            size: 10 * math.sqrt(cardHeight * 0.7),
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(
            // 使用 ! 断言，因为调用此函数的前提是 updateTime != null
            '编辑于 ${DateTimeFormatter.formatRelative(updateTime!)}',
            style: TextStyle(
              fontSize: 10 * math.sqrt(cardHeight * 0.7), // 使用 cardHeight 调整大小
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

// --- 删除不再需要的辅助函数 ---
// _buildLegacyUserInfo, _buildLegacyFallbackAvatar, _calculateCacheSize
}