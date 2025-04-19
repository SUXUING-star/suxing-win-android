// lib/widgets/components/screen/checkin/layout/responsive_checkin_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import '../../../../../models/user/user_checkin.dart';
import '../../../../../models/user/user_level.dart';
import '../../../../../utils/device/device_utils.dart';
import '../calendar/calendar_view.dart';
import '../widget/checkin_rules_card.dart';
import '../progress/level_progress_card.dart';
import '../widget/today_checkin_list.dart';

class ResponsiveCheckInLayout extends StatelessWidget {
  final CheckInStats? checkInStats;
  final UserLevel? userLevel;
  final Map<String, dynamic>? monthlyData;
  final int selectedYear;
  final int selectedMonth;
  final bool isLoading;
  final bool isCheckInLoading;
  final bool hasCheckedToday;
  final AnimationController animationController;
  final Function(int, int) onChangeMonth;
  final VoidCallback onCheckIn;
  final int missedDays;
  final int consecutiveMissedDays;
  // --- 新增：接收动画播放状态 ---
  // final bool playAnimations; // 从 CheckInScreen 传递过来
  // --- 结束新增 ---

  const ResponsiveCheckInLayout({
    Key? key,
    required this.checkInStats,
    required this.userLevel,
    required this.monthlyData,
    required this.selectedYear,
    required this.selectedMonth,
    required this.isLoading, // 虽然外部已处理，但保留以防万一
    required this.isCheckInLoading,
    required this.hasCheckedToday,
    required this.animationController,
    required this.onChangeMonth,
    required this.onCheckIn,
    this.missedDays = 0,
    this.consecutiveMissedDays = 0,
    // --- 新增：接收动画播放状态 ---
    // this.playAnimations = false, // 默认不播放
    // --- 结束新增 ---
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 外部已经处理了 Loading，这里可以简化
    // if (isLoading) { return const Center(child: CircularProgressIndicator()); }

    final isTablet = DeviceUtils.isTablet(context);
    final isDesktop = DeviceUtils.isDesktop;
    final isLandscape = DeviceUtils.isLandscape(context);

    if (isDesktop || (isTablet && isLandscape)) {
      return _buildHorizontalLayout(context);
    } else {
      return _buildVerticalLayout(context);
    }
  }

  /// Horizontal side-by-side layout (应用内部动画)
  Widget _buildHorizontalLayout(BuildContext context) {
    // 定义基础延迟和间隔
    const Duration initialDelay =
        Duration(milliseconds: 100); // 整体容器动画已有时延，内部可以快点
    const Duration stagger = Duration(milliseconds: 150);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left - Calendar area
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              // --- 修改这里：为 CalendarView 添加动画 ---
              child: FadeInSlideUpItem(
                // play: playAnimations,
                delay: initialDelay, // 左侧先出现
                child: CalendarView(
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  monthlyData: monthlyData,
                  onChangeMonth: onChangeMonth,
                  missedDays: missedDays,
                ),
              ),
              // --- 结束修改 ---
            ),
          ),

          const SizedBox(width: 16),

          // Right panel - 内部组件应用动画
          Expanded(
            flex: 2,
            child:
                _buildRightPanel(context, initialDelay + stagger), // 传递右侧起始延迟
          ),
        ],
      ),
    );
  }

  /// Right panel build (应用内部动画)
  /// 添加一个 `startDelay` 参数来控制起始延迟
  Widget _buildRightPanel(BuildContext context, Duration startDelay) {
    // 定义右侧内部的交错间隔
    const Duration internalStagger = Duration(milliseconds: 100);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 80,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // --- 修改这里：为右侧组件添加带延迟的动画 ---
            // LevelProgressCard
            if (checkInStats != null)
              FadeInSlideUpItem(
                // play: playAnimations,
                delay: startDelay, // 使用传入的起始延迟
                child: LevelProgressCard(
                  stats: checkInStats!,
                  userLevel: userLevel,
                  isLoading: isCheckInLoading,
                  hasCheckedToday: hasCheckedToday,
                  animationController: animationController,
                  onCheckIn: onCheckIn,
                  missedDays: missedDays,
                  consecutiveMissedDays: consecutiveMissedDays,
                ),
              ),
            const SizedBox(height: 16),
            // Stats Summary
            FadeInSlideUpItem(
              // play: playAnimations,
              delay: startDelay + internalStagger, // 增加延迟
              child: _buildStatsSummary(context),
            ),
            const SizedBox(height: 16),
            // Today Check-in List
            FadeInSlideUpItem(
              // play: playAnimations,
              delay: startDelay + internalStagger * 2, // 再增加延迟
              child: TodayCheckInList(maxHeight: 200),
            ),
            const SizedBox(height: 16),
            // Rules Card
            FadeInSlideUpItem(
              // play: playAnimations,
              delay: startDelay + internalStagger * 3, // 最后出现
              child: CheckInRulesCard(),
            ),
            // --- 结束修改 ---
          ],
        ),
      ),
    );
  }

  /// Vertical layout (应用内部动画)
  Widget _buildVerticalLayout(BuildContext context) {
    // 定义基础延迟和间隔
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 100); // 垂直布局间隔可以小点

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 修改这里：为垂直布局组件添加带延迟的动画 ---
          // Level progress card
          if (checkInStats != null)
            FadeInSlideUpItem(
              // play: playAnimations,
              delay: initialDelay, // 第一个出现
              child: LevelProgressCard(
                stats: checkInStats!,
                userLevel: userLevel,
                isLoading: isCheckInLoading,
                hasCheckedToday: hasCheckedToday,
                animationController: animationController,
                onCheckIn: onCheckIn,
                missedDays: missedDays,
                consecutiveMissedDays: consecutiveMissedDays,
              ),
            ),
          const SizedBox(height: 16),
          // Check-in stats summary
          FadeInSlideUpItem(
            // play: playAnimations,
            delay: initialDelay + stagger, // 增加延迟
            child: _buildStatsSummary(context),
          ),
          const SizedBox(height: 16),
          // Today Check-in List
          FadeInSlideUpItem(
            // play: playAnimations,
            delay: initialDelay + stagger * 2, // 再增加延迟
            child: TodayCheckInList(),
          ),
          const SizedBox(height: 16),
          // CalendarView
          FadeInSlideUpItem(
            // play: playAnimations,
            delay: initialDelay + stagger * 3, // 再增加延迟
            child: CalendarView(
              selectedYear: selectedYear,
              selectedMonth: selectedMonth,
              monthlyData: monthlyData,
              onChangeMonth: onChangeMonth,
              missedDays: missedDays,
            ),
          ),
          const SizedBox(height: 16),
          // Check-in rules
          FadeInSlideUpItem(
            // play: playAnimations,
            delay: initialDelay + stagger * 4, // 最后出现
            child: CheckInRulesCard(),
          ),
          const SizedBox(height: 16),
          // --- 结束修改 ---
        ],
      ),
    );
  }

  // _buildStatsSummary 和 _buildStatItem 保持不变，动画在其外部应用
  Widget _buildStatsSummary(BuildContext context) {
    final theme = Theme.of(context);
    final continuousDays = checkInStats?.continuousDays ?? 0;
    final totalCheckIns = checkInStats?.totalCheckIns ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                context: context,
                icon: Icons.calendar_today,
                title: '累计签到',
                value: '$totalCheckIns 天',
                color: theme.primaryColor),
            Container(height: 50, width: 1, color: Colors.grey.shade300),
            _buildStatItem(
                context: context,
                icon: Icons.timeline,
                title: '连续签到',
                value: '$continuousDays 天',
                color: continuousDays > 0 ? Colors.orange : theme.primaryColor,
                isBold: continuousDays > 0),
            if (consecutiveMissedDays > 1) ...[
              Container(height: 50, width: 1, color: Colors.grey.shade300),
              _buildStatItem(
                  context: context,
                  icon: Icons.history_toggle_off,
                  title: '断签记录',
                  value: '$consecutiveMissedDays 天',
                  color: Colors.red[400]!,
                  isBold: false)
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      {required BuildContext context,
      required IconData icon,
      required String title,
      required String value,
      required Color color,
      bool isBold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color)),
      ],
    );
  }
}
