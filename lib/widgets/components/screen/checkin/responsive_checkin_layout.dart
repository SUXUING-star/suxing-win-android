// lib/widgets/components/screen/checkin/responsive_checkin_layout.dart
import 'package:flutter/material.dart';
import '../../../../models/user/user_checkin.dart';
import '../../../../models/user/user_level.dart';
import '../../../../utils/device/device_utils.dart';
import 'calendar_view.dart';
import 'checkin_rules_card.dart';
import 'level_progress_card.dart';

/// 响应式签到布局组件
/// 根据设备类型和屏幕尺寸自动调整布局
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

  const ResponsiveCheckInLayout({
    Key? key,
    required this.checkInStats,
    required this.userLevel,
    required this.monthlyData,
    required this.selectedYear,
    required this.selectedMonth,
    required this.isLoading,
    required this.isCheckInLoading,
    required this.hasCheckedToday,
    required this.animationController,
    required this.onChangeMonth,
    required this.onCheckIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 判断设备类型
    final isTablet = DeviceUtils.isTablet(context);
    final isDesktop = DeviceUtils.isDesktop;
    final isLandscape = DeviceUtils.isLandscape(context);

    // 桌面端或平板横屏使用并排布局
    if (isDesktop || (isTablet && isLandscape)) {
      return _buildHorizontalLayout(context);
    } else {
      // 移动端或平板竖屏使用垂直布局
      return _buildVerticalLayout(context);
    }
  }

  /// 水平并排布局 (桌面端或平板横屏)
  Widget _buildHorizontalLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧 - 日历区域（使其可滚动）
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: CalendarView(
                selectedYear: selectedYear,
                selectedMonth: selectedMonth,
                monthlyData: monthlyData,
                onChangeMonth: onChangeMonth,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 右侧面板 - 高度受控，可滚动
          Expanded(
            flex: 2,
            child: _buildRightPanel(context),
          ),
        ],
      ),
    );
  }

  /// 右侧面板构建 - 包含用户等级、签到统计和规则
  Widget _buildRightPanel(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 80, // 考虑AppBar和一些边距
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (checkInStats != null)
              LevelProgressCard(
                stats: checkInStats!,
                userLevel: userLevel,
                isLoading: isCheckInLoading,
                hasCheckedToday: hasCheckedToday,
                animationController: animationController,
                onCheckIn: onCheckIn,
              ),
            const SizedBox(height: 16),
            _buildStatsSummary(context),
            const SizedBox(height: 16),
            CheckInRulesCard(),
          ],
        ),
      ),
    );
  }

  /// 垂直布局 (移动端或平板竖屏)
  Widget _buildVerticalLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 等级进度卡
          if (checkInStats != null)
            LevelProgressCard(
              stats: checkInStats!,
              userLevel: userLevel,
              isLoading: isCheckInLoading,
              hasCheckedToday: hasCheckedToday,
              animationController: animationController,
              onCheckIn: onCheckIn,
            ),

          const SizedBox(height: 16),

          // 签到统计摘要
          _buildStatsSummary(context),

          const SizedBox(height: 20),

          // 日历视图 - 减小上下边距，防止溢出
          Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: CalendarView(
              selectedYear: selectedYear,
              selectedMonth: selectedMonth,
              monthlyData: monthlyData,
              onChangeMonth: onChangeMonth,
            ),
          ),

          const SizedBox(height: 20),

          // 签到规则
          CheckInRulesCard(),
        ],
      ),
    );
  }

  /// 签到统计摘要卡片
  Widget _buildStatsSummary(BuildContext context) {
    final theme = Theme.of(context);
    final continuousDays = checkInStats?.continuousDays ?? 0;
    final totalCheckIns = checkInStats?.totalCheckIns ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
              color: theme.primaryColor,
            ),
            Container(
              height: 50,
              width: 1,
              color: Colors.grey.shade300,
            ),
            _buildStatItem(
              context: context,
              icon: Icons.timeline,
              title: '连续签到',
              value: '$continuousDays 天',
              color: continuousDays > 0 ? Colors.orange : theme.primaryColor,
              isBold: continuousDays > 0,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}