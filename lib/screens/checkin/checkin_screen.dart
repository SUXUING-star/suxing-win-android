import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/models/user/user_checkin.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/layout/checkin_content.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/effects/particle_effect.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

class CheckInScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final UserCheckInService checkInService;
  const CheckInScreen({
    super.key,
    required this.authProvider,
    required this.infoProvider,
    required this.followService,
    required this.checkInService,
  });

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  // 状态变量
  bool _isLoading = true; // 页面整体加载状态
  bool _hasInitializedDependencies = false;
  bool _checkInLoading = false; // 签到按钮的加载状态
  CheckInStats? _checkInStats; // 签到统计信息 (使用修改后的模型)
  User? _currentUser; // 当前登录用户信息 (包含等级经验)
  Map<String, dynamic>? _monthlyData; // 月度签到日历数据
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _errorMessage; // 加载错误信息
  int _missedDays = 0; // 本月漏签天数 (仅当前月份计算)
  int _consecutiveMissedDays = 0; // 断签天数 (自上次签到后)

  // 动画控制器
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 粒子效果持续时间
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      ;
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      // 加载初始数据
      _loadData();
    }
  }

  @override
  void dispose() {
    _particleController.dispose(); // 释放动画控制器资源
    super.dispose();
  }

  /// 加载签到页面所需的所有数据
  Future<void> _loadData() async {
    // 防止在 Widget 被 dispose 后还调用 setState
    if (!mounted) return;

    // 进入加载状态
    setState(() {
      _isLoading = true;
      _errorMessage = null; // 清除之前的错误信息
    });

    try {
      final currentUser = widget.authProvider.currentUser;
      // 必须确保用户已登录且用户信息已加载
      if (!widget.authProvider.isLoggedIn || currentUser == null) {
        // 可以抛出异常或设置错误消息
        throw Exception("用户未登录或信息获取失败");
      }

      // 2. 并行获取签到状态和月度数据 (如果需要初始化服务，放在前面)
      // await _checkInService.initialize(); // 如果需要初始化
      final results = await Future.wait([
        widget.checkInService.getCheckInStats(), // 获取签到统计 (返回精简后的 CheckInStats)
        widget.checkInService.getMonthlyCheckInData(
            year: _selectedYear, month: _selectedMonth), // 获取日历数据
        widget.checkInService.calculateConsecutiveMissedDays(), // 计算断签天数
      ]);

      // 处理获取结果
      final stats = results[0] as CheckInStats; // 类型断言
      final monthlyData = results[1] as Map<String, dynamic>?; // 类型断言
      final consecutiveMissedDays = results[2] as int; // 类型断言

      // 3. 计算本月漏签天数 (基于获取到的月度数据)
      final missedDays = await _calculateMissedDays(monthlyData);

      // 4. 更新状态 (必须在 mounted 检查后)
      if (mounted) {
        setState(() {
          _checkInStats = stats;
          _currentUser = currentUser; // 保存当前用户信息
          _monthlyData = monthlyData;
          _missedDays = missedDays;
          _consecutiveMissedDays = consecutiveMissedDays;
          _isLoading = false; // 加载完成
        });
      }
    } catch (e) {
      // print('签到数据加载失败: $e');
      if (mounted) {
        setState(() {
          // 显示更友好的错误信息
          _errorMessage =
              '加载数据失败，请稍后重试 (${e.toString().replaceAll('Exception: ', '')})';
          _isLoading = false;
        });
      }
    }
  }

  /// 计算当前显示月份的漏签天数 (仅对当前实际月份有效)
  Future<int> _calculateMissedDays(Map<String, dynamic>? monthlyData) async {
    // 如果不是当前年月，或数据为空，则不计算漏签
    final now = DateTime.now();
    if (monthlyData == null ||
        _selectedYear != now.year ||
        _selectedMonth != now.month) {
      return 0;
    }

    try {
      final List<dynamic> rawDays = monthlyData['days'] as List? ?? [];
      final Set<int> checkedDays = {};

      // 收集已签到的日期数字
      for (final rawDay in rawDays) {
        if (rawDay is Map) {
          final Map<String, dynamic> dayData =
              Map<String, dynamic>.from(rawDay);
          if (dayData['checkedIn'] == true && dayData['day'] != null) {
            // 安全解析日期数字
            int? dayNum;
            if (dayData['day'] is int) {
              dayNum = dayData['day'];
            } else if (dayData['day'] is String) {
              dayNum = int.tryParse(dayData['day']);
            }

            if (dayNum != null) {
              checkedDays.add(dayNum);
            }
          }
        }
      }

      // 计算从 1 号到昨天 (now.day - 1) 的漏签天数
      final currentDayOfMonth = now.day;
      int missedCount = 0;
      for (int day = 1; day < currentDayOfMonth; day++) {
        if (!checkedDays.contains(day)) {
          missedCount++;
        }
      }
      return missedCount;
    } catch (e) {
      // print('计算漏签天数时发生错误: $e');
      return 0; // 出错时返回 0
    }
  }

  /// 处理签到按钮点击事件
  Future<void> _handleCheckIn() async {
    // 防止重复点击或在未加载/已签到时点击
    if ((_checkInStats?.hasCheckedToday ?? true) ||
        _checkInLoading ||
        _isLoading) {
      return;
    }

    setState(() {
      _checkInLoading = true;
    }); // 进入签到按钮加载状态

    try {
      // 调用签到服务接口
      final result = await widget.checkInService.performCheckIn(); // 返回精简后的结果

      // 播放签到成功粒子效果
      if (mounted) {
        _particleController.reset();
        _particleController.forward();
      }

      // **重要：签到成功后，需要重新加载页面数据以反映最新状态**
      // 加入短暂延迟，等待 AuthProvider 更新完成（可选，但建议）
      await Future.delayed(const Duration(milliseconds: 300)); // 可以根据实际情况调整
      if (mounted) {
        await _loadData(); // 重新加载数据
      }

      // 显示签到成功提示框
      if (mounted) {
        // 使用签到接口返回的本次结果来显示提示
        _showCheckInSuccess(result);
      }
    } catch (e) {
      if (mounted) {
        // 显示更具体的错误信息
        final String errorMessage =
            '签到失败: ${e.toString().replaceAll('Exception: ', '')}';
        AppSnackBar.showError(context, errorMessage);
      }
    } finally {
      // 无论成功或失败，结束签到按钮的加载状态
      if (mounted) {
        setState(() {
          _checkInLoading = false;
        });
      }
    }
  }

  /// 显示签到成功对话框
  void _showCheckInSuccess(Map<String, dynamic> result) {
    // 从签到接口返回结果中安全地获取信息
    int expGained = 0;
    if (result['experienceGained'] is int) {
      expGained = result['experienceGained'];
    } else if (result['experienceGained'] != null) {
      expGained = int.tryParse(result['experienceGained'].toString()) ?? 0;
    }

    int consecutiveDays = 1;
    if (result['consecutiveCheckIn'] is int) {
      consecutiveDays = result['consecutiveCheckIn'];
    } else if (result['consecutiveCheckIn'] != null) {
      consecutiveDays =
          int.tryParse(result['consecutiveCheckIn'].toString()) ?? 1;
    }

    // 构建提示信息
    final String message = '恭喜您完成今日签到！\n'
        '${expGained > 0 ? '获得 +$expGained 经验值\n' : ''}' // 仅当获得经验时显示
        '当前连续签到: $consecutiveDays 天';

    // 显示确认对话框
    CustomConfirmDialog.show(
      context: context,
      title: '签到成功！🎉',
      message: message,
      iconData: Icons.check_circle_outline,
      iconColor: Colors.green,
      confirmButtonText: '知道了',
      confirmButtonColor: Theme.of(context).primaryColor,
      onConfirm: () async {}, // 点击确认按钮无特殊操作
      barrierDismissible: true, // 允许点击外部关闭
    );
  }

  /// 处理切换月份的事件
  void _handleChangeMonth(int year, int month) {
    // 更新选中的年月，并清除旧的月度数据和漏签天数
    setState(() {
      _selectedYear = year;
      _selectedMonth = month;
      _monthlyData = null; // 清空旧数据，触发 Loading
      _missedDays = 0; // 切换月份后重置漏签天数
      // _consecutiveMissedDays 不在这里重置，它是全局的
    });

    // 异步加载新月份的签到数据
    widget.checkInService
        .getMonthlyCheckInData(year: year, month: month)
        .then((data) {
      if (mounted) {
        setState(() {
          _monthlyData = data;
          // 如果切换回当前月份，重新计算漏签天数
          final now = DateTime.now();
          if (year == now.year && month == now.month) {
            _calculateMissedDays(data).then((mDays) {
              if (mounted) setState(() => _missedDays = mDays);
            });
          }
        });
      }
    });
  }

  Widget _buildFab() {
    return GenericFloatingActionButton(
      icon: Icons.refresh,
      heroTag: 'check_in_fresh_fab',
      tooltip: '刷新数据',
      onPressed: _isLoading ? null : _loadData,
    );
  }

  Widget _buildContentLayout() {
    return CheckInContent(
      infoProvider: widget.infoProvider,
      checkInService: widget.checkInService,
      followService: widget.followService,
      checkInStats: _checkInStats!, // 传递签到统计
      currentUser: _currentUser!, // 传递当前用户信息
      monthlyData: _monthlyData, // 传递月度日历数据
      selectedYear: _selectedYear,
      selectedMonth: _selectedMonth,
      isCheckInLoading: _checkInLoading, // 传递签到按钮状态
      hasCheckedToday: _checkInStats!.hasCheckedToday, // 传递今天是否已签到
      animationController: _particleController, // 传递动画控制器
      onChangeMonth: _handleChangeMonth, // 传递月份切换回调
      onCheckIn: _handleCheckIn, // 传递签到按钮回调
      missedDays: _missedDays, // 传递漏签天数
      consecutiveMissedDays: _consecutiveMissedDays, // 传递断签天数
    );
  }

  Widget _buildMainSection() {
    if (_isLoading) {
      return LoadingWidget.fullScreen(message: '正在加载签到数据...');
    }
    if (_errorMessage != null) {
      CustomErrorWidget(
        errorMessage: _errorMessage,
      );
    }
    if (_checkInStats == null || _currentUser == null) {
      CustomErrorWidget(errorMessage: '数据异常，请稍后重试');
    }
    return _buildContentLayout();
  }

  Widget? _buildEffectSection() {
    if (!(_checkInStats?.hasCheckedToday ?? true) &&
        !_isLoading &&
        _errorMessage == null) {
      return Positioned.fill(
        child: IgnorePointer(
          // 让粒子效果不响应触摸事件
          child: CheckinParticleEffect(
            controller: _particleController, // 控制动画播放
            color: Theme.of(context).primaryColor, // 粒子颜色
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildMainContent() {
    return Stack(
      // 使用 Stack 放置粒子效果
      children: [
        _buildMainSection(),
        _buildEffectSection() ?? const SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '每日签到',
      ),
      body: widget.authProvider.isLoggedIn
          ? _buildMainContent()
          : const LoginPromptWidget(),
      floatingActionButton: _buildFab(),
    );
  }
}
