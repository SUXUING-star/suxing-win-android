// lib/widgets/components/screen/checkin/widget/today_checkin_list_section.dart

/// 该文件定义了 TodayCheckInListSection 组件，用于显示今日签到名单。
/// TodayCheckInListSection 展示签到用户列表，并提供加载、刷新和错误处理功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/constants/user/level_constants.dart'; // 用户等级常量所需
import 'package:suxingchahui/models/user/user.dart'; // 用户模型所需
import 'package:suxingchahui/services/main/user/user_info_service.dart'; // 用户信息服务所需
import 'package:suxingchahui/services/main/user/user_follow_service.dart'; // 用户关注服务所需
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart'; // 空状态组件所需
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 错误组件所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需
import 'package:suxingchahui/models/user/user_checkIn_today_list.dart'; // 今日签到列表模型所需
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart'; // 用户信息徽章组件所需

/// `TodayCheckInListSection` 类：显示今日签到名单的 StatelessWidget。
///
/// 该组件负责渲染签到用户列表，并根据加载状态、错误信息和列表内容显示不同的UI。
class TodayCheckInListSection extends StatelessWidget {
  final User? currentUser; // 当前登录用户
  final UserFollowService followService; // 用户关注服务
  final UserInfoService infoService; // 用户信息服务
  final double? maxHeight; // 列表最大高度
  final bool showTitle; // 是否显示标题
  final bool isLoading; // 列表是否处于加载状态
  final TodayCheckInList? checkInList; // 今日签到列表数据
  final VoidCallback onRefresh; // 刷新回调
  final String? errMsg; // 错误消息

  /// 构造函数。
  ///
  /// [currentUser]：当前登录用户。
  /// [followService]：用户关注服务。
  /// [infoService]：用户信息服务。
  /// [maxHeight]：列表最大高度。
  /// [showTitle]：是否显示标题。
  /// [errMsg]：错误消息。
  /// [isLoading]：列表加载状态。
  /// [checkInList]：今日签到列表数据。
  /// [onRefresh]：刷新回调。
  const TodayCheckInListSection({
    super.key,
    required this.currentUser,
    required this.followService,
    required this.infoService,
    this.maxHeight,
    this.showTitle = true,
    this.errMsg,
    required this.isLoading,
    required this.checkInList,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // 阴影
      margin: EdgeInsets.zero, // 外边距
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)), // 圆角边框
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 最小化主轴尺寸
        children: [
          if (showTitle) // 显示标题
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // 内边距
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '今日签到名单',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (checkInList != null && !isLoading) // 显示签到人数
                        Text('共 ${checkInList!.count} 人',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 8), // 间距
                      InkWell(
                        onTap: isLoading ? null : onRefresh, // 刷新按钮点击回调
                        borderRadius: BorderRadius.circular(20), // 圆角
                        child: Padding(
                          padding: const EdgeInsets.all(4.0), // 内边距
                          child: Icon(Icons.refresh,
                              size: 20,
                              color: isLoading
                                  ? Colors.grey[400]
                                  : Colors.grey[600]), // 刷新图标颜色
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          _buildContent(context), // 构建内容区域
        ],
      ),
    );
  }

  /// 构建内容区域。
  ///
  /// [context]：Build 上下文。
  /// 根据加载状态、错误信息和列表内容显示不同的 UI。
  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      // 加载中状态
      double loadingDisplayHeight = 100.0;
      if (maxHeight != null && maxHeight! < 100.0) {
        loadingDisplayHeight = maxHeight!; // 调整加载显示高度
      }
      return SizedBox(
        height: loadingDisplayHeight,
        child: const LoadingWidget(), // 显示加载指示器
      );
    }
    if (errMsg != null) {
      // 错误状态
      return InlineErrorWidget(
        errorMessage: errMsg, // 错误消息
        onRetry: onRefresh, // 重试回调
        retryText: "尝试重试", // 重试文本
      );
    }

    if (checkInList == null || checkInList!.users.isEmpty) {
      // 空状态
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
        child: EmptyStateWidget(
          message: '今天还没有小伙伴签到呢',
          iconData: Icons.emoji_people_outlined,
        ),
      );
    }

    // 列表内容
    ScrollPhysics physics;
    if (maxHeight != null) {
      // 根据最大高度设置滚动物理
      physics = checkInList!.users.length > (maxHeight! / 50.0).floor()
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics();
    } else {
      physics = const NeverScrollableScrollPhysics(); // 默认禁用滚动
    }

    return Container(
      constraints: maxHeight != null // 根据最大高度设置约束
          ? BoxConstraints(maxHeight: maxHeight!)
          : const BoxConstraints(),
      child: ListView.builder(
        itemCount: checkInList!.users.length, // 用户数量
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 内边距
        shrinkWrap: true, // 根据内容收缩高度
        physics: physics, // 滚动物理
        itemBuilder: (context, index) {
          final String userId = checkInList!.users[index]; // 当前用户ID
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0), // 垂直内边距
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LevelUtils.getLevelColor(index + 1), // 等级颜色
                    shape: BoxShape.circle, // 圆形
                  ),
                  child: Text(
                    '${index + 1}', // 排名
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8), // 间距
                Expanded(
                  child: UserInfoBadge(
                    // 用户信息徽章
                    currentUser: currentUser,
                    infoService: infoService,
                    followService: followService,
                    targetUserId: userId,
                    showFollowButton: true,
                    mini: true,
                    showLevel: true,
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    showCheckInStats: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
