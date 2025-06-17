// lib/widgets/components/screen/checkin/widget/today_checkin_list_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/constants/user/level_constants.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/common/empty_state_widget.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/models/user/user_checkIn_today_list.dart';
import 'package:suxingchahui/widgets/ui/badges/user_info_badge.dart';

// 直接改成 StatelessWidget
class TodayCheckInListSection extends StatelessWidget {
  final User? currentUser;
  final UserFollowService followService;
  final UserInfoService infoService;
  final double? maxHeight;
  final bool showTitle;
  final bool isLoading;
  final TodayCheckInList? checkInList;
  final VoidCallback onRefresh;
  final String? errMsg;

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
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                      // 直接用传进来的数据
                      if (checkInList != null && !isLoading)
                        Text('共 ${checkInList!.count} 人',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      InkWell(
                        // 直接用传进来的回调和加载状态
                        onTap: isLoading ? null : onRefresh,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.refresh,
                              size: 20,
                              color: isLoading
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // 内容区域直接调用 _buildContent
          _buildContent(context),
        ],
      ),
    );
  }

  // 把原来的 _buildContent 拿过来，稍微改改
  Widget _buildContent(BuildContext context) {
    // --- 加载中状态 ---
    if (isLoading) {
      double loadingDisplayHeight = 100.0;
      if (maxHeight != null && maxHeight! < 100.0) {
        loadingDisplayHeight = maxHeight!;
      }
      return SizedBox(
        height: loadingDisplayHeight,
        child: const LoadingWidget(),
      );
    }
    if (errMsg != null) {
      return InlineErrorWidget(
        errorMessage: errMsg,
        onRetry: onRefresh,
        retryText: "尝试重试",
      );
    }

    // --- 空状态或错误状态 ---
    // 直接用传进来的 checkInList
    if (checkInList == null || checkInList!.users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 16.0),
        child: EmptyStateWidget(
          message: '今天还没有小伙伴签到呢~',
          iconData: Icons.emoji_people_outlined,
        ),
      );
    }

    // --- 列表内容 ---
    ScrollPhysics physics;
    if (maxHeight != null) {
      physics = checkInList!.users.length > (maxHeight! / 50.0).floor()
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics();
    } else {
      physics = const NeverScrollableScrollPhysics();
    }

    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight!)
          : const BoxConstraints(),
      child: ListView.builder(
        itemCount: checkInList!.users.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shrinkWrap: true,
        physics: physics,
        itemBuilder: (context, index) {
          final String userId = checkInList!.users[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: LevelUtils.getLevelColor(index + 1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: UserInfoBadge(
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
