// lib/wrapper/maintenance_wrapper.dart

/// 该文件定义了 MaintenanceWrapper，一个用于处理应用维护状态的 StatefulWidget。
/// MaintenanceWrapper 负责根据维护状态显示维护界面或渲染主应用内容。
library;

import 'dart:async'; // 异步操作所需
import 'package:flutter/material.dart'; // Flutter UI 组件
import 'package:flutter/foundation.dart'; // 导入 kIsWeb
import 'package:provider/provider.dart'; // Provider 状态管理
import 'package:suxingchahui/constants/global_constants.dart'; // 全局常量
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart'; // 桌面框架布局
import 'package:suxingchahui/utils/device/device_utils.dart'; // 设备工具类
import 'package:suxingchahui/widgets/ui/components/maintenance_display.dart'; // 维护信息显示组件
import 'package:suxingchahui/services/main/maintenance/maintenance_checker_service.dart'; // 维护检查服务
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart'; // 维护服务
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 认证 Provider
import 'package:suxingchahui/models/maintenance/maintenance_info.dart'; // 维护信息模型
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 颜色扩展方法
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 应用文本组件
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart'; // 应用文本类型
import 'package:suxingchahui/windows/ui/windows_controls.dart'; // Windows 窗口控制
import 'package:window_manager/window_manager.dart'; // 窗口管理库

/// `LifecycleEventHandler` 类：应用生命周期事件处理器。
///
/// 该类监听应用生命周期状态变化，并在应用从后台恢复时执行回调。
class _LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack; // 应用从后台恢复时执行的回调

  /// 构造函数。
  ///
  /// [resumeCallBack]：应用从后台恢复时的回调。
  _LifecycleEventHandler({
    required this.resumeCallBack,
  });

  /// 应用生命周期状态变化时调用。
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台恢复
      await resumeCallBack(); // 执行恢复回调
    }
  }
}

/// `MaintenanceWrapper` 类：维护模式包装器。
///
/// 该 Widget 负责根据维护状态显示维护界面或渲染主应用内容。
class MaintenanceWrapper extends StatefulWidget {
  final AuthProvider authProvider; // 认证 Provider
  final MaintenanceService maintenanceService; // 维护服务
  final Widget child; // 子 Widget

  /// 构造函数。
  ///
  /// [key]：Widget 的 Key。
  /// [authProvider]：认证 Provider。
  /// [maintenanceService]：维护服务。
  /// [child]：要渲染的子 Widget。
  const MaintenanceWrapper({
    super.key,
    required this.authProvider,
    required this.maintenanceService,
    required this.child,
  });

  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

/// `_MaintenanceWrapperState` 类：`MaintenanceWrapper` 的状态管理。
class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  late final MaintenanceCheckerService _maintenanceChecker; // 维护检查服务实例
  bool _hasInitializedDependencies = false; // 依赖项是否已初始化标记
  bool _hasInitializedMaintenance = false; // 维护状态是否已初始化标记
  _LifecycleEventHandler? _lifecycleEventHandler; // 生命周期事件处理器

  /// 初始化状态。
  @override
  void initState() {
    super.initState();
  }

  /// 依赖项发生变化时调用。
  ///
  /// 初始化维护检查服务，并检查维护状态。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedDependencies) {
      _maintenanceChecker =
          context.read<MaintenanceCheckerService>(); // 获取维护检查服务
      _hasInitializedDependencies = true; // 标记依赖项已初始化
    }
    if (_hasInitializedDependencies) {
      widget.maintenanceService
          .checkMaintenanceStatus(forceCheck: true) // 强制检查维护状态
          .then((_) {
        if (mounted) {
          // 检查 Widget 是否已挂载
          setState(() {
            _hasInitializedMaintenance = true; // 标记维护状态已初始化
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 在当前帧渲染完成后回调
            if (mounted && _hasInitializedMaintenance) {
              // 检查 Widget 挂载状态和维护状态初始化
              _maintenanceChecker.triggerMaintenanceCheck(
                  uiContext: context); // 触发维护检查
            }
          });
        }
      }).catchError((error) {
        // 捕获错误
        if (mounted) {
          // 检查 Widget 是否已挂载
          setState(() {
            _hasInitializedMaintenance = true; // 标记维护状态已初始化
          });
        }
      });
    }
  }

  /// 销毁状态。
  ///
  /// 移除生命周期事件监听。
  @override
  void dispose() {
    if (_lifecycleEventHandler != null) {
      WidgetsBinding.instance
          .removeObserver(_lifecycleEventHandler!); // 移除生命周期事件监听
    }
    super.dispose(); // 调用父类销毁方法
  }

  /// 构建 Windows 窗口控制区域。
  ///
  /// 返回一个包含应用图标、标题和窗口控制按钮的 Positioned Widget。
  Widget _buildWindowsControlsSection() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: DesktopFrameLayout.kDesktopTitleBarHeight, // 标题栏高度
      child: Material(
        color: Colors.white, // 背景色
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0), // 水平内边距
              child: Row(
                mainAxisSize: MainAxisSize.min, // 最小尺寸
                children: [
                  Image.asset(
                    GlobalConstants.appIcon, // 应用图标
                    height: 24.0,
                    width: 24.0,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(width: 8.0), // 间距
                  AppText(
                    GlobalConstants.appName, // 应用名称
                    color: Colors.black,
                    fontSize: 13,
                    maxLines: 1,
                    type: AppTextType.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: DragToMoveArea(
                // 拖拽区域
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // 渐变背景
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [...GlobalConstants.desktopBarColor],
                    ),
                  ),
                ),
              ),
            ),
            WindowsControls(
              // Windows 窗口控制按钮
              iconColor: Colors.grey[700],
              hoverColor: Colors.black.withSafeOpacity(0.1),
              closeHoverColor: Colors.red.withSafeOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Widget。
  ///
  /// 根据维护状态显示维护界面或渲染主应用内容。
  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktop; // 判断是否是桌面平台

    if (!_hasInitializedDependencies) {
      return const SizedBox.shrink(); // 依赖项未初始化时返回空 Widget
    }

    return StreamBuilder<MaintenanceInfo?>(
      stream: widget.maintenanceService.maintenanceInfoStream, // 监听维护信息 Stream
      initialData: widget.maintenanceService.maintenanceInfo, // 初始数据
      builder: (context, maintenanceSnapshot) {
        final bool isInMaintenance =
            widget.maintenanceService.isInMaintenance; // 是否处于维护状态
        final bool allowLogin = widget.maintenanceService.allowLogin; // 是否允许登录
        final MaintenanceInfo? currentMaintenanceInfo =
            maintenanceSnapshot.data; // 当前维护信息
        final bool isAdmin = widget.authProvider.isAdmin; // 是否是管理员
        if (isInMaintenance && !allowLogin && !isAdmin) {
          // 处于维护状态且不允许登录且不是管理员
          final maintenanceContent = Material(
            color: Theme.of(context).scaffoldBackgroundColor, // 背景颜色
            child: MaintenanceDisplay(
              maintenanceInfo: currentMaintenanceInfo, // 维护信息
              remainingMinutes:
                  widget.maintenanceService.remainingMinutes, // 剩余分钟数
            ),
          );

          return isDesktop // 判断是否是桌面平台
              ? Stack(
                  // 桌面端使用 Stack 叠加窗口控件
                  children: [
                    maintenanceContent, // 维护内容
                    _buildWindowsControlsSection(), // Windows 窗口控制区域
                  ],
                )
              : maintenanceContent; // 移动端直接显示维护内容
        }
        return widget.child; // 不在维护状态时渲染子 Widget
      },
    );
  }
}
