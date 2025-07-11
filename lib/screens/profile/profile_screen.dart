// lib/screens/profile/profile_screen.dart

/// 该文件定义了 ProfileScreen 组件，一个用于显示用户个人资料的屏幕。
/// ProfileScreen 负责加载和展示用户资料、经验进度、并提供编辑和登出功能。
library;

import 'dart:async'; // 导入 Timer
import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:flutter/services.dart'; // 导入文本输入格式化
import 'package:suxingchahui/models/user/task/daily_progress_data.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 导入侧边栏 Provider
import 'package:suxingchahui/services/main/user/user_info_service.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart'; // 导入限速文件上传服务
import 'package:suxingchahui/services/main/user/user_service.dart'; // 导入用户服务
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/dart/lazy_layout_builder.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart'; // 导入基础输入对话框
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart'; // 导入文本输入框组件
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:visibility_detector/visibility_detector.dart'; // 导入可见性检测器
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart'; // 导入左右滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart'; // 导入悬浮动作按钮组
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart'; // 导入通用悬浮动作按钮
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart'; // 导入应用 SnackBar 工具
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/constants/profile/profile_menu_item.dart'; // 导入个人资料菜单项常量
import 'package:suxingchahui/models/user/user/user.dart'; // 导入用户模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/utils/device/device_utils.dart'; // 导入设备工具类
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar
import 'package:suxingchahui/widgets/components/screen/profile/layout/mobile/profile_mobile_header.dart'; // 导入移动端个人资料头部组件
import 'package:suxingchahui/widgets/components/screen/profile/layout/mobile/profile_mobile_menu_list.dart'; // 导入移动端个人资料菜单列表组件
import 'package:suxingchahui/widgets/components/screen/profile/layout/desktop/profile_desktop_account_card.dart'; // 导入桌面端个人资料账号卡片组件
import 'package:suxingchahui/widgets/components/screen/profile/layout/desktop/profile_desktop_menu_grid.dart'; // 导入桌面端个人资料菜单网格组件
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart'; // 导入登录提示组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart'; // 导入确认对话框

/// `ProfileScreen` 类：用户个人资料屏幕组件。
///
/// 该屏幕负责展示用户资料、经验进度、并提供编辑资料、上传头像和登出等功能。
class ProfileScreen extends StatefulWidget {
  final AuthProvider authProvider; // 认证 Provider
  final UserService userService; // 用户服务
  final UserInfoService infoService;
  final InputStateService inputStateService; // 输入状态服务
  final SidebarProvider sidebarProvider; // 侧边栏 Provider
  final RateLimitedFileUpload fileUpload; // 限速文件上传服务
  final WindowStateProvider windowStateProvider;

  /// 构造函数。
  ///
  /// [authProvider]：认证 Provider。
  /// [userService]：用户服务。
  /// [inputStateService]：输入状态服务。
  /// [sidebarProvider]：侧边栏 Provider。
  /// [fileUpload]：文件上传服务。
  const ProfileScreen({
    super.key,
    required this.authProvider,
    required this.infoService,
    required this.windowStateProvider,
    required this.userService,
    required this.inputStateService,
    required this.sidebarProvider,
    required this.fileUpload,
  });

  /// 创建状态。
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

/// `_ProfileScreenState` 类：`ProfileScreen` 的状态管理。
///
/// 管理用户资料加载、经验进度加载、错误处理、可见性、刷新和各种用户操作。
class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  String? _error; // 错误消息
  bool _isInitialized = false; // 是否已初始化标记
  bool _hasInitializedDependencies = false; // 依赖初始化标记
  bool _isVisible = false; // 屏幕是否可见标记
  bool _isRefreshing = false; // 是否正在刷新标记
  final visibilityKey =
      const Key('profile_screen_visibility_detector'); // 可见性检测器键
  DateTime? _lastRefreshTime; // 上次刷新时间
  DateTime? _lastRefreshingTime; // 最新一次被挂起加载的时间
  static const Duration _minRefreshInterval = Duration(seconds: 30); // 最小刷新间隔
  static const Duration _maxRefreshingDuration = Duration(seconds: 10);
  static const Duration _maxLoadingExpDataDuration = Duration(seconds: 10);
  String? _currentUserId; // 当前用户ID

  DailyProgressData? _dailyProgressData; // 每日经验进度数据
  bool _isLoadingExpData = false; // 经验数据是否正在加载
  DateTime? _lastLoadingExpDataTime;
  String? _expDataError; // 经验数据错误消息
  bool _expDataLoadedOnce = false; // 经验数据是否已加载至少一次

  late double _screenWidth;

  static const String _editUsernameSlot = 'profile_edit_username'; // 编辑用户名槽名称
  static const String _editSignatureSlot = 'profile_edit_signature'; // 编辑签名槽名称

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this); // 添加应用生命周期观察者
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      // 依赖未初始化时
      _hasInitializedDependencies = true; // 标记为已初始化
    }
    if (_hasInitializedDependencies) {
      _screenWidth = DeviceUtils.getScreenWidth(context);
      _currentUserId = widget.authProvider.currentUserId; // 获取当前用户ID
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return; // 组件未挂载时返回

    if (state == AppLifecycleState.resumed) {
      _checkAuthStateChange();
      _checkLoadingTimeout();
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停时
      // 无操作
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != oldWidget.authProvider.currentUserId ||
        _currentUserId != widget.authProvider.currentUserId) {
      // 用户ID变化时
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this); // 移除应用生命周期观察者
  }

  /// 处理可见性变化。
  ///
  /// [info]：可见性信息。
  void _handleVisibilityChange(VisibilityInfo info) {
    final bool currentlyVisible = info.visibleFraction > 0; // 判断当前是否可见

    _checkLoadingTimeout();
    _checkAuthStateChange();

    if (currentlyVisible != _isVisible) {
      // 可见性状态变化时
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isVisible = currentlyVisible; // 更新可见性状态
          });
          if (_isVisible) {
            // 如果变为可见
            _triggerInitialLoad(); // 触发初始加载
            if (widget.authProvider.isLoggedIn &&
                (!_expDataLoadedOnce || _expDataError != null)) {
              // 已登录且经验数据未加载或加载失败时
              _loadDailyExperienceProgress(); // 加载每日经验进度
            }
          }
        } else {
          _isVisible = currentlyVisible; // 更新可见性状态
        }
      });
    }
  }

  ///
  ///
  void _checkAuthStateChange() {
    if (_currentUserId != widget.authProvider.currentUserId) {
      // 用户ID变化时
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId; // 更新用户ID
        });
      }
    }
  }

  ///
  ///
  void _checkLoadingTimeout() {
    // 不管是可视变化还是什么时候
    final now = DateTime.now();
    // 超过最大时长直接关闭
    if (_lastRefreshingTime != null &&
        now.difference(_lastRefreshingTime!) > _maxRefreshingDuration) {
      if (mounted) {
        setState(() {
          _lastRefreshingTime = null;
          _isRefreshing = false;
        });
      }
    }

    // 超过最大时长直接关闭
    if (_lastLoadingExpDataTime != null &&
        now.difference(_lastLoadingExpDataTime!) > _maxLoadingExpDataDuration) {
      if (mounted) {
        setState(() {
          _lastLoadingExpDataTime = null;
          _isLoadingExpData = false;
        });
      }
    }
  }

  /// 加载每日经验进度数据。
  ///
  /// [forceRefresh]：是否强制刷新。
  Future<void> _loadDailyExperienceProgress({bool forceRefresh = false}) async {
    if (!mounted || !widget.authProvider.isLoggedIn) {
      // 组件未挂载或未登录时
      if (mounted) {
        setState(() {
          _dailyProgressData = null; // 清空数据
          _isLoadingExpData = false; // 结束加载
          _expDataError = null; // 清空错误
          _expDataLoadedOnce = false; // 重置加载标记
        });
      }
      return; // 返回
    }
    if (_lastLoadingExpDataTime != null) _lastLoadingExpDataTime = null;
    if (_isLoadingExpData && !forceRefresh) return; // 正在加载且非强制刷新时返回
    if (_expDataLoadedOnce &&
        _dailyProgressData != null &&
        _expDataError == null &&
        !forceRefresh) {
      // 已加载且无错误且非强制刷新时返回
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingExpData = true; // 设置加载状态
        _lastLoadingExpDataTime = DateTime.now();
        _expDataError = null; // 清空错误
        if (forceRefresh) _dailyProgressData = null; // 强制刷新时清除旧数据
      });
    }

    try {
      final data =
          await widget.userService.getDailyExperienceProgress(); // 获取每日经验进度数据
      if (mounted) {
        setState(() {
          _dailyProgressData = data; // 更新数据
          _isLoadingExpData = false; // 结束加载
          _lastLoadingExpDataTime = null;
          _expDataLoadedOnce = true; // 标记已加载
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expDataError = "经验数据加载失败"; // 设置错误消息
          _isLoadingExpData = false; // 结束加载
          _expDataLoadedOnce = true; // 标记已加载
          _lastLoadingExpDataTime = null;
        });
      }
    }
  }

  /// 触发初始加载。
  ///
  /// 仅在未初始化且可见时加载主用户信息。
  void _triggerInitialLoad() {
    if (!_isInitialized && _isVisible) {
      // 未初始化且可见时
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isInitialized = true; // 标记为已初始化
          });
          if (widget.authProvider.isLoggedIn && !_expDataLoadedOnce) {
            // 已登录且经验数据未加载时
            _loadDailyExperienceProgress(); // 加载每日经验进度
            _lastRefreshTime = DateTime.now();
          }
        }
      });
    }
  }

  /// 刷新个人资料。
  ///
  /// [needCheck]：是否需要进行时间间隔检查。
  Future<void> _refreshData({bool needCheck = true}) async {
    if (_lastRefreshingTime != null) _lastRefreshTime = null;
    if (_isRefreshing) return; // 正在刷新时返回

    final now = DateTime.now();
    if (needCheck) {
      // 需要检查时
      if (_lastRefreshTime != null &&
          now.difference(_lastRefreshTime!) < _minRefreshInterval) {
        // 刷新间隔不足时
        final remaining =
            _minRefreshInterval - now.difference(_lastRefreshTime!);
        final remainingSeconds = remaining.inSeconds + 1;
        if (mounted) {
          AppSnackBar.showInfo('刷新太频繁，请 $remainingSeconds 秒后再试'); // 提示刷新频繁
        }
        return; // 返回
      }
    }

    if (!mounted) return; // 组件未挂载时返回
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时
      if (mounted) {
        setState(() {
          _error = null; // 清空错误
          _isInitialized = true; // 标记为已初始化
          _isRefreshing = false; // 结束刷新
          _lastRefreshTime = null; // 清空上次刷新时间
          _dailyProgressData = null; // 清空经验数据
          _isLoadingExpData = false; // 结束经验数据加载
          _expDataError = null; // 清空经验数据错误
          _expDataLoadedOnce = false; // 重置经验数据加载标记
        });
      }
      return; // 返回
    }

    if (mounted) {
      setState(() {
        _isRefreshing = true; // 设置刷新状态
        _error = null; // 清空错误
        _lastRefreshingTime = DateTime.now();
      });
    }

    try {
      await widget.authProvider.refreshUserState(forceRefresh: true); // 刷新用户状态
      if (_currentUserId != null) {}
      if (mounted && widget.authProvider.isLoggedIn) {
        // 组件挂载且已登录时
        await _loadDailyExperienceProgress(forceRefresh: true); // 强制刷新经验数据
      }
    } catch (e) {
      // 捕获刷新失败异常
      if (mounted) {
        setState(() {
          _error = '刷新失败: ${e.toString()}'; // 设置错误消息
        });
      }
    } finally {
      // 无论成功失败，确保刷新状态重置
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastRefreshTime = DateTime.now(); // 记录刷新时间
          _lastRefreshingTime = null;
        });
      }
    }
  }

  /// 显示编辑个人资料对话框。
  ///
  /// [currentUser]：当前用户。
  /// [context]：Build 上下文。
  void _showEditProfileDialog(User currentUser, BuildContext context) {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示登录
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    widget.inputStateService.getController(_editUsernameSlot).text =
        currentUser.username; // 设置用户名
    widget.inputStateService.getController(_editSignatureSlot).text =
        currentUser.signature ?? ''; // 设置个性签名

    BaseInputDialog.show<bool>(
      context: context,
      title: '编辑个人资料', // 标题
      iconData: Icons.edit_note_outlined, // 图标
      confirmButtonText: '保存更改', // 确认按钮文本
      isDraggable: true, // 可拖拽
      isScalable: false, // 不可缩放
      contentBuilder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0), // 垂直内边距
          child: Column(
            mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化
            crossAxisAlignment: CrossAxisAlignment.stretch, // 交叉轴拉伸
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0), // 底部内边距
                child: AppText(
                  "用户名 (3-25位)", // 文本
                  style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                ),
              ),
              TextInputField(
                inputStateService: widget.inputStateService, // 输入状态服务
                slotName: _editUsernameSlot, // 槽名称
                hintText: '请输入新的用户名', // 提示文本
                maxLines: 1, // 最大行数
                maxLength: 25, // 最大长度
                maxLengthEnforcement: MaxLengthEnforcement.enforced, // 长度限制策略
                showSubmitButton: false, // 不显示提交按钮
                textInputAction: TextInputAction.next, // 文本输入动作
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12), // 内容内边距
                padding: EdgeInsets.zero, // 内边距
              ),
              const SizedBox(height: 16), // 间距
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0), // 底部内边距
                child: AppText(
                  "个性签名 (最多100位)", // 文本
                  style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                ),
              ),
              TextInputField(
                inputStateService: widget.inputStateService, // 输入状态服务
                slotName: _editSignatureSlot, // 槽名称
                hintText: '请输入您的个性签名', // 提示文本
                maxLines: 3, // 最大行数
                minLines: 1, // 最小行数
                maxLength: 100, // 最大长度
                maxLengthEnforcement: MaxLengthEnforcement.enforced, // 长度限制策略
                showSubmitButton: false, // 不显示提交按钮
                textInputAction: TextInputAction.done, // 文本输入动作
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12), // 内容内边距
                padding: EdgeInsets.zero, // 内边距
              ),
            ],
          ),
        );
      },
      onConfirm: () async {
        // 确认回调
        final newUsername = widget.inputStateService
            .getText(_editUsernameSlot)
            .trim(); // 获取新用户名
        final newSignature = widget.inputStateService
            .getText(_editSignatureSlot)
            .trim(); // 获取新个性签名

        if (newUsername.isEmpty) {
          // 用户名为空时抛出异常
          throw Exception('用户名不能为空');
        }
        if (newUsername.length < 3 || newUsername.length > 25) {
          // 用户名长度不符合要求时抛出异常
          throw Exception('用户名长度必须为 3 到 25 位');
        }
        if (newSignature.length > 100) {
          // 个性签名长度超出限制时抛出异常
          throw Exception('个性签名不能超过 100 位');
        }

        final bool usernameChanged =
            newUsername != currentUser.username; // 用户名是否改变
        final bool signatureChanged =
            newSignature != (currentUser.signature ?? ''); // 个性签名是否改变

        if (!usernameChanged && !signatureChanged) {
          // 未发生改变时返回 false
          return false;
        }

        await widget.userService.updateCurrentUserProfile(
          username: usernameChanged ? newUsername : null, // 更新用户名
          signature: signatureChanged ? newSignature : null, // 更新个性签名
        );

        await widget.authProvider.refreshUserState(); // 刷新用户状态
        return true; // 返回 true 表示确认成功
      },
    ).then((updatePerformed) {
      // 对话框关闭后的回调
      if (updatePerformed == true) {
        // 更新成功时
        if (mounted) {
          AppSnackBar.showSuccess('个人资料更新成功！'); // 显示成功提示
        }
      }
    }).catchError((error) {
      // 捕获错误时
      if (mounted) {
        AppSnackBar.showError('操作失败: $error'); // 显示错误提示
      }
    }).whenComplete(() {
      // 完成时清空输入
      widget.inputStateService.clearText(_editUsernameSlot);
      widget.inputStateService.clearText(_editSignatureSlot);
    });
  }

  /// 显示退出登录对话框。
  ///
  /// [context]：Build 上下文。
  void _showLogoutDialog(BuildContext context) {
    if (!widget.authProvider.isLoggedIn) {
      // 未登录时提示
      AppSnackBar.showWarning("你没登录你登出干什么");
      return;
    }
    CustomConfirmDialog.show(
      context: context,
      title: '退出登录', // 标题
      message: '您确定要退出当前账号吗？', // 消息
      confirmButtonText: '确认退出', // 确认按钮文本
      cancelButtonText: '取消', // 取消按钮文本
      confirmButtonColor: Colors.red, // 确认按钮颜色
      iconData: Icons.logout, // 图标
      iconColor: Colors.orange, // 颜色
      onConfirm: () async {
        // 确认回调
        try {
          await widget.authProvider.signOut(); // 调用认证 Provider 登出
          if (mounted) {
            // 登出成功且组件挂载时
            setState(() {
              // 重置所有相关状态
              _error = null;
              _isInitialized = false;
              _isRefreshing = false;
              _lastRefreshTime = null;
              _dailyProgressData = null;
              _isLoadingExpData = false;
              _expDataError = null;
              _expDataLoadedOnce = false;
            });
            NavigationUtils.navigateToHome(widget.sidebarProvider, this.context,
                tabIndex: 0); // 导航到首页
          }
        } catch (e) {
          // 捕获登出失败异常
          if (!mounted) return; // 组件未挂载时返回
          setState(() {
            _isRefreshing = false; // 结束刷新
          });
          AppSnackBar.showError('登录失败：${e.toString()}'); // 显示错误提示
        }
      },
    );
  }

  /// 处理上传成功。
  ///
  /// [context]：Build 上下文。
  /// [avatarUrl]：新头像 URL。
  Future<void> _handleUploadSuccess(
      BuildContext context, String avatarUrl) async {
    if (!mounted) return; // 组件未挂载时返回
    try {
      await widget.userService.updateCurrentUserProfile(
        avatar: avatarUrl, // 更新用户头像
      );

      await widget.authProvider.refreshUserState(); // 刷新用户状态

      AppSnackBar.showSuccess('用户信息已刷新'); // 显示成功提示
    } catch (e) {
      // 捕获刷新失败异常
      widget.fileUpload.deleteUploadedImagesOnError([avatarUrl]); // 补偿删除头像
      AppSnackBar.showError('刷新用户信息失败：${e.toString()}'); // 显示错误提示
    } finally {
      // 无论成功失败，确保刷新状态重置
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// 构建个人资料屏幕的主体 UI。
  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: visibilityKey, // 可见性检测器键
      onVisibilityChanged: _handleVisibilityChange, // 可见性变化回调
      child: Scaffold(
        backgroundColor: Colors.transparent, // 背景透明
        appBar: const CustomAppBar(title: '个人中心', actions: []), // AppBar
        body: RefreshIndicator(
          onRefresh: () => _refreshData(needCheck: true), // 下拉刷新回调
          child: _buildProfileContent(), // 个人资料内容
        ),
        floatingActionButton: _buildFloatButtons(), // 悬浮按钮
      ),
    );
  }

  String _makeHeroTag({required String mainCtx}) {
    final ctxDevice =
        DeviceUtils.isDesktopInThisWidth(_screenWidth) ? 'desktop' : 'mobile';
    const ctxScreen = 'profile';
    return '${ctxScreen}_${ctxDevice}_${mainCtx}_${widget.authProvider.currentUserId}';
  }

  /// 构建悬浮按钮组。
  ///
  Widget _buildFloatButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0), // 内边距
      child: FloatingActionButtonGroup(
        toggleButtonHeroTag: "profile_heroTags",
        spacing: 16.0, // 间距
        alignment: MainAxisAlignment.end, // 对齐方式
        children: [
          GenericFloatingActionButton(
            icon: Icons.refresh_outlined, // 图标
            onPressed: () => _refreshData(needCheck: true),
            heroTag: _makeHeroTag(mainCtx: 'refresh'), // Hero 标签
            tooltip: "刷新", // 提示
          ),
          GenericFloatingActionButton(
            icon: Icons.settings_outlined, // 图标
            onPressed: () => NavigationUtils.pushNamed(
                context, AppRoutes.settingPage), // 点击导航到设置页面
            heroTag: _makeHeroTag(mainCtx: 'profile'), // Hero 标签
            tooltip: "设置", // 提示
          ),
        ],
      ),
    );
  }

  /// 构建桌面端内容。
  ///
  /// [currentUser]：当前用户。
  /// [menuItems]：菜单项列表。
  Widget _buildDesktopContent(
      User currentUser, List<ProfileMenuItem> menuItems) {
    return Padding(
      padding: const EdgeInsets.all(24.0), // 内边距
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
        children: [
          Expanded(
            flex: 1, // 比例
            child: FadeInSlideLRItem(
              slideDirection: SlideDirection.left, // 滑动方向
              duration: const Duration(milliseconds: 500), // 动画时长
              delay: const Duration(milliseconds: 100), // 延迟
              child: ProfileDesktopAccountCard(
                user: currentUser, // 用户数据
                onEditProfile: () =>
                    _showEditProfileDialog(currentUser, context), // 编辑个人资料回调
                onLogout: () => _showLogoutDialog(context), // 登出回调
                fileUpload: widget.fileUpload, // 文件上传服务
                onUploadSuccess: (avatarUrl) =>
                    _handleUploadSuccess(context, avatarUrl), // 上传成功回调
                dailyProgressData: _dailyProgressData, // 每日进度数据
                isLoadingExpData: _isLoadingExpData, // 经验数据是否加载中
                expDataError: _expDataError, // 经验数据错误
                onRefreshExpData: (needCheck) =>
                    _refreshData(needCheck: needCheck), // 刷新经验数据回调
              ),
            ),
          ),
          const SizedBox(width: 24), // 间距
          Expanded(
            flex: 2,
            child: FadeInSlideLRItem(
              slideDirection: SlideDirection.right, // 滑动方向
              duration: const Duration(milliseconds: 500), // 动画时长
              delay: const Duration(milliseconds: 250), // 延迟
              child: ProfileDesktopMenuGrid(
                screenWidth: _screenWidth,
                menuItems: menuItems,
                windowStateProvider: widget.windowStateProvider,
                currentUser: widget.authProvider.currentUser,
              ), // 桌面端菜单网格
            ),
          ),
        ],
      ),
    );
  }

  /// 构建移动端内容。
  ///
  /// [currentUser]：当前用户。
  /// [menuItems]：菜单项列表。
  Widget _buildMobileContent(
      User currentUser, List<ProfileMenuItem> menuItems) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(), // 始终可滚动物理
      children: [
        FadeInSlideUpItem(
          duration: const Duration(milliseconds: 400), // 动画时长
          delay: const Duration(milliseconds: 100), // 延迟
          child: ProfileMobileHeader(
            user: currentUser, // 用户数据
            onEditProfile: () =>
                _showEditProfileDialog(currentUser, context), // 编辑个人资料回调
            onLogout: () => _showLogoutDialog(context), // 登出回调
            fileUpload: widget.fileUpload, // 文件上传服务
            onUploadSuccess: (avatarUrl) =>
                _handleUploadSuccess(context, avatarUrl), // 上传成功回调
            dailyProgressData: _dailyProgressData, // 每日进度数据
            isLoadingExpData: _isLoadingExpData, // 经验数据是否加载中
            expDataError: _expDataError, // 经验数据错误
            onRefreshExpData: (needCheck) =>
                _refreshData(needCheck: needCheck), // 刷新经验数据回调
          ),
        ),
        FadeInSlideUpItem(
          duration: const Duration(milliseconds: 450), // 动画时长
          delay: const Duration(milliseconds: 200), // 延迟
          child: ProfileMobileMenuList(
            menuItems: menuItems,
            currentUser: widget.authProvider.currentUser,
          ), // 移动端菜单列表
        ),
        const SizedBox(height: 80), // 底部间距
      ],
    );
  }

  /// 构建个人资料内容。
  ///
  /// [useDesktopLayout]：是否使用桌面布局。
  Widget _buildProfileContent() {
    return StreamBuilder<User?>(
        stream: widget.authProvider.currentUserStream, // 监听当前用户流
        initialData: widget.authProvider.currentUser, // 初始用户数据
        builder: (context, authSnapshot) {
          final User? currentUser = authSnapshot.data; // 获取当前用户数据
          if (currentUser == null) {
            // 未登录时
            if (_isInitialized ||
                _error != null ||
                _isRefreshing ||
                _dailyProgressData != null) {
              // 重置所有状态
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                    _isRefreshing = false;
                    _lastRefreshTime = null;
                    _dailyProgressData = null;
                    _isLoadingExpData = false;
                    _expDataError = null;
                    _expDataLoadedOnce = false;
                  });
                }
              });
            }
            return FadeInSlideUpItem(
                duration: const Duration(milliseconds: 300),
                child: const LoginPromptWidget()); // 显示登录提示
          }

          if (_isRefreshing && _error == null) {
            // 刷新中且无错误时显示全屏加载
            return const FadeInItem(
              // 全屏加载组件
              child: LoadingWidget(
                isOverlay: true,
                message: "等待加载...",
                overlayOpacity: 0.4,
                size: 36,
              ),
            ); //
          } else if (!_isInitialized && _error == null) {
            // 未初始化且无错误时显示全屏加载
            return const LoadingWidget(
              isOverlay: true,
              message: "少女正在祈祷中...",
              overlayOpacity: 0.4,
              size: 36,
              // 全屏加载组件
            ); //
          } else if (_error != null) {
            // 有错误时显示错误组件
            return Center(
              child: CustomErrorWidget(
                errorMessage: _error!,
                onRetry: () => _refreshData(needCheck: false),
              ),
            );
          }
          final List<ProfileMenuItem> menuItems =
              ProfileMenuItem.getProfileMenuItems(
            currentUser.isAdmin,
          );

          return Stack(
            children: [
              LazyLayoutBuilder(
                windowStateProvider: widget.windowStateProvider,
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  _screenWidth = screenWidth;
                  return DeviceUtils.isDesktopInThisWidth(screenWidth)
                      ? _buildDesktopContent(currentUser, menuItems)
                      : _buildMobileContent(currentUser, menuItems);
                },
              ),
              if (_isRefreshing) // 刷新中时显示半透明遮罩和进度指示器
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withSafeOpacity(0.1), // 半透明黑色背景
                    child: const LoadingWidget(
                      size: 40,
                    ), // 进度指示器
                  ),
                ),
            ],
          );
        });
  }
}
