// lib/screens/check_in/check_in_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../services/main/user/user_checkin_service.dart';
import '../../services/main/user/user_level_service.dart';
import '../../models/user/user_checkin.dart';
import '../../models/user/user_level.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/components/screen/checkin/layout/responsive_checkin_layout.dart';
import '../../widgets/components/screen/checkin/effects/particle_effect.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/common/loading_widget.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with TickerProviderStateMixin {
  // 状态变量
  bool _isLoading = true;
  bool _checkInLoading = false;
  bool _isCheckedToday = false;
  CheckInStats? _checkInStats;
  UserLevel? _userLevel;
  Map<String, dynamic>? _monthlyData;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _errorMessage;
  int _missedDays = 0; // 添加漏签天数变量
  int _consecutiveMissedDays = 0; // 添加断签天数变量（上次签到至今的天数）

  // 动画控制器
  late AnimationController _particleController;

  // 服务实例
  late UserCheckInService _checkInService;
  late UserLevelService _levelService;

  @override
  void initState() {
    super.initState();
    _checkInService = Provider.of<UserCheckInService>(context, listen: false);
    _levelService = Provider.of<UserLevelService>(context, listen: false);

    // 初始化动画控制器
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 加载数据
    _loadData();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  // 加载签到数据
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 初始化服务
      await _checkInService.initialize();

      // 2. 获取签到状态
      final stats = await _checkInService.getCheckInStats();

      // 3. 获取用户等级
      final userLevel = await _levelService.getUserLevel();

      // 4. 获取月度签到数据
      final monthlyData = await _checkInService.getMonthlyCheckInData(
        year: _selectedYear,
        month: _selectedMonth,
      );

      // 5. 计算漏签天数（本月未签到的总天数）
      final missedDays = await _calculateMissedDays(monthlyData);

      // 6. Calculate consecutive missed days (days since last check-in)
      final consecutiveMissedDays = await _checkInService.calculateConsecutiveMissedDays();
      print(consecutiveMissedDays);
      if (mounted) {
        setState(() {
          _checkInStats = stats;
          _userLevel = userLevel;
          _isCheckedToday = stats.hasCheckedToday;
          _monthlyData = monthlyData;
          _missedDays = missedDays; // 设置漏签天数
          _consecutiveMissedDays = consecutiveMissedDays; // 设置断签天数
          _isLoading = false;
        });
      }
    } catch (e) {
      print('签到数据加载失败: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '签到数据加载失败: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // 计算漏签天数
  Future<int> _calculateMissedDays(Map<String, dynamic>? monthlyData) async {
    if (monthlyData == null) return 0;

    // 只计算当前月份的漏签
    final now = DateTime.now();
    if (_selectedYear != now.year || _selectedMonth != now.month) {
      return 0;
    }

    try {
      // 从月度数据中提取已签到日期
      final List<dynamic> rawDays = monthlyData['days'] as List? ?? [];
      final Set<int> checkedDays = {};

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

          if (dayOfMonth != null) {
            checkedDays.add(dayOfMonth);
          }
        }
      }

      // 计算漏签天数（从1号到昨天）
      final currentDay = now.day;
      int missedDays = 0;
      for (int day = 1; day < currentDay; day++) {
        if (!checkedDays.contains(day)) {
          missedDays++;
        }
      }

      return missedDays;
    } catch (e) {
      print('计算漏签天数失败: $e');
      return 0;
    }
  }

  // 处理签到事件
  Future<void> _handleCheckIn() async {
    if (_isCheckedToday || _checkInLoading) return;

    setState(() {
      _checkInLoading = true;
    });

    try {
      // 执行签到
      final result = await _checkInService.performCheckIn();

      // 播放粒子效果
      if (mounted) {
        _particleController.reset();
        _particleController.forward();
      }

      // 重新加载签到数据
      await _loadData();

      // 获取升级信息 (可选)
      if (mounted) {
        await _levelService.getUserLevel(forceRefresh: true);
      }

      // 显示签到成功提示
      if (mounted) {
        _showCheckInSuccess(result);
      }
    } catch (e) {
      print('签到失败: $e');
      if (mounted) {
        final String errorMessage ='签到失败: ${e.toString().replaceAll('Exception: ', '')}';
        AppSnackBar.showError(context,errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkInLoading = false;
        });
      }
    }
  }

  // 显示签到成功对话框
  void _showCheckInSuccess(Map<String, dynamic> result) {
    // 安全地获取经验值
    int expGained = 0;
    if (result.containsKey('experienceGained')) {
      if (result['experienceGained'] is int) {
        expGained = result['experienceGained'];
      } else if (result['experienceGained'] != null) {
        expGained = int.tryParse(result['experienceGained'].toString()) ?? 0;
      }
    }
    final int consecutiveDays = result['consecutiveCheckIn'] ?? 1;

    final String message = '恭喜您完成今日签到！\n'
        '获得 +$expGained 经验值\n'
        '当前连续签到: $consecutiveDays 天';

    // 创建成功对话框
    CustomConfirmDialog.show(
      context: context,
      title: '签到成功！🎉', // 可以加点 emoji
      message: message, // 使用上面构建的消息字符串
      iconData: Icons.check_circle_outline, // 使用成功图标
      iconColor: Colors.green, // 设置图标颜色为绿色
      confirmButtonText: '知道了', // 将确认按钮文本改为更符合场景的
      confirmButtonColor: Theme.of(context).primaryColor, // 确认按钮颜色使用主题色
      onConfirm: () async {
      },
      barrierDismissible: true, // 允许点击外部关闭对话框

    );
  }

  // 改变月份处理
  void _handleChangeMonth(int year, int month) {
    setState(() {
      _selectedYear = year;
      _selectedMonth = month;
      _monthlyData = null; // 清除旧数据
      // 重置漏签天数（不是当前月不显示）
      if (year != DateTime.now().year || month != DateTime.now().month) {
        _missedDays = 0;
      }
    });

    // 加载新月份数据
    _checkInService.getMonthlyCheckInData(
      year: year,
      month: month,
    ).then((data) {
      if (mounted) {
        setState(() {
          _monthlyData = data;

          // 如果是当前月份，重新计算漏签天数
          if (year == DateTime.now().year && month == DateTime.now().month) {
            _calculateMissedDays(data).then((missedDays) {
              if (mounted) {
                setState(() {
                  _missedDays = missedDays;
                });
              }
            });
          }
        });
      }
    }).catchError((e) {
      print('获取月度签到数据失败: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '每日签到',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [

          // 处理加载和错误状态
          if (_isLoading)
            LoadingWidget.fullScreen(message: '正在加载签到数据...'),

          if (_errorMessage != null)
            InlineErrorWidget(
              errorMessage: _errorMessage!,
              onRetry: _loadData,
            ),

          // 成功状态下显示响应式布局
          if (!_isLoading && _errorMessage == null)
            ResponsiveCheckInLayout(
              checkInStats: _checkInStats,
              userLevel: _userLevel,
              monthlyData: _monthlyData,
              selectedYear: _selectedYear,
              selectedMonth: _selectedMonth,
              isLoading: _isLoading,
              isCheckInLoading: _checkInLoading,
              hasCheckedToday: _isCheckedToday,
              animationController: _particleController,
              onChangeMonth: _handleChangeMonth,
              onCheckIn: _handleCheckIn,
              missedDays: _missedDays, // 漏签天数
              consecutiveMissedDays: _consecutiveMissedDays, // 断签天数
            ),

          // 粒子效果
          if (!_isCheckedToday)
            Positioned.fill(
              child: IgnorePointer(
                child: ParticleEffect(
                  controller: _particleController,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}