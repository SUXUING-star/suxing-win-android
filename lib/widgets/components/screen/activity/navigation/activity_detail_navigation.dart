/// lib/widgets/components/screen/activity/navigation/activity_detail_navigation.dart

/// 该文件定义了 ActivityDetailNavigation 组件，用于显示活动的上一篇/下一篇导航。
/// ActivityDetailNavigation 负责渲染导航按钮，并处理导航逻辑。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/models/activity/activity_detail_param.dart';
import 'package:suxingchahui/models/activity/activity_navigation_info.dart';
import 'package:suxingchahui/models/activity/activity.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

/// `ActivityDetailNavigation` 类：活动导航板块组件。
///
/// 该组件显示用于在活动详情页之间切换的“上一篇”和“下一篇”按钮。
class ActivityDetailNavigation extends StatelessWidget {
  final ActivityNavigationInfo navigationInfo;
  final bool isDesktopLayout;

  const ActivityDetailNavigation({
    super.key,
    required this.navigationInfo,
    required this.isDesktopLayout,
  });

  /// 导航到指定活动。
  void _navigateToActivity(BuildContext context, {required bool isNext}) {
    final Activity? activity =
        isNext ? navigationInfo.nextActivity : navigationInfo.prevActivity;
    final int? pageNum =
        isNext ? navigationInfo.nextPageNum : navigationInfo.prevPageNum;

    if (activity == null) return;

    NavigationUtils.pushNamed(
      context,
      AppRoutes.activityDetail,
      arguments: ActivityDetailParam(
        activityId: activity.id,
        activity: activity,
        listPageNum: pageNum ?? 1,
        feedType: navigationInfo.feedType,
      ),
    );
  }

  /// 构建导航按钮的核心UI，不包含布局逻辑（如Expanded）。
  /// 这让它可以在不同布局中被灵活使用。
  Widget _buildNavigationButtonCore(BuildContext context,
      {required bool isPrevious}) {
    final icon =
        isPrevious ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios;
    final label = isPrevious ? '上一篇' : '下一篇';

    final textWidget = Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );

    final iconWidget = Icon(
      icon,
      size: 16,
      color: Theme.of(context).colorScheme.primary,
    );

    final padding = isDesktopLayout
        ? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0)
        : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: Theme.of(context).dividerColor.withSafeOpacity(0.5),
            width: 1.0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToActivity(context, isNext: !isPrevious),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min, // 让 Row 包裹内容，这是关键！
            children: isPrevious
                ? [iconWidget, const SizedBox(width: 8), textWidget]
                : [textWidget, const SizedBox(width: 8), iconWidget],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPrevious = navigationInfo.prevActivity != null;
    final bool hasNext = navigationInfo.nextActivity != null;

    if (!hasPrevious && !hasNext) {
      return const SizedBox.shrink();
    }

    // --- 桌面端布局：使用 Row + Spacer 实现两端对齐 ---
    // 这他妈才是正确的做法！
    if (isDesktopLayout) {
      return Row(
        children: [
          if (hasPrevious)
            _buildNavigationButtonCore(context, isPrevious: true),

          const Spacer(), // 关键中的关键！把左右两个按钮撑开！

          if (hasNext) _buildNavigationButtonCore(context, isPrevious: false),
        ],
      );
    }

    // --- 移动端布局：使用 Expanded 撑满宽度 ---
    return Row(
      children: [
        if (hasPrevious)
          Expanded(child: _buildNavigationButtonCore(context, isPrevious: true))
        else
          const Expanded(child: SizedBox.shrink()),
        if (hasPrevious && hasNext) const SizedBox(width: 16),
        if (hasNext)
          Expanded(
              child: _buildNavigationButtonCore(context, isPrevious: false))
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}
