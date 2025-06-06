// lib/screens/profile/profile_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/constants/profile/profile_constants.dart';
import 'package:suxingchahui/models/user/daily_progress.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart';
import 'package:suxingchahui/services/common/upload/rate_limited_file_upload.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/inputs/text_input_field.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_lr_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/floating_action_button_group.dart';
import 'package:suxingchahui/widgets/ui/buttons/generic_fab.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/constants/profile/profile_menu_item.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/mobile/profile_mobile_header.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/mobile/profile_mobile_menu_list.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/desktop/profile_desktop_account_card.dart';
import 'package:suxingchahui/widgets/components/screen/profile/layout/desktop/profile_desktop_menu_grid.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/login_prompt_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final UserService userService;
  final InputStateService inputStateService;
  final SidebarProvider sidebarProvider;
  final RateLimitedFileUpload fileUpload;
  const ProfileScreen({
    super.key,
    required this.authProvider,
    required this.userService,
    required this.inputStateService,
    required this.sidebarProvider,
    required this.fileUpload,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  String? _error;
  bool _isInitialized = false;
  bool _hasInitializedDependencies = false;
  bool _isVisible = false;
  bool _isRefreshing = false;
  final visibilityKey = const Key('profile_screen_visibility_detector');
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 30);
  String? _currentUserId;

  DailyProgressData? _dailyProgressData;
  bool _isLoadingExpData = false;
  String? _expDataError;
  bool _expDataLoadedOnce = false;

  static const String _editUsernameSlot = 'profile_edit_username';
  static const String _editSignatureSlot = 'profile_edit_signature';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      _currentUserId = widget.authProvider.currentUserId;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      if (_currentUserId != widget.authProvider.currentUserId) {
        if (mounted) {
          setState(() {
            _currentUserId = widget.authProvider.currentUserId;
          });
        }
      }
    } else if (state == AppLifecycleState.paused) {
      //
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentUserId != oldWidget.authProvider.currentUserId ||
        _currentUserId != widget.authProvider.currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    final bool currentlyVisible = info.visibleFraction > 0;

    if (_currentUserId != widget.authProvider.currentUserId) {
      if (mounted) {
        setState(() {
          _currentUserId = widget.authProvider.currentUserId;
        });
      }
    }
    if (currentlyVisible != _isVisible) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isVisible = currentlyVisible;
          });
          if (_isVisible) {
            _triggerInitialLoad(); // 这个会检查是否需要加载主用户信息
            // 如果可见，已登录，且经验数据从未加载过 (或上次加载失败)
            if (widget.authProvider.isLoggedIn &&
                (!_expDataLoadedOnce || _expDataError != null)) {
              _loadDailyExperienceProgress();
            }
          }
        } else {
          _isVisible = currentlyVisible;
        }
      });
    }
  }

  // 加载每日经验进度数据的方法
  Future<void> _loadDailyExperienceProgress({bool forceRefresh = false}) async {
    if (!mounted || !widget.authProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          // 如果未登录，清空数据
          _dailyProgressData = null;
          _isLoadingExpData = false;
          _expDataError = null;
          _expDataLoadedOnce = false;
        });
      }
      return;
    }
    // 如果正在加载且不是强制刷新，则返回
    if (_isLoadingExpData && !forceRefresh) return;
    // 如果已经加载过且没有错误，并且不是强制刷新，则不重复加载
    if (_expDataLoadedOnce &&
        _dailyProgressData != null &&
        _expDataError == null &&
        !forceRefresh) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingExpData = true;
        _expDataError = null;
        if (forceRefresh) _dailyProgressData = null; // 强制刷新时清除旧数据，以便显示loading
      });
    }

    try {
      final data = await widget.userService.getDailyExperienceProgress();
      if (mounted) {
        setState(() {
          _dailyProgressData = data;
          _isLoadingExpData = false;
          _expDataLoadedOnce = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expDataError = "经验数据加载失败";
          _isLoadingExpData = false;
          _expDataLoadedOnce = true; // 标记尝试加载过
        });
      }
    }
  }

  void _triggerInitialLoad() {
    if (!_isInitialized && _isVisible) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          if (widget.authProvider.isLoggedIn && !_expDataLoadedOnce) {
            // 如果已登录且经验数据从未加载过
            _loadDailyExperienceProgress();
          }
        }
      });
    }
  }

  Future<void> _refreshProfile({bool needCheck = true}) async {
    if (_isRefreshing) return;

    final now = DateTime.now();
    if (needCheck) {
      if (_lastRefreshTime != null &&
          now.difference(_lastRefreshTime!) < _minRefreshInterval) {
        final remaining =
            _minRefreshInterval - now.difference(_lastRefreshTime!);
        final remainingSeconds = remaining.inSeconds + 1;
        if (mounted) {
          AppSnackBar.showInfo(context, '刷新太频繁，请 $remainingSeconds 秒后再试');
        }
        return;
      }
    }

    if (!mounted) return;
    if (!widget.authProvider.isLoggedIn) {
      if (mounted) {
        setState(() {
          _error = null;
          _isInitialized = true;
          // 清理经验数据
          _dailyProgressData = null;
          _isLoadingExpData = false;
          _expDataError = null;
          _expDataLoadedOnce = false;
        });
      }
      return;
    }

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      await widget.authProvider.refreshUserState();
      if (mounted && widget.authProvider.isLoggedIn) {
        await _loadDailyExperienceProgress(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '刷新失败: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    }
  }

  void _showEditProfileDialog(User currentUser, BuildContext context) {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    widget.inputStateService.getController(_editUsernameSlot).text =
        currentUser.username;
    widget.inputStateService.getController(_editSignatureSlot).text =
        currentUser.signature ?? '';

    BaseInputDialog.show<bool>(
      context: context,
      title: '编辑个人资料',
      iconData: Icons.edit_note_outlined,
      confirmButtonText: '保存更改',
      isDraggable: true,
      isScalable: false,
      contentBuilder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: AppText(
                  "用户名 (3-25位)",
                  style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                ),
              ),
              TextInputField(
                inputStateService: widget.inputStateService,
                slotName: _editUsernameSlot,
                hintText: '请输入新的用户名',
                maxLines: 1,
                maxLength: 25,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                showSubmitButton: false,
                textInputAction: TextInputAction.next,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: AppText(
                  "个性签名 (最多100位)",
                  style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                ),
              ),
              TextInputField(
                inputStateService: widget.inputStateService,
                slotName: _editSignatureSlot,
                hintText: '请输入您的个性签名',
                maxLines: 3,
                minLines: 1,
                maxLength: 100,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                showSubmitButton: false,
                textInputAction: TextInputAction.done,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
      onConfirm: () async {
        final newUsername =
            widget.inputStateService.getText(_editUsernameSlot).trim();
        final newSignature =
            widget.inputStateService.getText(_editSignatureSlot).trim();

        if (newUsername.isEmpty) {
          throw Exception('用户名不能为空');
        }
        if (newUsername.length < 3 || newUsername.length > 25) {
          throw Exception('用户名长度必须为 3 到 25 位');
        }
        if (newSignature.length > 100) {
          throw Exception('个性签名不能超过 100 位');
        }

        final bool usernameChanged = newUsername != currentUser.username;
        final bool signatureChanged =
            newSignature != (currentUser.signature ?? '');

        if (!usernameChanged && !signatureChanged) {
          return false;
        }

        await widget.userService.updateUserProfile(
          username: usernameChanged ? newUsername : null,
          signature: signatureChanged ? newSignature : null,
        );

        await widget.authProvider.refreshUserState();
        return true;
      },
    ).then((updatePerformed) {
      if (updatePerformed == true) {
        if (mounted) {
          AppSnackBar.showSuccess(this.context, '个人资料更新成功！');
        }
      }
    }).catchError((error) {
      if (mounted) {
        AppSnackBar.showError(this.context, '操作失败: $error');
      }
    }).whenComplete(() {
      widget.inputStateService.clearText(_editUsernameSlot);
      widget.inputStateService.clearText(_editSignatureSlot);
    });
  }

  void _showLogoutDialog(BuildContext context) {
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showWarning(context, "你没登录你登出干什么");
      return;
    }
    CustomConfirmDialog.show(
      context: context,
      title: '退出登录',
      message: '您确定要退出当前账号吗？',
      confirmButtonText: '确认退出',
      cancelButtonText: '取消',
      confirmButtonColor: Colors.red,
      iconData: Icons.logout,
      iconColor: Colors.orange,
      onConfirm: () async {
        try {
          await widget.authProvider.signOut();
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
            NavigationUtils.navigateToHome(widget.sidebarProvider, this.context,
                tabIndex: 0);
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _isRefreshing = false;
          });
          AppSnackBar.showError(this.context, '登录失败：$e');
        }
      },
    );
  }

  void _handleUploadStateChanged(bool isLoading) {
    if (mounted && _isRefreshing != isLoading) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isRefreshing = isLoading;
          });
        }
      });
    }
  }

  Future<void> _handleUploadSuccess(
      BuildContext context, String avatarUrl) async {
    if (!mounted) return;
    try {
      await widget.userService.updateUserProfile(
        avatar: avatarUrl,
      );

      await widget.authProvider.refreshUserState();
      if (mounted && widget.authProvider.isLoggedIn) {
        await _loadDailyExperienceProgress(forceRefresh: true);
      }

      if (!mounted) return;
      AppSnackBar.showSuccess(this.context, '用户信息已刷新');
    } catch (e) {
      if (!mounted) return;
      // 补偿删除头像
      widget.fileUpload.deleteUploadedImagesOnError([avatarUrl]);
      AppSnackBar.showError(this.context, '刷新用户信息失败：$e');
    } finally {
      // 无论 try 成功还是 catch 有异常，最后都必须把加载状态关掉！
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isDesktop = DeviceUtils.isDesktop;
    final bool useDesktopLayout = isDesktop && screenSize.width > 900;

    return VisibilityDetector(
      key: visibilityKey,
      onVisibilityChanged: _handleVisibilityChange,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: '个人中心', actions: []),
        body: RefreshIndicator(
          onRefresh: () => _refreshProfile(),
          child: _buildProfileContent(useDesktopLayout),
        ),
        floatingActionButton: _buildFloatButtons(context),
      ),
    );
  }

  Widget _buildFloatButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
      child: FloatingActionButtonGroup(
        spacing: 16.0,
        alignment: MainAxisAlignment.end,
        children: [
          GenericFloatingActionButton(
            icon: Icons.settings_outlined,
            onPressed: () =>
                NavigationUtils.pushNamed(context, AppRoutes.settingPage),
            heroTag: "profile_setting_fab",
            tooltip: "设置",
          )
        ],
      ),
    );
  }

  Widget _buildDesktopContent(
      User currentUser, List<ProfileMenuItem> menuItems) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: FadeInSlideLRItem(
              slideDirection: SlideDirection.left,
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 100),
              child: ProfileDesktopAccountCard(
                user: currentUser,
                onEditProfile: () =>
                    _showEditProfileDialog(currentUser, context),
                onLogout: () => _showLogoutDialog(context),
                onUploadStateChanged: _handleUploadStateChanged,
                fileUpload: widget.fileUpload,
                onUploadSuccess: (avatarUrl) =>
                    _handleUploadSuccess(context, avatarUrl),
                dailyProgressData: _dailyProgressData,
                isLoadingExpData: _isLoadingExpData,
                expDataError: _expDataError,
                onRefreshExpData: () =>
                    _loadDailyExperienceProgress(forceRefresh: true),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: FadeInSlideLRItem(
              slideDirection: SlideDirection.right,
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 250),
              child: ProfileDesktopMenuGrid(menuItems: menuItems),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent(
      User currentUser, List<ProfileMenuItem> menuItems) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        FadeInSlideUpItem(
          duration: const Duration(milliseconds: 400),
          delay: const Duration(milliseconds: 100),
          child: ProfileMobileHeader(
            user: currentUser,
            onEditProfile: () => _showEditProfileDialog(currentUser, context),
            onLogout: () => _showLogoutDialog(context),
            fileUpload: widget.fileUpload,
            onUploadStateChanged: _handleUploadStateChanged,
            onUploadSuccess: (avatarUrl) =>
                _handleUploadSuccess(context, avatarUrl),
            dailyProgressData: _dailyProgressData,
            isLoadingExpData: _isLoadingExpData,
            expDataError: _expDataError,
            onRefreshExpData: () =>
                _loadDailyExperienceProgress(forceRefresh: true),
          ),
        ),
        FadeInSlideUpItem(
          duration: const Duration(milliseconds: 450),
          delay: const Duration(milliseconds: 200),
          child: ProfileMobileMenuList(menuItems: menuItems),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildProfileContent(bool useDesktopLayout) {
    return StreamBuilder<User?>(
        stream: widget.authProvider.currentUserStream,
        initialData: widget.authProvider.currentUser,
        builder: (context, authSnapshot) {
          final User? currentUser = authSnapshot.data;
          if (currentUser == null) {
            if (_isInitialized ||
                _error != null ||
                _isRefreshing ||
                _dailyProgressData != null) {
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    _error = null;
                    _isInitialized = false; // 可以重置初始化状态，以便下次可见时重新触发
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
                child: const LoginPromptWidget());
          }

          // 加载状态处理
          if (_isRefreshing && _error == null) {
            return LoadingWidget.fullScreen(message: "正在刷新...");
          } else if (!_isInitialized && _error == null) {
            return LoadingWidget.fullScreen(message: "正在加载个人资料");
          } else if (_error != null) {
            return Center(
                child: CustomErrorWidget(
                    errorMessage: _error!, onRetry: () => _refreshProfile()));
          }
          final menuItems = ProfileConstants.getProfileMenuItems(
            context,
            currentUser.isAdmin,
            currentUser,
          );
          return Stack(
            children: [
              if (useDesktopLayout)
                _buildDesktopContent(currentUser, menuItems)
              else
                _buildMobileContent(currentUser, menuItems),
              if (_isRefreshing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withSafeOpacity(0.1),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
            ],
          );
        });
  }
}
