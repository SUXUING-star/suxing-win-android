// lib/widgets/components/screen/checkin/calendar_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final Map<String, dynamic>? monthlyData;
  final Function(int, int) onChangeMonth;
  final int missedDays; // Added parameter to track missed days

  const CalendarView({
    Key? key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.monthlyData,
    required this.onChangeMonth,
    this.missedDays = 0, // Default to 0 missed days
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate missed days if viewing current month
    int calculatedMissedDays = missedDays;
    if (monthlyData != null && selectedYear == DateTime.now().year && selectedMonth == DateTime.now().month) {
      final List<dynamic> rawDays = monthlyData?['days'] as List? ?? [];
      final Set<int> missedCheckInDays = _calculateMissedDays(rawDays, DateTime(selectedYear, selectedMonth + 1, 0).day);
      calculatedMissedDays = missedCheckInDays.length;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日历标题和月份选择
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '签到日历',
                  style: theme.textTheme.titleSmall,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Display missed days counter only for current month
                      if (selectedYear == DateTime.now().year &&
                          selectedMonth == DateTime.now().month &&
                          calculatedMissedDays > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            '漏签 $calculatedMissedDays 天',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      SizedBox(width: 8),
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
                        constraints: BoxConstraints(),
                        iconSize: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$selectedYear年${selectedMonth}月',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
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
                        constraints: BoxConstraints(),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 日历网格
            monthlyData == null
                ? Center(child: CircularProgressIndicator())
                : _buildCalendarGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final theme = Theme.of(context);

    // 星期标题
    final weekdayTitles = ['一', '二', '三', '四', '五', '六', '日'];

    // 计算月份首日是星期几
    final firstDay = DateTime(selectedYear, selectedMonth, 1);
    int firstWeekday = firstDay.weekday;
    // 调整星期索引（星期一为1，星期日为7）
    if (firstWeekday == 7) firstWeekday = 0;

    // 获取本月天数
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    // 解析签到数据
    final List<dynamic> rawDays = monthlyData?['days'] as List? ?? [];
    final Map<int, Map<String, dynamic>> checkedInDays = {};

    // 计算应该签到但错过的日期
    final Set<int> missedCheckInDays = _calculateMissedDays(rawDays, daysInMonth);

    // 安全地转换数据
    for (final rawDay in rawDays) {
      // 确保是Map类型
      if (rawDay is! Map) continue;

      // 转换为<String, dynamic>
      final Map<String, dynamic> dayData = Map<String, dynamic>.from(rawDay);

      // 提取日期并解析
      if (dayData['checkedIn'] == true && dayData.containsKey('day')) {
        var dayValue = dayData['day'];
        int? dayOfMonth;

        // 处理不同类型的日期值
        if (dayValue is int) {
          dayOfMonth = dayValue;
        } else if (dayValue is String) {
          // 尝试直接解析数字
          dayOfMonth = int.tryParse(dayValue);

          // 如果失败，尝试解析日期字符串
          if (dayOfMonth == null && dayValue.contains('-')) {
            try {
              final parts = dayValue.split('-');
              if (parts.length >= 3) {
                dayOfMonth = int.parse(parts[2]);
              }
            } catch (e) {
              print('解析日期失败: $e');
            }
          }
        }

        // 添加到签到日映射
        if (dayOfMonth != null && dayOfMonth > 0 && dayOfMonth <= daysInMonth) {
          checkedInDays[dayOfMonth] = dayData;
        }
      }
    }

    return Column(
      children: [
        // 星期标题行
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
                    color: isWeekend ? Colors.red.shade300 : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const Divider(height: 16),

        // 日历网格
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            // 填充空白格子
            if (index < firstWeekday) {
              return Container();
            }

            // 实际日期
            final day = index - firstWeekday + 1;
            final date = DateTime(selectedYear, selectedMonth, day);
            final now = DateTime.now();

            // 判断是否今天
            final isToday = now.year == selectedYear &&
                now.month == selectedMonth &&
                now.day == day;

            // 判断是否过去的日期（用于标记漏签）
            final isPastDate = date.isBefore(DateTime(now.year, now.month, now.day));

            // 判断是否周末
            final isWeekend = date.weekday >= 6;

            // 判断是否已签到
            final isCheckedIn = checkedInDays.containsKey(day);

            // 判断是否漏签
            final isMissedCheckIn = isPastDate && !isCheckedIn && missedCheckInDays.contains(day);

            // 安全地获取经验值
            int experience = 0;
            if (isCheckedIn) {
              final dayData = checkedInDays[day];
              if (dayData != null && dayData.containsKey('experience')) {
                final expValue = dayData['experience'];
                if (expValue is int) {
                  experience = expValue;
                } else if (expValue is num) {
                  experience = expValue.toInt();
                } else if (expValue is String) {
                  experience = int.tryParse(expValue) ?? 0;
                }
              }
            }

            return _buildDayCell(
              context: context,
              day: day,
              isToday: isToday,
              isWeekend: isWeekend,
              isCheckedIn: isCheckedIn,
              isMissedCheckIn: isMissedCheckIn,
              experience: experience,
            );
          },
        ),
      ],
    );
  }

  // 计算漏签日期集合（仅包含本月内的日期）
  Set<int> _calculateMissedDays(List<dynamic> rawDays, int daysInMonth) {
    final Set<int> missedDays = {};
    final Set<int> checkedDays = {};
    final now = DateTime.now();

    // 如果查看的不是当前月份，返回空集
    if (selectedYear != now.year || selectedMonth != now.month) {
      return {};
    }

    // 收集已签到的日期
    for (final rawDay in rawDays) {
      if (rawDay is! Map) continue;
      final Map<String, dynamic> dayData = Map<String, dynamic>.from(rawDay);

      if (dayData['checkedIn'] == true && dayData.containsKey('day')) {
        var dayValue = dayData['day'];
        int? dayOfMonth;

        if (dayValue is int) {
          dayOfMonth = dayValue;
        } else if (dayValue is String) {
          dayOfMonth = int.tryParse(dayValue);

          if (dayOfMonth == null && dayValue.contains('-')) {
            try {
              final parts = dayValue.split('-');
              if (parts.length >= 3) {
                dayOfMonth = int.parse(parts[2]);
              }
            } catch (e) {
              print('解析日期失败: $e');
            }
          }
        }

        if (dayOfMonth != null && dayOfMonth > 0 && dayOfMonth <= daysInMonth) {
          checkedDays.add(dayOfMonth);
        }
      }
    }

    // 计算漏签日期（过去的日期，但未在已签到集合中）
    final currentDay = now.day;
    for (int day = 1; day < currentDay; day++) {
      if (!checkedDays.contains(day)) {
        missedDays.add(day);
      }
    }

    return missedDays;
  }

  Widget _buildDayCell({
    required BuildContext context,
    required int day,
    required bool isToday,
    required bool isWeekend,
    required bool isCheckedIn,
    required bool isMissedCheckIn,
    required int experience,
  }) {
    final theme = Theme.of(context);

    // 设置样式
    Color bgColor = Colors.transparent;
    Color textColor = isWeekend ? Colors.red.shade300 : Colors.black87;
    Color borderColor = Colors.transparent;

    if (isToday) {
      borderColor = theme.primaryColor;
      textColor = theme.primaryColor;
    }

    // 如果是漏签日，设置特殊样式（但设计得更加柔和）
    if (isMissedCheckIn) {
      bgColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.15);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: isToday ? 1.5 : (isMissedCheckIn ? 0.5 : 0),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isMissedCheckIn ? Colors.grey.shade500 : textColor,
                  ),
                ),
                SizedBox(height: 2),
                isCheckedIn
                    ? Icon(
                  Icons.check_circle,
                  color: theme.primaryColor,
                  size: 14,
                )
                    : isMissedCheckIn
                    ? Icon(
                  // Using a more subtle X icon
                  Icons.close,
                  color: Colors.red.shade200,
                  size: 12,
                )
                    : Container(
                  height: 14,
                ),
                if (isCheckedIn && experience > 0)
                  Text(
                    '+$experience',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // 当天未签到红点提示
          if (isToday && !isCheckedIn)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
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