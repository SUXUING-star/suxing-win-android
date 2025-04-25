// lib/widgets/components/screen/activity/hot_activities_compact_panel.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/user_activity.dart';
// import 'package:suxingchahui/screens/profile/open_profile_screen.dart'; // <- 不再需要手动导航
// import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // <- 不再需要手动导航
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
// --- 只依赖 UserInfoBadge ---
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';
// import 'package:suxingchahui/widgets/ui/badges/safe_user_avatar.dart'; // <- 干掉
import '../../../utils/activity_utils.dart'; // 这个活动描述工具还是要的

class HotActivitiesCompactPanel extends StatelessWidget {
  final List<UserActivity> hotActivities;
  final Map<String, int> activityStats;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final VoidCallback onRefresh;
  final String Function(String) getActivityTypeName;
  final Color Function(String) getActivityTypeColor;
  final double panelWidth;

  const HotActivitiesCompactPanel({
    super.key,
    required this.hotActivities,
    required this.activityStats,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.onRefresh,
    required this.getActivityTypeName,
    required this.getActivityTypeColor,
    required this.panelWidth,
  });

  @override
  Widget build(BuildContext context) {
    // ... (外部 Card 和 Header 部分不变) ...
    return SizedBox(
      width: panelWidth,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                // ... (Header 内容不变) ...
              ),
            ),
            const Divider(),
            // 简化的统计信息 (不变)
            _buildCompactStatsCards(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // 紧凑的活动列表
            _buildCompactActivitiesList(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // _buildCompactStatsCards 和 _buildMiniActivityTypeTag 不变
  Widget _buildCompactStatsCards() {
    final totalActivities = activityStats['totalActivities'] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '总动态数: $totalActivities',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          _buildMiniActivityTypeTag(),
        ],
      ),
    );
  }
  Widget _buildMiniActivityTypeTag() {
    final typeEntries = activityStats.entries
        .where((entry) => entry.key != 'totalActivities').toList();
    if (typeEntries.isEmpty) return const SizedBox.shrink();
    final topEntry = typeEntries.reduce((a, b) => a.value > b.value ? a : b);
    final topType = topEntry.key;
    final typeName = getActivityTypeName(topType);
    final typeColor = getActivityTypeColor(topType);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        typeName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // 紧凑的活动列表 - ***大改***
  Widget _buildCompactActivitiesList(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: LoadingWidget.inline(size: 16),
      );
    }
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: InlineErrorWidget(errorMessage: errorMessage, onRetry: onRefresh),
      );
    }
    if (hotActivities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: EmptyStateWidget(message: '暂无热门动态', iconSize: 30),
      );
    }

    // 使用 ListView.separated
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hotActivities.length,
      itemBuilder: (context, index) {
        final activity = hotActivities[index];
        final activityDescription =
        ActivityUtils.getActivityDescription(activity);

        // --- 直接在 ListTile 中使用 UserInfoBadge ---
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // 调整垂直 padding
          // *** 用 UserInfoBadge 作为 leading 和 title 的组合 ***
          // *** UserInfoBadge 内部处理点击跳转 ***
          title: UserInfoBadge(
            userId: activity.userId,
            // --- 配置 UserInfoBadge 以适应 ListTile ---
            showFollowButton: false, // 列表里一般不显示关注
            mini: true, // 使用紧凑模式
            showLevel: false, // 列表里一般不显示等级
            backgroundColor: Colors.transparent, // 不需要背景
            padding: EdgeInsets.zero, // 不需要内边距
            // 可以微调头像大小和名字样式（如果 UserInfoBadge 支持）
            // avatarSize: 32, // 示例
            // nameStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // 示例
          ),
          // leading: UserInfoBadge(...) // <- 不再需要单独的 leading
          // title: UserInfoBadge(...) // <- title 现在被 UserInfoBadge 占据

          // --- subtitle 显示活动描述 ---
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 44.0, top: 2.0), // *** 左侧缩进，与 UserInfoBadge 的头像对齐 *** (需要根据实际头像大小调整)
            child: Text(
              activityDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600), // 调整样式
            ),
          ),
          // onTap: () => _navigateToUserProfile(context, activity.userId), // <- 干掉，UserInfoBadge 自己处理
          trailing: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        );
      },
      separatorBuilder: (context, index) =>
      const Divider(height: 1, indent: 12, endIndent: 12), // 分隔线调整
    );
  }

// --- 干掉不再需要的导航方法 ---
// void _navigateToUserProfile(BuildContext context, String userId) { ... } // <- 删除
}