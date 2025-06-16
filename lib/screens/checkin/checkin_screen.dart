// lib/screens/checkin/checkin_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/checkin_result.dart';
import 'package:suxingchahui/models/user/checkin_status.dart';
import 'package:suxingchahui/models/user/monthly_checkin_report.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/models/user/user_checkIn_today_list.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/main/user/user_checkin_service.dart';
import 'package:suxingchahui/services/main/user/user_follow_service.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/effects/checkin_particle_effect.dart';
import 'package:suxingchahui/widgets/components/screen/checkin/layout/checkin_layout.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';

class CheckInScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final UserInfoProvider infoProvider;
  final UserFollowService followService;
  final UserCheckInService checkInService;
  final WindowStateProvider windowStateProvider;

  const CheckInScreen({
    super.key,
    required this.authProvider,
    required this.infoProvider,
    required this.followService,
    required this.checkInService,
    required this.windowStateProvider,
  });

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _checkInLoading = false;
  String? _errorMessage;
  CheckInStatus? _checkInStatus;
  User? _currentUser;
  MonthlyCheckInReport? _monthlyData;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _missedDays = 0;
  int _consecutiveMissedDays = 0;
  bool _hasInitializedDependencies = false;

  TodayCheckInList? _todayCheckInList;
  bool _isTodayListLoading = false;
  String? _todayListErrMsg;

  late AnimationController _particleController;

  static const Duration _minTodayListRefreshInterval = Duration(seconds: 30);

  DateTime? _lastTodayListRefreshAttemptTime;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _currentUser = widget.authProvider.currentUser;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _loadTodayListData();

      if (widget.authProvider.isLoggedIn) {
        _loadData();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayListData({bool needCheck = true}) async {
    if (_isTodayListLoading) {
      return;
    }
    final now = DateTime.now();
    if (needCheck) {
      if (_lastTodayListRefreshAttemptTime != null &&
          now.difference(_lastTodayListRefreshAttemptTime!) <
              _minTodayListRefreshInterval) {
        final remainingSeconds = _minTodayListRefreshInterval.inSeconds -
            now.difference(_lastTodayListRefreshAttemptTime!).inSeconds;

        AppSnackBar.showInfo(
          '手速太快了！请 $remainingSeconds 秒后再刷新',
          duration: const Duration(seconds: 2),
        );
      }
      _lastTodayListRefreshAttemptTime = now;
    } else {
      _lastTodayListRefreshAttemptTime = now;
    }

    try {
      setState(() {
        _isTodayListLoading = true;
        _todayListErrMsg = null;
      });
      final result = await widget.checkInService.getTodayCheckInList();
      setState(() {
        _todayCheckInList = result;
        _isTodayListLoading = false;
      });
    } catch (e) {
      setState(() {
        _todayCheckInList = null;
        _todayListErrMsg = e.toString();
      });
    } finally {
      setState(() {
        _isTodayListLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (!widget.authProvider.isLoggedIn || !mounted) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await widget.checkInService.getCheckInStatus();
      final monthlyData = await widget.checkInService.getMonthlyCheckInData(
        year: _selectedYear,
        month: _selectedMonth,
      );

      final bool todayChecked = stats.checkedInToday;
      final consecutiveMissed =
          UserCheckInService.calculateConsecutiveMissedDays(
        monthlyData,
        todayChecked,
      );
      final missed = UserCheckInService.calculateMissedDays(monthlyData);

      if (mounted) {
        setState(() {
          _checkInStatus = stats;
          _currentUser = widget.authProvider.currentUser;
          _monthlyData = monthlyData;
          _missedDays = missed;
          _consecutiveMissedDays = consecutiveMissed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              '加载数据失败: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCheckIn() async {
    if ((_checkInStatus?.checkedInToday ?? true) ||
        _checkInLoading ||
        _isLoading) {
      return;
    }

    setState(() => _checkInLoading = true);

    try {
      final result = await widget.checkInService.performCheckIn();
      final currentUserId = _currentUser?.id;
      if (currentUserId != null) {
        await widget.infoProvider.refreshUserInfo(currentUserId);
      }

      if (mounted) {
        _particleController.reset();
        _particleController.forward();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      await _loadData();
      await _loadTodayListData(needCheck: false);

      if (mounted) {
        _showCheckInSuccess(result);
      }
    } catch (e) {
      AppSnackBar.showError('签到失败: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _checkInLoading = false);
      }
    }
  }

  void _showCheckInSuccess(CheckInResult result) {
    final int expGained = result.experienceGained;
    final int consecutiveDays = result.consecutiveCheckIn;
    final int totalCheckInDays = result.totalCheckIn;
    final int coinsGained = result.coinsGained;

    final String message = '恭喜您完成今日签到！\n'
        '${totalCheckInDays > 0 ? '今天是第$totalCheckInDays天签到！\n' : ''}'
        '${expGained > 0 ? '获得 +$expGained 经验值\n' : ''}'
        '${coinsGained > 0 ? '获得$coinsGained硬币！\n' : ''}'
        '当前连续签到: $consecutiveDays 天';

    CustomConfirmDialog.show(
      context: context,
      title: '签到成功！🎉',
      message: message,
      iconData: Icons.check_circle_outline,
      iconColor: Colors.green,
      confirmButtonText: '知道了',
      confirmButtonColor: Theme.of(context).primaryColor,
      onConfirm: () async {},
      barrierDismissible: true,
    );
  }

  Future<void> _handleChangeMonth(int year, int month) async {
    if (!mounted) return;

    setState(() {
      _selectedYear = year;
      _selectedMonth = month;
      _monthlyData = null;
      _missedDays = 0;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newMonthlyData = await widget.checkInService.getMonthlyCheckInData(
        year: year,
        month: month,
      );
      final newMissedDays =
          UserCheckInService.calculateMissedDays(newMonthlyData);

      if (mounted) {
        setState(() {
          _monthlyData = newMonthlyData;
          _missedDays = newMissedDays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              '加载月份数据失败: ${e.toString().replaceAll('Exception: ', '')}';
          _monthlyData =
              MonthlyCheckInReport.defaultReport(year: year, month: month);
          _missedDays = 0;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFab() {
    return GenericFloatingActionButton(
      icon: Icons.refresh,
      heroTag: 'check_in_refresh_fab',
      tooltip: '刷新数据',
      onPressed: _isLoading ? null : _loadData,
    );
  }

  Widget _buildContentLayout() {
    return LazyLayoutBuilder(
      windowStateProvider: widget.windowStateProvider,
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktopLayout = DeviceUtils.isDesktopInThisWidth(screenWidth);
        return CheckInLayout(
          isDesktop: isDesktopLayout,
          infoProvider: widget.infoProvider,
          checkInService: widget.checkInService,
          followService: widget.followService,
          checkInStatus: _checkInStatus!,
          currentUser: _currentUser!,
          monthlyData: _monthlyData,
          selectedYear: _selectedYear,
          todayCheckInList: _todayCheckInList,
          isTodayListLoading: _isTodayListLoading,
          onRefreshTodayList: () => _loadTodayListData(),
          todayListErrMsg: _todayListErrMsg,
          selectedMonth: _selectedMonth,
          isCheckInLoading: _checkInLoading,
          hasCheckedToday: _checkInStatus!.checkedInToday,
          animationController: _particleController,
          onChangeMonth: _handleChangeMonth,
          onCheckIn: () => _handleCheckIn(),
          missedDays: _missedDays,
          consecutiveMissedDays: _consecutiveMissedDays,
        );
      },
    );
  }

  Widget _buildMainSection() {
    if (_isLoading && (_checkInStatus == null || _monthlyData == null)) {
      return const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      ); //
    }

    if (_errorMessage != null) {
      return CustomErrorWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadData,
      );
    }

    if (_checkInStatus == null || _currentUser == null) {
      return CustomErrorWidget(
        errorMessage: '签到数据异常，请刷新重试。',
        onRetry: _loadData,
      );
    }
    return _buildContentLayout();
  }

  Widget? _buildEffectSection() {
    if (!(_checkInStatus?.checkedInToday ?? true) &&
        !_isLoading &&
        _errorMessage == null) {
      return Positioned.fill(
        child: IgnorePointer(
          child: CheckInParticleEffect(
            controller: _particleController,
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        _buildMainSection(),
        if (_buildEffectSection() != null) _buildEffectSection()!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '每日签到'),
      body: widget.authProvider.isLoggedIn
          ? _buildMainContent()
          : const LoginPromptWidget(),
      floatingActionButton: widget.authProvider.isLoggedIn ? _buildFab() : null,
    );
  }
}
