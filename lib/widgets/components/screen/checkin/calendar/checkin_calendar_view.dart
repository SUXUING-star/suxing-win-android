// lib/widgets/components/screen/checkin/calendar/checkin_calendar_view.dart

/// 该文件定义了 CheckInCalendarView 组件，用于显示用户的签到日历。
/// CheckInCalendarView 展示特定月份的签到情况和漏签天数，并提供月份切换功能。
library;

import 'package:flutter/material.dart'; // Flutter UI 组件所需
import 'package:suxingchahui/models/user/check_in/monthly_checkin_report.dart'; // 月度签到报告模型所需
import 'package:suxingchahui/models/user/check_in/daily_checkin_info.dart'; // 每日签到信息模型所需
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 加载组件所需
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法所需

/// `CheckInCalendarView` 类：显示签到日历的 StatelessWidget。
///
/// 该组件负责渲染指定年份和月份的签到日历，包括每日签到状态和漏签天数。
class CheckInCalendarView extends StatelessWidget {
  final int selectedYear; // 当前选中的年份
  final int selectedMonth; // 当前选中的月份
  final MonthlyCheckInReport? monthlyData; // 月度签到数据报告
  final Function(int, int) onChangeMonth; // 月份切换回调
  final int missedDays; // 本月漏签天数

  /// 构造函数。
  ///
  /// [selectedYear]：当前选中的年份。
  /// [selectedMonth]：当前选中的月份。
  /// [monthlyData]：月度签到数据。
  /// [onChangeMonth]：月份切换回调。
  /// [missedDays]：本月漏签天数。
  const CheckInCalendarView({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.monthlyData,
    required this.onChangeMonth,
    this.missedDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 获取当前主题
    final now = DateTime.now(); // 获取当前时间

    // 计算是否可以再往后翻 (去到下个月)
    final bool isNextMonthDisabled =
        selectedYear == now.year && selectedMonth == now.month;

    // 计算允许的最早月份
    int limitYear = now.year;
    int limitMonth = now.month - 1;
    if (limitMonth == 0) {
      // 处理跨年
      limitMonth = 12;
      limitYear--;
    }

    // 计算是否可以再往前翻 (去到上上个月)
    final bool isPrevMonthDisabled =
        selectedYear == limitYear && selectedMonth == limitMonth;

    // 确定显示的漏签天数
    final int displayMissedDays =
        (selectedYear == now.year && selectedMonth == now.month)
            ? missedDays
            : 0; // 其他月份不显示漏签

    return Card(
      elevation: 2, // 阴影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // 圆角边框
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 内边距
        child: Column(
          mainAxisSize: MainAxisSize.min, // 最小化主轴尺寸
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
                      if (displayMissedDays > 0) // 漏签天数大于0时显示
                        Container(
                          margin: const EdgeInsets.only(right: 8), // 右外边距
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2), // 内边距
                          decoration: BoxDecoration(
                            color: Colors.red.withSafeOpacity(0.1), // 背景色
                            borderRadius: BorderRadius.circular(12), // 圆角
                            border: Border.all(
                                color: Colors.red.withSafeOpacity(0.3)), // 边框
                          ),
                          child: Text(
                            '漏签 $displayMissedDays 天', // 显示漏签天数
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
                              icon: const Icon(Icons.chevron_left), // 左箭头图标
                              onPressed: isPrevMonthDisabled // 根据状态禁用按钮
                                  ? null
                                  : () {
                                      int newMonth = selectedMonth - 1; // 计算新月份
                                      int newYear = selectedYear; // 新年份
                                      if (newMonth < 1) {
                                        // 处理月份小于1的情况
                                        newMonth = 12;
                                        newYear--;
                                      }
                                      onChangeMonth(
                                          newYear, newMonth); // 触发月份切换回调
                                    },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 22,
                              splashRadius: 18,
                              tooltip: '上个月', // 工具提示
                            ),
                            const SizedBox(width: 4), // 间距
                            Flexible(
                              child: Text(
                                '$selectedYear年$selectedMonth月', // 显示年份和月份
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis, // 文本溢出处理
                                textAlign: TextAlign.center, // 文本居中
                              ),
                            ),
                            const SizedBox(width: 4), // 间距
                            IconButton(
                              icon: const Icon(Icons.chevron_right), // 右箭头图标
                              onPressed: isNextMonthDisabled // 根据状态禁用按钮
                                  ? null
                                  : () {
                                      int newMonth = selectedMonth + 1; // 计算新月份
                                      int newYear = selectedYear; // 新年份
                                      if (newMonth > 12) {
                                        // 处理月份大于12的情况
                                        newMonth = 1;
                                        newYear++;
                                      }
                                      onChangeMonth(
                                          newYear, newMonth); // 触发月份切换回调
                                    },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 22,
                              splashRadius: 18,
                              tooltip: '下个月', // 工具提示
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // 垂直间距
            monthlyData == null // 数据加载中显示 Loading
                ? const LoadingWidget()
                : _buildCalendarGrid(context), // 构建日历网格
          ],
        ),
      ),
    );
  }

  /// 构建日历网格。
  ///
  /// [context]：Build 上下文。
  /// 返回一个包含周几标题和日期单元格的 GridView。
  Widget _buildCalendarGrid(BuildContext context) {
    final weekdayTitles = ['一', '二', '三', '四', '五', '六', '日']; // 周几标题
    final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1); // 月份第一天
    final int firstWeekdayIndex =
        (firstDayOfMonth.weekday - 1) % 7; // 月份第一天是周几的索引
    final daysInMonth =
        DateTime(selectedYear, selectedMonth + 1, 0).day; // 当前月份天数

    final Map<int, DailyCheckInInfo> checkedInDaysData = {}; // 已签到日期数据
    if (monthlyData != null) {
      for (final dayInfo in monthlyData!.days) {
        if (dayInfo.checkedIn) {
          checkedInDaysData[dayInfo.day] = dayInfo; // 存储已签到日期信息
        }
      }
    }

    final now = DateTime.now(); // 当前时间
    final Set<int> missedCheckInDaysThisMonthView = {}; // 当前视图的漏签日期
    if (selectedYear == now.year && selectedMonth == now.month) {
      for (int day = 1; day < now.day; day++) {
        if (!checkedInDaysData.containsKey(day)) {
          missedCheckInDaysThisMonthView.add(day); // 添加漏签日期
        }
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdayTitles.map((title) {
            // 遍历周几标题
            final isWeekend = title == '六' || title == '日'; // 判断是否为周末
            return Expanded(
              child: Center(
                child: Text(
                  title, // 周几标题
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isWeekend
                        ? Colors.red.shade300
                        : Colors.grey.shade600, // 周末显示不同颜色
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(height: 10, thickness: 0.5), // 分割线
        GridView.builder(
          shrinkWrap: true, // 根据内容收缩高度
          physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 每行7个单元格
            childAspectRatio: 1 / 1.4, // 单元格宽高比
            mainAxisSpacing: 4, // 主轴间距
            crossAxisSpacing: 4, // 交叉轴间距
          ),
          itemCount: firstWeekdayIndex + daysInMonth, // 网格总数量
          itemBuilder: (context, index) {
            final dayNumber = index - firstWeekdayIndex + 1; // 计算日期数字

            if (index < firstWeekdayIndex) {
              return Container(); // 填充月份前的空白单元格
            }

            final date =
                DateTime(selectedYear, selectedMonth, dayNumber); // 完整日期
            final isToday = now.year == selectedYear &&
                now.month == selectedMonth &&
                now.day == dayNumber; // 判断是否为今天
            final isWeekend = date.weekday >= 6; // 判断是否为周末
            final DailyCheckInInfo? dayCheckInInfo =
                checkedInDaysData[dayNumber]; // 获取每日签到信息
            final bool isCheckedIn =
                dayCheckInInfo?.checkedIn ?? false; // 判断是否已签到
            final int experience = dayCheckInInfo?.exp ?? 0; // 获取经验值
            final bool isMarkedAsMissed =
                missedCheckInDaysThisMonthView.contains(dayNumber); // 判断是否标记为漏签

            return _buildDayCell(
              context: context,
              day: dayNumber,
              isToday: isToday,
              isWeekend: isWeekend,
              isCheckedIn: isCheckedIn,
              isMissedCheckIn: isMarkedAsMissed, // 传递漏签标记
              experience: experience,
            );
          },
        ),
      ],
    );
  }

  /// 构建单个日期单元格。
  ///
  /// [context]：Build 上下文。
  /// [day]：日期数字。
  /// [isToday]：是否为今天。
  /// [isWeekend]：是否为周末。
  /// [isCheckedIn]：是否已签到。
  /// [isMissedCheckIn]：是否标记为漏签样式。
  /// [experience]：获得的经验值。
  /// 返回一个表示日期单元格的 Widget。
  Widget _buildDayCell({
    required BuildContext context,
    required int day,
    required bool isToday,
    required bool isWeekend,
    required bool isCheckedIn,
    required bool isMissedCheckIn,
    required int experience,
  }) {
    final theme = Theme.of(context); // 获取当前主题
    Color textColor = Colors.black87; // 默认文本颜色
    Color bgColor = Colors.transparent; // 默认背景颜色
    Color borderColor = Colors.transparent; // 默认边框颜色
    double borderWidth = 0; // 默认边框宽度
    FontWeight fontWeight = FontWeight.normal; // 默认字体粗细

    if (isWeekend && !isToday) {
      // 周末且非今天
      textColor = Colors.red.shade300; // 设置文本颜色
    }
    if (isMissedCheckIn) {
      // 标记为漏签
      textColor = Colors.grey.shade500; // 设置文本颜色
      bgColor = Colors.red.withSafeOpacity(0.05); // 设置背景颜色
      borderColor = Colors.red.withSafeOpacity(0.1); // 设置边框颜色
      borderWidth = 0.5; // 设置边框宽度
    }
    if (isToday) {
      // 今天
      textColor = theme.primaryColor; // 设置文本颜色
      borderColor = theme.primaryColor; // 设置边框颜色
      borderWidth = 1.5; // 设置边框宽度
      fontWeight = FontWeight.bold; // 设置字体加粗
    }

    const double iconSize = 12.0; // 图标大小
    const double experienceFontSize = 9.0; // 经验值字体大小

    return Container(
      decoration: BoxDecoration(
        color: bgColor, // 背景颜色
        border: Border.all(color: borderColor, width: borderWidth), // 边框
        borderRadius: BorderRadius.circular(4), // 圆角
      ),
      child: Stack(
        alignment: Alignment.center, // 居中对齐
        children: [
          Column(
            mainAxisSize: MainAxisSize.min, // 最小化主轴尺寸
            mainAxisAlignment: MainAxisAlignment.center, // 主轴居中
            crossAxisAlignment: CrossAxisAlignment.center, // 交叉轴居中
            children: [
              Text(
                day.toString(), // 日期数字
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: fontWeight,
                  color: textColor,
                ),
                textAlign: TextAlign.center, // 文本居中
                maxLines: 1, // 最大行数
              ),
              SizedBox(
                height: iconSize + 4,
                child: isCheckedIn // 已签到显示打勾图标
                    ? Icon(Icons.check_circle_outline,
                        color: theme.primaryColor.withSafeOpacity(0.85),
                        size: iconSize)
                    : isMissedCheckIn // 漏签显示关闭图标
                        ? Icon(Icons.close,
                            color: Colors.red.shade200, size: iconSize)
                        : null, // 其他情况不显示图标
              ),
              SizedBox(
                height: isCheckedIn && experience > 0
                    ? experienceFontSize + 2
                    : 0, // 经验值高度
                child: isCheckedIn && experience > 0 // 已签到且有经验值时显示
                    ? Text(
                        '+$experience', // 经验值
                        style: TextStyle(
                          fontSize: experienceFontSize,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center, // 文本居中
                        maxLines: 1, // 最大行数
                      )
                    : null,
              ),
            ],
          ),
          if (isToday && !isCheckedIn) // 今天且未签到时显示红点
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle, // 圆形红点
                ),
              ),
            ),
        ],
      ),
    );
  }
}
