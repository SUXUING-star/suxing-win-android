// lib/widgets/components/screen/checkin/responsive_checkin_layout.dart
import 'package:flutter/material.dart';
import '../../../../models/user/user_checkin.dart';
import '../../../../models/user/user_level.dart';
import '../../../../utils/device/device_utils.dart';
import 'calendar/calendar_view.dart';
import 'checkin_rules_card.dart';
import 'level_progress_card.dart';
import 'today_checkin_list.dart';

/// Responsive Check-in Layout Component
/// Automatically adjusts layout based on device type and screen size
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
  final int missedDays; // Total missed days in the month (漏签天数)
  final int consecutiveMissedDays; // Days since last check-in (断签天数)

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
    this.missedDays = 0, // Default to 0
    this.consecutiveMissedDays = 0, // Default check-in gap to 0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Determine device type
    final isTablet = DeviceUtils.isTablet(context);
    final isDesktop = DeviceUtils.isDesktop;
    final isLandscape = DeviceUtils.isLandscape(context);

    // Desktop or landscape tablet use side-by-side layout
    if (isDesktop || (isTablet && isLandscape)) {
      return _buildHorizontalLayout(context);
    } else {
      // Mobile or portrait tablet use vertical layout
      return _buildVerticalLayout(context);
    }
  }

  /// Horizontal side-by-side layout (desktop or landscape tablet)
  Widget _buildHorizontalLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left - Calendar area (scrollable)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: CalendarView(
                selectedYear: selectedYear,
                selectedMonth: selectedMonth,
                monthlyData: monthlyData,
                onChangeMonth: onChangeMonth,
                missedDays: missedDays,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Right panel - height controlled, scrollable
          Expanded(
            flex: 2,
            child: _buildRightPanel(context),
          ),
        ],
      ),
    );
  }

  /// Right panel build - includes user level, check-in stats and rules
  Widget _buildRightPanel(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 80, // Account for AppBar and margins
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
                missedDays: missedDays, // Total missed days
                consecutiveMissedDays: consecutiveMissedDays, // Check-in gap
              ),
            const SizedBox(height: 16),
            _buildStatsSummary(context),
            const SizedBox(height: 16),
            // Add today's check-in list
            TodayCheckInList(maxHeight: 200),
            const SizedBox(height: 16),
            CheckInRulesCard(),
          ],
        ),
      ),
    );
  }

  /// Vertical layout (mobile or portrait tablet)
  Widget _buildVerticalLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level progress card
          if (checkInStats != null)
            LevelProgressCard(
              stats: checkInStats!,
              userLevel: userLevel,
              isLoading: isCheckInLoading,
              hasCheckedToday: hasCheckedToday,
              animationController: animationController,
              onCheckIn: onCheckIn,
              missedDays: missedDays, // Pass missed days
              consecutiveMissedDays: consecutiveMissedDays, // Pass check-in gap
            ),

          const SizedBox(height: 16),

          // Check-in stats summary
          _buildStatsSummary(context),

          const SizedBox(height: 16),

          // Add today's check-in list
          TodayCheckInList(),

          const SizedBox(height: 16),

          // Calendar view - reduce vertical padding to prevent overflow
          Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
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
          CheckInRulesCard(),
        ],
      ),
    );
  }

  /// Check-in stats summary card
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
            // Only show when there's a check-in gap
            if (consecutiveMissedDays > 0) ...[
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.shade300,
              ),
              _buildStatItem(
                context: context,
                icon: Icons.history_toggle_off,
                title: '断签记录',
                value: '$consecutiveMissedDays 天',
                color: Colors.red[400]!,
                isBold: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build stat item
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