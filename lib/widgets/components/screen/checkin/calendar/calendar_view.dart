// lib/widgets/components/screen/checkin/calendar/calendar_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';

class CalendarView extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final Map<String, dynamic>? monthlyData;
  final Function(int, int) onChangeMonth;
  final int missedDays; // 从父级传入的漏签天数 (可选)

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

    // --- 精确计算当前月份视图的漏签天数 ---
    int calculatedMissedDays = 0;
    if (selectedYear == now.year && selectedMonth == now.month) {
      if (monthlyData != null) {
        final List<dynamic> rawDays = monthlyData?['days'] as List? ?? [];
        final int daysInCurrentMonth =
            DateTime(selectedYear, selectedMonth + 1, 0).day;
        // 注意：这里调用的是 _calculateMissedDaysForCurrentMonth
        final Set<int> missedCheckInDays = _calculateMissedDaysForCurrentMonth(
            rawDays, daysInCurrentMonth, selectedYear, selectedMonth);
        calculatedMissedDays = missedCheckInDays.length;
      } else {
        calculatedMissedDays = missedDays; // 数据加载中或失败时，使用传入值
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 卡片内部整体边距
        child: Column(
          // 卡片内的主要 Column
          mainAxisSize: MainAxisSize.min, // 高度根据内容自适应
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 日历标题和月份选择 (顶部 Header) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center, // 确保垂直居中对齐
              children: [
                // "签到日历" 标题
                Text(
                  '签到日历',
                  style: theme.textTheme.titleSmall ??
                      const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // 右侧控制区域 (漏签提示 + 月份切换)
                Expanded(
                  // 占据剩余空间，将右侧内容推到最右边
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end, // 右对齐
                    crossAxisAlignment: CrossAxisAlignment.center, // 确保垂直居中
                    children: [
                      // 漏签天数提示 (仅当前月份显示)
                      if (selectedYear == now.year &&
                          selectedMonth == now.month &&
                          calculatedMissedDays > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8), // 与切换按钮的间距
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withSafeOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withSafeOpacity(0.3)),
                          ),
                          child: Text(
                            '漏签 $calculatedMissedDays 天',
                            style: TextStyle(
                              fontSize: 11, // 字体可以小一点
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      // 月份切换按钮和年月显示 (用 Flexible 包裹防止宽度溢出)
                      Flexible(
                        // 允许这部分在空间不足时收缩
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 只占据必要宽度
                          mainAxisAlignment: MainAxisAlignment.end, // 内部元素也靠右
                          children: [
                            // 左箭头按钮
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
                              constraints:
                                  const BoxConstraints(), // 移除默认的大 padding
                              iconSize: 22,
                              splashRadius: 18, // 控制点击波纹范围
                              tooltip: '上个月', // 增加可访问性
                            ),
                            const SizedBox(width: 4), // 按钮和文字间距
                            // 年月显示 (用 Flexible 允许文本溢出时显示省略号)
                            Flexible(
                              child: Text(
                                '$selectedYear年$selectedMonth月',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis, // 超长时显示 ...
                                textAlign: TextAlign.center, // 居中显示
                              ),
                            ),
                            const SizedBox(width: 4), // 文字和按钮间距
                            // 右箭头按钮
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
            // --- Header 结束 ---

            const SizedBox(height: 12), // Header 和星期标题之间的间距

            // --- 日历网格部分 (Loading 或 Grid) ---
            monthlyData == null
                ? LoadingWidget.inline()
                : _buildCalendarGrid(context), // 显示日历网格
            // --- 日历网格部分结束 ---
          ],
        ),
      ),
    );
  }

  // --- 构建日历网格 (包括星期标题和日期格子) ---
  Widget _buildCalendarGrid(BuildContext context) {
    //final theme = Theme.of(context);

    // 星期标题
    final weekdayTitles = ['一', '二', '三', '四', '五', '六', '日'];

    // 计算日期相关信息
    final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
    // Dart 的 weekday: 周一=1, 周日=7. 调整为 周一=0, 周日=6
    final int firstWeekdayIndex = (firstDayOfMonth.weekday - 1) % 7;
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    // --- 安全地解析签到数据 ---
    final List<dynamic> rawDays = monthlyData?['days'] as List? ?? [];
    final Map<int, Map<String, dynamic>> checkedInDaysData =
        {}; // 存储完整签到数据 {day: data}
    final Set<int> checkedInDayNumbers = {}; // 只存储签到的日期数字 {day1, day2, ...}
    for (final rawDay in rawDays) {
      if (rawDay is! Map) continue; // 跳过无效数据
      final Map<String, dynamic> dayData = Map<String, dynamic>.from(rawDay);
      // 必须是已签到 ('checkedIn' == true) 且包含 'day' 字段
      if (dayData['checkedIn'] == true && dayData.containsKey('day')) {
        int? dayOfMonth =
            _parseDayOfMonth(dayData['day'], daysInMonth); // 使用辅助函数解析日期
        if (dayOfMonth != null) {
          // 确保日期有效
          checkedInDaysData[dayOfMonth] = dayData;
          checkedInDayNumbers.add(dayOfMonth);
        }
      }
    }
    // --- 数据解析结束 ---

    // --- 计算当前月份视图的漏签日期 ---
    final now = DateTime.now();
    final Set<int> missedCheckInDays = {};
    // 仅当查看的是当前实际月份时才计算漏签
    if (selectedYear == now.year && selectedMonth == now.month) {
      final int currentDay = now.day;
      // 遍历今天之前的日期
      for (int day = 1; day < currentDay; day++) {
        // 如果过去的某一天不在已签到列表里，则视为漏签
        if (!checkedInDayNumbers.contains(day)) {
          missedCheckInDays.add(day);
        }
      }
    }
    // --- 漏签计算结束 ---

    return Column(
      // 包含星期标题和 GridView
      children: [
        // --- 星期标题行 ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // 均匀分布
          children: weekdayTitles.map((title) {
            final isWeekend = title == '六' || title == '日';
            return Expanded(
              // 每个标题占据相等宽度
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // 星期标题字体可以小一点
                    color: isWeekend
                        ? Colors.red.shade300
                        : Colors.grey.shade600, // 周末红色
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // --- 星期标题行结束 ---

        const Divider(height: 10, thickness: 0.5), // 星期标题和日期网格之间的分割线

        // --- 日期网格 ---
        GridView.builder(
          shrinkWrap: true, // 高度根据内容自适应 (重要!)
          physics:
              const NeverScrollableScrollPhysics(), // 日历本身不可滚动 (由外部 SingleChildScrollView 控制)

          // --- !!! 核心修改：解决单元格垂直溢出和可能的水平溢出 !!! ---
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 每行7个单元格
            // childAspectRatio: 宽度 / 高度
            // 值越小，单元格越高。增加高度以容纳打勾和经验值。
            // childAspectRatio: 1.0, // 原始值 (正方形，内容会溢出)
            // childAspectRatio: 1 / 1.15, // 之前的尝试
            childAspectRatio: 1 / 1.4, // <--- 显著增加高度 (尝试这个值)
            // 如果 1/1.25 仍然溢出，可以试试 1/1.3
            // childAspectRatio: 1 / 1.3, // <--- 更高的高度
            mainAxisSpacing: 4, // 单元格之间的垂直间距
            crossAxisSpacing: 4, // 单元格之间的水平间距
          ),
          // --- !!! 核心修改结束 !!! ---

          itemCount: firstWeekdayIndex + daysInMonth, // 总格子数 = 月初空白格 + 本月天数
          itemBuilder: (context, index) {
            // 计算当前格子的日期
            final day = index - firstWeekdayIndex + 1;

            // 处理月初的空白格子
            if (index < firstWeekdayIndex) {
              return Container(); // 返回空容器
            }

            // --- 获取当前日期的状态 ---
            final date = DateTime(selectedYear, selectedMonth, day);
            final isToday = now.year == selectedYear &&
                now.month == selectedMonth &&
                now.day == day;
            // isPastDate 现在只用于视觉效果（比如漏签样式），漏签逻辑使用 missedCheckInDays 集合
            // final isPastDate = date.isBefore(DateTime(now.year, now.month, now.day));
            final isWeekend = date.weekday >= 6; // 周六或周日
            final isCheckedIn = checkedInDayNumbers.contains(day);
            final isMissedCheckIn =
                missedCheckInDays.contains(day); // 是否是计算出的漏签日期

            // 安全地获取经验值
            int experience = 0;
            if (isCheckedIn && checkedInDaysData.containsKey(day)) {
              final dayData = checkedInDaysData[day];
              final expValue = dayData?['experience'];
              if (expValue is int) {
                experience = expValue;
              } else if (expValue is num) {
                experience = expValue.toInt();
              } else if (expValue is String) {
                experience = int.tryParse(expValue) ?? 0;
              }
            }
            // --- 状态获取结束 ---

            // --- 构建并返回单个日期单元格 ---
            return _buildDayCell(
              context: context,
              day: day,
              isToday: isToday,
              isWeekend: isWeekend,
              isCheckedIn: isCheckedIn,
              isMissedCheckIn: isMissedCheckIn,
              experience: experience,
            );
            // --- 单元格构建结束 ---
          },
        ),
        // --- 日期网格结束 ---
      ],
    );
  }

  // --- 构建单个日期单元格 ---
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

    // --- 根据状态确定样式 ---
    Color textColor = Colors.black87; // 默认文字颜色
    Color bgColor = Colors.transparent; // 默认背景色
    Color borderColor = Colors.transparent; // 默认边框色
    double borderWidth = 0; // 默认边框宽度
    FontWeight fontWeight = FontWeight.normal; // 默认字体粗细

    // 周末样式 (如果不是今天)
    if (isWeekend && !isToday) {
      textColor = Colors.red.shade300;
    }
    // 漏签样式 (覆盖周末文字颜色)
    if (isMissedCheckIn) {
      textColor = Colors.grey.shade500; // 漏签文字颜色变灰
      bgColor = Colors.red.withSafeOpacity(0.05); // 淡红色背景
      borderColor = Colors.red.withSafeOpacity(0.1); // 淡红色边框
      borderWidth = 0.5;
    }
    // 今天样式 (覆盖其他样式)
    if (isToday) {
      textColor = theme.primaryColor; // 今天文字用主题色
      borderColor = theme.primaryColor; // 今天边框用主题色
      borderWidth = 1.5; // 今天边框加粗
      fontWeight = FontWeight.bold; // 今天字体加粗
    }
    // 已签到但不是今天的，可以考虑加个淡背景色，但目前保持透明
    // if (isCheckedIn && !isToday) {
    //   bgColor = theme.primaryColor.withSafeOpacity(0.05);
    // }
    // --- 样式确定结束 ---

    // --- 定义内部元素尺寸 ---
    const double iconSize = 12.0; // 图标大小
    const double experienceFontSize = 9.0; // 经验值字体大小
    // --- 尺寸定义结束 ---

    return Container(
      // 单元格容器
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(4), // 轻微圆角
      ),
      child: Stack(
        // 使用 Stack 方便放置“今天”的小红点
        alignment: Alignment.center, // Stack 内元素默认居中
        children: [
          // --- 主要内容：日期、图标、经验值 ---
          Column(
            mainAxisSize: MainAxisSize.min, // Column 高度自适应
            mainAxisAlignment: MainAxisAlignment.center, // 垂直居中对齐 Column 内容
            crossAxisAlignment:
                CrossAxisAlignment.center, // <<< 水平居中对齐 Column 内容 (防止数字飞出)
            children: [
              // --- 日期数字 ---
              Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14, // 日期字体大小
                  fontWeight: fontWeight,
                  color: textColor,
                ),
                textAlign: TextAlign.center, // <<< 确保文本本身居中 (防止数字飞出)
                maxLines: 1, // 最多一行
              ),
              // --- 图标区域 (打勾或关闭) ---
              // 使用 SizedBox 控制图标区域的高度，即使没有图标也占位
              SizedBox(
                // 高度 = 图标大小 + 上下一点点间距
                height: iconSize + 4,
                child: isCheckedIn
                    // 已签到图标
                    ? Icon(Icons.check_circle_outline,
                        color: theme.primaryColor.withSafeOpacity(0.85),
                        size: iconSize)
                    : isMissedCheckIn
                        // 漏签图标
                        ? Icon(Icons.close,
                            color: Colors.red.shade200, size: iconSize)
                        // 既未签到也未漏签（未来日期或今天未签），显示空 SizedBox 占位
                        : null,
              ),
              // --- 经验值区域 ---
              // 仅在已签到且经验值 > 0 时显示
              SizedBox(
                // 高度 = 字体大小 + 一点点间距，如果经验值为0则高度为0
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
                        textAlign: TextAlign.center, // <<< 确保经验值也居中
                        maxLines: 1,
                      )
                    // 不显示经验值时为 null
                    : null,
              ),
            ],
          ),
          // --- “今天”的小红点提示 ---
          // 仅在是今天且尚未签到时显示
          if (isToday && !isCheckedIn)
            Positioned(
              // 放置在右上角
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
          // --- 小红点结束 ---
        ],
      ),
    );
  }

  // --- 辅助函数：安全地从各种格式解析日期 ---
  int? _parseDayOfMonth(dynamic dayValue, int daysInMonth) {
    int? dayOfMonth;
    if (dayValue is int) {
      dayOfMonth = dayValue;
    } else if (dayValue is String) {
      // 优先尝试直接解析数字字符串
      dayOfMonth = int.tryParse(dayValue);
      // 如果失败，且包含 '-'，尝试按日期格式解析
      if (dayOfMonth == null && dayValue.contains('-')) {
        try {
          // 尝试通用格式 'yyyy-MM-dd' (更健壮)
          final date =
              DateFormat('yyyy-MM-dd').parse(dayValue, true); // 使用 intl 包
          dayOfMonth = date.day;
          // 可选：验证解析出的年月是否与当前日历匹配
          // if (date.year != selectedYear || date.month != selectedMonth) return null;
        } catch (e) {
          // 如果 'yyyy-MM-dd' 失败，尝试提取最后的数字部分 (兼容 'MM-dd' 或 'dd')
          //print(
          //   'Warning: Parsing date string "$dayValue" failed, attempting fallback: $e');
          final parts = dayValue.split('-');
          if (parts.isNotEmpty) {
            dayOfMonth = int.tryParse(parts.last);
          }
        }
      }
    }

    // 最终验证：确保日期在有效范围内 (1 到 daysInMonth)
    if (dayOfMonth != null && dayOfMonth > 0 && dayOfMonth <= daysInMonth) {
      return dayOfMonth;
    }
    // print(
    //     'Warning: Invalid day value parsed or out of range: $dayValue -> $dayOfMonth');
    return null; // 返回 null 表示无效
  }

  // --- 辅助函数：计算【当前月份】视图下的漏签日期集合 ---
  // （这个函数逻辑基本没问题，保持不变）
  Set<int> _calculateMissedDaysForCurrentMonth(
      List<dynamic> rawDays, int daysInMonth, int year, int month) {
    final Set<int> missedDays = {};
    final Set<int> checkedDays = {};
    final now = DateTime.now();

    // 如果计算的年月不是当前实际年月，直接返回空集合
    if (year != now.year || month != now.month) {
      return {};
    }

    // 收集本月所有已签到的日期
    for (final rawDay in rawDays) {
      if (rawDay is! Map) continue;
      final Map<String, dynamic> dayData = Map<String, dynamic>.from(rawDay);
      if (dayData['checkedIn'] == true && dayData.containsKey('day')) {
        int? dayOfMonth = _parseDayOfMonth(dayData['day'], daysInMonth);
        if (dayOfMonth != null) {
          checkedDays.add(dayOfMonth);
        }
      }
    }

    // 计算漏签日期：遍历今天之前的日期，如果不在 checkedDays 里，就是漏签
    final currentDayOfMonth = now.day;
    for (int day = 1; day < currentDayOfMonth; day++) {
      if (!checkedDays.contains(day)) {
        missedDays.add(day);
      }
    }
    return missedDays;
  }
}
