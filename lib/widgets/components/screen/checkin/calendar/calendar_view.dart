// lib/widgets/components/screen/checkin/calendar/calendar_view.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/monthly_checkin_report.dart';
import 'package:suxingchahui/models/user/daily_checkin_info.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class CalendarView extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final MonthlyCheckInReport? monthlyData; // 类型已更新
  final Function(int, int) onChangeMonth;
  final int missedDays; // 父组件已计算好的本月漏签天数

  const CalendarView({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.monthlyData,
    required this.onChangeMonth,
    this.missedDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // --- 直接使用父组件传入的 missedDays ---
    // 只有当查看的是当前实际年月时，才考虑显示漏签天数
    final int displayMissedDays =
        (selectedYear == now.year && selectedMonth == now.month)
            ? missedDays // 使用父组件计算的结果
            : 0; // 其他月份不显示漏签

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '签到日历',
                  style: theme.textTheme.titleSmall ??
                      const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- 使用 displayMissedDays ---
                      if (displayMissedDays > 0) // 只有大于0才显示
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withSafeOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withSafeOpacity(0.3)),
                          ),
                          child: Text(
                            '漏签 $displayMissedDays 天', // 显示处理后的漏签天数
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                int newMonth = selectedMonth - 1;
                                int newYear = selectedYear;
                                if (newMonth < 1) {
                                  newMonth = 12;
                                  newYear--;
                                }
                                onChangeMonth(newYear, newMonth);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 22,
                              splashRadius: 18,
                              tooltip: '上个月',
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$selectedYear年$selectedMonth月',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                int newMonth = selectedMonth + 1;
                                int newYear = selectedYear;
                                if (newMonth > 12) {
                                  newMonth = 1;
                                  newYear++;
                                }
                                onChangeMonth(newYear, newMonth);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 22,
                              splashRadius: 18,
                              tooltip: '下个月',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            monthlyData == null
                ? LoadingWidget.inline() // 数据加载中显示 Loading
                : _buildCalendarGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final weekdayTitles = ['一', '二', '三', '四', '五', '六', '日'];
    final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
    final int firstWeekdayIndex = (firstDayOfMonth.weekday - 1) % 7;
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    // --- 使用新的模型访问数据 ---
    final Map<int, DailyCheckInInfo> checkedInDaysData = {};
    if (monthlyData != null) {
      for (final dayInfo in monthlyData!.days) {
        // monthlyData 不为 null
        if (dayInfo.checkedIn) {
          // 假设 dayInfo.day 是有效的日期数字 (1-31)
          // DailyCheckInInfo.fromJson 应该已经处理了日期的解析和有效性
          checkedInDaysData[dayInfo.day] = dayInfo;
        }
      }
    }
    // --- 数据解析结束 ---

    final now = DateTime.now();
    final Set<int> missedCheckInDaysThisMonthView = {};
    if (selectedYear == now.year && selectedMonth == now.month) {
      // 仅当查看的是当前实际月份时才计算当前视图的漏签日期
      // 这是为了视觉上标记“漏签”的格子，不同于父组件计算的“本月总漏签”
      for (int day = 1; day < now.day; day++) {
        if (!checkedInDaysData.containsKey(day)) {
          missedCheckInDaysThisMonthView.add(day);
        }
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdayTitles.map((title) {
            final isWeekend = title == '六' || title == '日';
            return Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color:
                        isWeekend ? Colors.red.shade300 : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(height: 10, thickness: 0.5),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1 / 1.4, // 保持之前的调整
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: firstWeekdayIndex + daysInMonth,
          itemBuilder: (context, index) {
            final dayNumber = index - firstWeekdayIndex + 1;

            if (index < firstWeekdayIndex) {
              return Container();
            }

            final date = DateTime(selectedYear, selectedMonth, dayNumber);
            final isToday = now.year == selectedYear &&
                now.month == selectedMonth &&
                now.day == dayNumber;
            final isWeekend = date.weekday >= 6;
            final DailyCheckInInfo? dayCheckInInfo =
                checkedInDaysData[dayNumber];
            final bool isCheckedIn = dayCheckInInfo?.checkedIn ?? false;
            final int experience = dayCheckInInfo?.exp ?? 0;
            // 当前视图的漏签标记
            final bool isMarkedAsMissed =
                missedCheckInDaysThisMonthView.contains(dayNumber);

            return _buildDayCell(
              context: context,
              day: dayNumber,
              isToday: isToday,
              isWeekend: isWeekend,
              isCheckedIn: isCheckedIn,
              isMissedCheckIn: isMarkedAsMissed, // 使用当前视图计算的漏签标记
              experience: experience,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required int day,
    required bool isToday,
    required bool isWeekend,
    required bool isCheckedIn,
    required bool isMissedCheckIn, // 这是指当前格子是否标记为“漏签”样式
    required int experience,
  }) {
    final theme = Theme.of(context);
    Color textColor = Colors.black87;
    Color bgColor = Colors.transparent;
    Color borderColor = Colors.transparent;
    double borderWidth = 0;
    FontWeight fontWeight = FontWeight.normal;

    if (isWeekend && !isToday) {
      textColor = Colors.red.shade300;
    }
    if (isMissedCheckIn) {
      // 如果这个格子被标记为漏签
      textColor = Colors.grey.shade500;
      bgColor = Colors.red.withSafeOpacity(0.05);
      borderColor = Colors.red.withSafeOpacity(0.1);
      borderWidth = 0.5;
    }
    if (isToday) {
      textColor = theme.primaryColor;
      borderColor = theme.primaryColor;
      borderWidth = 1.5;
      fontWeight = FontWeight.bold;
    }

    const double iconSize = 12.0;
    const double experienceFontSize = 9.0;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              SizedBox(
                height: iconSize + 4,
                child: isCheckedIn
                    ? Icon(Icons.check_circle_outline,
                        color: theme.primaryColor.withSafeOpacity(0.85),
                        size: iconSize)
                    : isMissedCheckIn // 如果标记为漏签样式，显示关闭图标
                        ? Icon(Icons.close,
                            color: Colors.red.shade200, size: iconSize)
                        : null,
              ),
              SizedBox(
                height:
                    isCheckedIn && experience > 0 ? experienceFontSize + 2 : 0,
                child: isCheckedIn && experience > 0
                    ? Text(
                        '+$experience',
                        style: TextStyle(
                          fontSize: experienceFontSize,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      )
                    : null,
              ),
            ],
          ),
          if (isToday && !isCheckedIn)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
