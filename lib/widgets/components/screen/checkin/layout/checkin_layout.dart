// lib/widgets/components/screen/checkin/layout/checkin_layout.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/checkin_status.dart';
import 'package:suxingchahui/models/user/monthly_checkin_report.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/user/user_checkin.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/calendar/calendar_view.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/progress/level_progress_card.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/widget/checkin_rules_card.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/widget/today_checkin_list_section.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';

class CheckInLayout extends StatelessWidget {
  final CheckInStatus checkInStatus;
  final User currentUser;
  final bool isDesktop;
  final UserInfoProvider infoProvider;
  final UserCheckInService checkInService;
  final UserFollowService followService;
  final MonthlyCheckInReport? monthlyData;
  final int selectedYear;
  final int selectedMonth;
  final bool isCheckInLoading;
  final bool hasCheckedToday;
  final AnimationController animationController;
  final Function(int, int) onChangeMonth;
  final VoidCallback onCheckIn;
  final int missedDays;
  final int consecutiveMissedDays;
  final TodayCheckInList? todayCheckInList;
  final bool isTodayListLoading;
  final VoidCallback onRefreshTodayList;
  final String? todayListErrMsg;

  const CheckInLayout({
    super.key,
    required this.checkInStatus,
    required this.currentUser,
    required this.isDesktop,
    required this.infoProvider,
    required this.checkInService,
    required this.followService,
    required this.monthlyData,
    required this.selectedYear,
    required this.selectedMonth,
    required this.isCheckInLoading,
    required this.hasCheckedToday,
    required this.animationController,
    required this.onChangeMonth,
    required this.onCheckIn,
    required this.isTodayListLoading,
    required this.onRefreshTodayList,
    required this.todayListErrMsg,
    this.missedDays = 0,
    this.consecutiveMissedDays = 0, this.todayCheckInList,
  });

  // --- Animation Parameters ---
  static const Duration _slideDuration = Duration(milliseconds: 400);
  // static const Duration _fadeDuration = Duration(milliseconds: 350); // If needed for FadeInItem
  static const Duration _baseDelay = Duration(milliseconds: 100);
  static const Duration _delayIncrement =
      Duration(milliseconds: 100); // Stagger for vertical
  static const Duration _horizontalStagger =
      Duration(milliseconds: 150); // Stagger for horizontal right panel
  static const Duration _horizontalInternalStagger =
      Duration(milliseconds: 100); // Stagger within horizontal right panel
  static const double _slideOffset = 15.0;

  // --- Section Builders ---

  Widget _buildLevelProgressSection(Duration delay, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration: _slideDuration,
      delay: delay,
      slideOffset: _slideOffset,
      child: LevelProgressCard(
        stats: checkInStatus,
        currentUser: currentUser,
        isLoading: isCheckInLoading,
        hasCheckedToday: hasCheckedToday,
        animationController: animationController,
        onCheckIn: onCheckIn,
        missedDays: missedDays,
        consecutiveMissedDays: consecutiveMissedDays,
      ),
    );
  }

  Widget _buildStatsSummarySection(
      BuildContext context, Duration delay, Key key) {
    final theme = Theme.of(context);
    final continuous = checkInStatus.consecutiveCheckIn;
    final total = checkInStatus.totalCheckIn;

    // Local helper to build stat item, similar to GameDetailContent's pattern
    Widget buildStatItem({
      required IconData icon,
      required String title,
      required String value,
      required Color color,
      bool isBold = false,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return FadeInSlideUpItem(
      key: key,
      duration: _slideDuration,
      delay: delay,
      slideOffset: _slideOffset,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: buildStatItem(
                  icon: Icons.calendar_today_outlined,
                  title: '累计签到',
                  value: '$total 天',
                  color:
                      theme.textTheme.bodySmall?.color ?? Colors.grey.shade700,
                ),
              ),
              Container(height: 50, width: 1, color: Colors.grey.shade300),
              Expanded(
                child: buildStatItem(
                  icon: Icons.local_fire_department_outlined,
                  title: '连续签到',
                  value: '$continuous 天',
                  color: continuous > 0
                      ? Colors.orange.shade700
                      : (theme.textTheme.bodySmall?.color ??
                          Colors.grey.shade700),
                  isBold: continuous > 0,
                ),
              ),
              if (consecutiveMissedDays > 1) ...[
                Container(height: 50, width: 1, color: Colors.grey.shade300),
                Expanded(
                  child: buildStatItem(
                    icon: Icons.link_off_outlined,
                    title: '已断签',
                    value: '$consecutiveMissedDays 天',
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCheckInSection(Duration delay, Key key,
      {double? maxHeight}) {
    return FadeInSlideUpItem(
      key: key,
      duration: _slideDuration,
      delay: delay,
      slideOffset: _slideOffset,
      child: TodayCheckInListSection(
        infoProvider: infoProvider,
        isLoading: isTodayListLoading,
        checkInList: todayCheckInList,
        onRefresh: onRefreshTodayList,
        followService: followService,
        currentUser: currentUser,
        maxHeight: maxHeight, // Pass maxHeight if provided
      ),
    );
  }

  Widget _buildCalendarSection(Duration delay, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration:
          _slideDuration, // Or a different animation type/duration if preferred
      delay: delay,
      slideOffset: _slideOffset,
      child: CalendarView(
        selectedYear: selectedYear,
        selectedMonth: selectedMonth,
        monthlyData: monthlyData,
        onChangeMonth: onChangeMonth,
        missedDays: missedDays,
      ),
    );
  }

  Widget _buildCheckInRulesSection(Duration delay, Key key) {
    return FadeInSlideUpItem(
      key: key,
      duration: _slideDuration,
      delay: delay,
      slideOffset: _slideOffset,
      child: const CheckInRulesCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unique key for the root to ensure proper rebuilds if top-level props change identity,
    // though individual section keys handle most animation triggers.
    // Using a combination of relevant props for the key.
    final rootKey = ValueKey(
        'check_in_content_root_${currentUser.id}_${selectedYear}_$selectedMonth');

    return Padding(
      key: rootKey,
      padding: const EdgeInsets.all(0), // Padding handled by layouts
      child: isDesktop
          ? _buildHorizontalLayout(context)
          : _buildVerticalLayout(context),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    int rightPanelDelayIndex = 0;

    // Keys for horizontal layout
    final calendarKey =
        ValueKey('calendar_horiz_${selectedYear}_$selectedMonth');
    final levelProgressKey = ValueKey('level_horiz_${currentUser.id}');
    final statsSummaryKey =
        ValueKey('stats_summary_horiz_${checkInStatus.hashCode}');
    final todayListKey = ValueKey('today_list_horiz_${currentUser.id}');
    final rulesKey = ValueKey('rules_horiz');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Left: Calendar ---
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              // Keep SingleChildScrollView if calendar content can exceed flexbox space
              child: _buildCalendarSection(
                _baseDelay,
                calendarKey,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // --- Right: Info Panel ---
          Expanded(
            flex: 2,
            child: Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height - kToolbarHeight - 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLevelProgressSection(
                      _baseDelay +
                          _horizontalStagger +
                          (_horizontalInternalStagger * rightPanelDelayIndex++),
                      levelProgressKey,
                    ),
                    const SizedBox(height: 16),
                    _buildStatsSummarySection(
                      context,
                      _baseDelay +
                          _horizontalStagger +
                          (_horizontalInternalStagger * rightPanelDelayIndex++),
                      statsSummaryKey,
                    ),
                    const SizedBox(height: 16),
                    _buildTodayCheckInSection(
                      _baseDelay +
                          _horizontalStagger +
                          (_horizontalInternalStagger * rightPanelDelayIndex++),
                      todayListKey,
                      maxHeight: 200,
                    ),
                    const SizedBox(height: 16),
                    _buildCheckInRulesSection(
                      _baseDelay +
                          _horizontalStagger +
                          (_horizontalInternalStagger * rightPanelDelayIndex++),
                      rulesKey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(BuildContext context) {
    int delayIndex = 0;

    // Keys for vertical layout
    final levelProgressKey = ValueKey('level_vert_${currentUser.id}');
    final statsSummaryKey =
        ValueKey('stats_summary_vert_${checkInStatus.hashCode}');
    final todayListKey = ValueKey('today_list_vert_${currentUser.id}');
    final calendarKey =
        ValueKey('calendar_vert_${selectedYear}_$selectedMonth');
    final rulesKey = ValueKey('rules_vert');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLevelProgressSection(
            _baseDelay + (_delayIncrement * delayIndex++),
            levelProgressKey,
          ),
          const SizedBox(height: 16),
          _buildStatsSummarySection(
            context,
            _baseDelay + (_delayIncrement * delayIndex++),
            statsSummaryKey,
          ),
          const SizedBox(height: 16),
          _buildTodayCheckInSection(
            _baseDelay + (_delayIncrement * delayIndex++),
            todayListKey,
            // maxHeight: null (let it be auto in vertical)
          ),
          const SizedBox(height: 16),
          _buildCalendarSection(
            _baseDelay + (_delayIncrement * delayIndex++),
            calendarKey,
          ),
          const SizedBox(height: 16),
          _buildCheckInRulesSection(
            _baseDelay + (_delayIncrement * delayIndex++),
            rulesKey,
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
}
