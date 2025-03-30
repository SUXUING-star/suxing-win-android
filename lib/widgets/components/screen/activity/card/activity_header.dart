// lib/widgets/components/screen/activity/card/activity_header.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
import 'dart:math' as math;
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart';
import 'package:suxingchahui/widgets/ui/buttons/custom_popup_menu_button.dart';
import 'package:suxingchahui/widgets/ui/image/safe_cached_image.dart';
// --- 引入新的活动类型工具类 ---
import 'package:suxingchahui/utils/activity/activity_type_utils.dart';

class ActivityHeader extends StatelessWidget {
  final Map<String, dynamic>? user;
  final DateTime createTime;
  final DateTime? updateTime;
  final bool isEdited;
  final String activityType;
  final bool isAlternate;
  final double cardHeight;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;


  const ActivityHeader({
    Key? key,
    required this.user,
    required this.createTime,
    this.updateTime,
    this.isEdited = false,
    required this.activityType,
    this.isAlternate = false,
    this.cardHeight = 1.0,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final userId = user?['userId'] ?? '';
    final String timeAgo = DateTimeFormatter.formatRelative(createTime);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUserId;
    final isAdmin = authProvider.isAdmin;

    final bool canEdit = onEdit != null && authProvider.isLoggedIn && currentUserId == userId;
    final bool canDelete = onDelete != null && authProvider.isLoggedIn && (currentUserId == userId || isAdmin);

    return Column(
      crossAxisAlignment: isAlternate ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // UserInfoBadge 或 LegacyUserInfo
            Expanded(
              child: userId.isNotEmpty
                  ? UserInfoBadge(
                userId: userId,
                showFollowButton: true,
                mini: true,
                showLevel: true,
                backgroundColor: Colors.transparent,
              )
                  : _buildLegacyUserInfo(context),
            ),

            // 时间 (左侧)
            if (!isAlternate)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11 * math.sqrt(cardHeight * 0.8),
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // 活动类型 Chip
            _buildActivityTypeChip(),

            // 时间 (右侧，交替布局时)
            if (isAlternate)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11 * math.sqrt(cardHeight * 0.8),
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // 操作菜单按钮
            if (canEdit || canDelete)
              CustomPopupMenuButton<String>(
                icon: Icons.more_vert,
                iconSize: 16 * math.sqrt(cardHeight * 0.8),
                iconColor: Colors.grey.shade600,
                tooltip: '更多操作',
                padding: const EdgeInsets.all(4.0),
                offset: const Offset(0, 25),
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) {
                    onEdit!();
                  } else if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
                itemBuilder: (context) => [
                  if (canEdit)
                    const PopupMenuItem<String>(
                      value: 'edit',
                      height: 36,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                  if (canDelete)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      height: 36,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),

        // 编辑时间显示
        if (isEdited && updateTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Icon(
                  Icons.edit_note,
                  size: 10 * math.sqrt(cardHeight * 0.7),
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '编辑于 ${DateTimeFormatter.formatRelative(updateTime!)}',
                  style: TextStyle(
                    fontSize: 10 * math.sqrt(cardHeight * 0.7),
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- 补全 _buildLegacyUserInfo ---
  Widget _buildLegacyUserInfo(BuildContext context) {
    final username = user?['username'] ?? '未知用户';
    final avatarUrl = user?['avatar'];
    final double avatarDiameter = 32 * math.sqrt(cardHeight * 0.7);
    final double avatarRadius = avatarDiameter / 2;
    final int cacheSize = _calculateCacheSize(context, avatarDiameter);

    return Row(
      textDirection: isAlternate ? TextDirection.rtl : TextDirection.ltr,
      mainAxisSize: MainAxisSize.min,
      children: [
        avatarUrl != null
            ? SafeCachedImage(
          imageUrl: avatarUrl,
          width: avatarDiameter,
          height: avatarDiameter,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(avatarRadius),
          memCacheWidth: cacheSize,
          memCacheHeight: cacheSize,
          // 可以为 SafeCachedImage 添加背景色以优化占位符/错误状态
          // backgroundColor: Colors.grey.shade300,
        )
            : _buildLegacyFallbackAvatar(username, avatarDiameter),
        SizedBox(width: 8 * cardHeight),
        Flexible(
          child: Text(
            username,
            style: TextStyle(
              fontSize: 14 * math.sqrt(cardHeight * 0.8),
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // --- 补全 _buildLegacyFallbackAvatar ---
  Widget _buildLegacyFallbackAvatar(String username, double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: Colors.grey.shade400, // 可以根据需要调整备用颜色
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          // 安全地获取首字母
          (username.isNotEmpty) ? username[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: diameter * 0.45, // 字体大小与直径相关
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // _calculateCacheSize 方法保持不变
  int _calculateCacheSize(BuildContext context, double displaySize) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (displaySize * devicePixelRatio).round();
  }

  // --- 补全并重构 _buildActivityTypeChip ---
  Widget _buildActivityTypeChip() {
    // 使用工具类获取显示信息
    final displayInfo = ActivityTypeUtils.getActivityTypeDisplayInfo(activityType);

    // 计算尺寸
    double fontSize = math.min(math.max(11, 11 * math.sqrt(cardHeight * 0.7)), 12);
    double horizontalPadding = math.min(math.max(6, 6 * cardHeight * 0.8), 8);
    double verticalPadding = math.min(math.max(3, 3 * cardHeight * 0.8), 4);
    double borderRadius = math.min(math.max(10, 10 * cardHeight * 0.8), 12);

    // 构建 Chip
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: displayInfo.backgroundColor, // 使用工具类返回的背景色
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        displayInfo.text, // 使用工具类返回的文本
        style: TextStyle(
          fontSize: fontSize,
          color: displayInfo.textColor, // 使用工具类返回的文本色
          fontWeight: FontWeight.w500, // 可以稍微加粗
        ),
      ),
    );
  }
}