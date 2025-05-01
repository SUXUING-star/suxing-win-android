import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart'; // **导入 User 模型**
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import '../../../../../models/user/user_checkin.dart'; // 导入修改后的 CheckInStats
// import '../../../../../models/user/user_level.dart'; // <--- 已删除
import '../../../../../utils/device/device_utils.dart';
import '../calendar/calendar_view.dart';
import '../widget/checkin_rules_card.dart';
import '../progress/level_progress_card.dart'; // 指向 progress 目录
import '../widget/today_checkin_list.dart'; // 指向 widget 目录

class ResponsiveCheckInLayout extends StatelessWidget {
  // --- 接收的数据 ---
  final CheckInStats checkInStats;    // 签到统计 (精简后)
  final User currentUser;           // 当前用户信息 (包含等级经验)
  final Map<String, dynamic>? monthlyData; // 月度日历数据
  final int selectedYear;
  final int selectedMonth;
  final bool isCheckInLoading;      // 签到按钮加载状态
  final bool hasCheckedToday;       // 今天是否已签到
  final AnimationController animationController; // 粒子效果控制器
  final Function(int, int) onChangeMonth; // 月份切换回调
  final VoidCallback onCheckIn;           // 签到按钮回调
  final int missedDays;              // 本月漏签天数
  final int consecutiveMissedDays;   // 断签天数

  const ResponsiveCheckInLayout({
    super.key,
    required this.checkInStats,
    required this.currentUser, // **接收 currentUser**
    required this.monthlyData,
    required this.selectedYear,
    required this.selectedMonth,
    required this.isCheckInLoading,
    required this.hasCheckedToday,
    required this.animationController,
    required this.onChangeMonth,
    required this.onCheckIn,
    this.missedDays = 0,
    this.consecutiveMissedDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 判断设备类型和方向
    final isTablet = DeviceUtils.isTablet(context);
    final isDesktop = DeviceUtils.isDesktop;
    final isLandscape = DeviceUtils.isLandscape(context);

    // 根据不同布局渲染
    if (isDesktop || (isTablet && isLandscape)) {
      // 桌面或平板横屏 -> 水平布局
      return _buildHorizontalLayout(context);
    } else {
      // 手机或平板竖屏 -> 垂直布局
      return _buildVerticalLayout(context);
    }
  }

  // --- 水平布局 ---
  Widget _buildHorizontalLayout(BuildContext context) {
    // 动画延迟和间隔设置
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 150);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
        children: [
          // --- 左侧区域：日历 ---
          Expanded(
            flex: 3, // 日历区域占比较大
            child: SingleChildScrollView( // 允许日历内容滚动（如果需要）
              child: FadeInSlideUpItem( // 应用进入动画
                delay: initialDelay, // 左侧先入场
                child: CalendarView( // 日历组件
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  monthlyData: monthlyData,
                  onChangeMonth: onChangeMonth,
                  missedDays: missedDays, // 传递漏签天数给日历显示
                ),
              ),
            ),
          ),
          // --- 结束左侧区域 ---

          const SizedBox(width: 16), // 左右区域间距

          // --- 右侧区域：信息面板 ---
          Expanded(
            flex: 2, // 信息面板区域占比较小
            child: _buildRightPanel(context, initialDelay + stagger), // 构建右侧面板并传递动画延迟
          ),
          // --- 结束右侧区域 ---
        ],
      ),
    );
  }

  // --- 构建右侧信息面板 ---
  Widget _buildRightPanel(BuildContext context, Duration startDelay) {
    // 右侧面板内部组件的动画间隔
    const Duration internalStagger = Duration(milliseconds: 100);

    return Container(
      // 限制最大高度，防止在小屏幕上无限延伸
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - kToolbarHeight - 16, // 减去 AppBar 和一些边距
      ),
      child: SingleChildScrollView( // 允许右侧面板内容滚动
        child: Column(
          children: [
            // 1. 等级进度卡片
            FadeInSlideUpItem(
              delay: startDelay, // 使用传入的起始延迟
              child: LevelProgressCard( // 等级进度组件
                stats: checkInStats,       // 传递签到统计
                currentUser: currentUser,  // **传递当前用户信息**
                isLoading: isCheckInLoading, // 传递签到按钮状态
                hasCheckedToday: hasCheckedToday,
                animationController: animationController,
                onCheckIn: onCheckIn,
                missedDays: missedDays, // 这个卡片可能不需要显示漏签
                consecutiveMissedDays: consecutiveMissedDays, // 传递断签天数
              ),
            ),
            const SizedBox(height: 16), // 组件间距

            // 2. 签到统计概要
            FadeInSlideUpItem(
              delay: startDelay + internalStagger, // 错开动画
              child: _buildStatsSummary(context), // 构建统计概要
            ),
            const SizedBox(height: 16),

            // 3. 今日签到列表
            FadeInSlideUpItem(
              delay: startDelay + internalStagger * 2, // 再次错开
              child: TodayCheckInList(maxHeight: 200), // 今日签到列表，限制最大高度
            ),
            const SizedBox(height: 16),

            // 4. 签到规则卡片
            FadeInSlideUpItem(
              delay: startDelay + internalStagger * 3, // 最后入场
              child: CheckInRulesCard(), // 签到规则说明
            ),
          ],
        ),
      ),
    );
  }

  // --- 垂直布局 ---
  Widget _buildVerticalLayout(BuildContext context) {
    // 垂直布局的动画延迟和间隔
    const Duration initialDelay = Duration(milliseconds: 100);
    const Duration stagger = Duration(milliseconds: 100);

    return SingleChildScrollView( // 整体可滚动
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 组件宽度撑满
        children: [
          // 1. 等级进度卡片
          FadeInSlideUpItem(
            delay: initialDelay,
            child: LevelProgressCard(
              stats: checkInStats,
              currentUser: currentUser, // **传递 currentUser**
              isLoading: isCheckInLoading,
              hasCheckedToday: hasCheckedToday,
              animationController: animationController,
              onCheckIn: onCheckIn,
              missedDays: missedDays,
              consecutiveMissedDays: consecutiveMissedDays,
            ),
          ),
          const SizedBox(height: 16),

          // 2. 签到统计概要
          FadeInSlideUpItem(
            delay: initialDelay + stagger,
            child: _buildStatsSummary(context),
          ),
          const SizedBox(height: 16),

          // 3. 今日签到列表
          FadeInSlideUpItem(
            delay: initialDelay + stagger * 2,
            child: TodayCheckInList(), // 不限制高度，让它自适应
          ),
          const SizedBox(height: 16),

          // 4. 日历视图
          FadeInSlideUpItem(
            delay: initialDelay + stagger * 3,
            child: CalendarView(
              selectedYear: selectedYear,
              selectedMonth: selectedMonth,
              monthlyData: monthlyData,
              onChangeMonth: onChangeMonth,
              missedDays: missedDays,
            ),
          ),
          const SizedBox(height: 16),

          // 5. 签到规则卡片
          FadeInSlideUpItem(
            delay: initialDelay + stagger * 4,
            child: CheckInRulesCard(),
          ),
          const SizedBox(height: 16), // 底部留白
        ],
      ),
    );
  }

  // --- 构建签到统计概要 ---
  Widget _buildStatsSummary(BuildContext context) {
    final theme = Theme.of(context);
    // 从 checkInStats 获取数据
    final continuousDays = checkInStats.continuousDays;
    final totalCheckIns = checkInStats.totalCheckIns;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0), // 调整内边距
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 累计签到
            Expanded( // 使用 Expanded 确保均匀分布且文本可换行
              child: _buildStatItem(
                context: context,
                icon: Icons.calendar_today_outlined, // 换个图标
                title: '累计签到',
                value: '$totalCheckIns 天',
                color: theme.textTheme.bodySmall?.color ?? Colors.grey.shade700, // 跟随文本颜色
              ),
            ),
            // 垂直分割线
            Container(height: 50, width: 1, color: Colors.grey.shade300),
            // 连续签到
            Expanded(
              child: _buildStatItem(
                context: context,
                icon: Icons.local_fire_department_outlined, // 换个图标
                title: '连续签到',
                value: '$continuousDays 天',
                color: continuousDays > 0 ? Colors.orange.shade700 : (theme.textTheme.bodySmall?.color ?? Colors.grey.shade700), // 连续签到用橙色
                isBold: continuousDays > 0, // 连续签到时加粗
              ),
            ),
            // 断签记录 (仅当断签天数 > 1 时显示)
            if (consecutiveMissedDays > 1) ...[
              Container(height: 50, width: 1, color: Colors.grey.shade300),
              Expanded(
                child: _buildStatItem(
                  context: context,
                  icon: Icons.link_off_outlined, // 换个图标
                  title: '已断签',
                  value: '$consecutiveMissedDays 天',
                  color: Colors.red.shade400, // 断签用红色
                  isBold: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- 构建单个统计项 ---
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
        Icon(icon, color: color, size: 24), // 图标稍小
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13, // 字体稍小
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, // 值字体稍大
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600, // 调整粗细
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}