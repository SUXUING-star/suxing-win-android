// lib/wrapper/maintenance_wrapper.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/components/maintenance_display.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_checker_service.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/models/maintenance/maintenance_info.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import 'package:suxingchahui/windows/ui/windows_controls.dart';
import 'package:window_manager/window_manager.dart';

// LifecycleEventHandler 不变
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;

  LifecycleEventHandler({
    required this.resumeCallBack,
  });
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await resumeCallBack();
    }
  }
}

class MaintenanceWrapper extends StatefulWidget {
  final AuthProvider authProvider;
  final MaintenanceService maintenanceService;
  final Widget child;

  const MaintenanceWrapper({
    super.key,
    required this.authProvider,
    required this.maintenanceService,
    required this.child,
  });

  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  late final MaintenanceCheckerService _maintenanceChecker;
  bool _hasInitializedDependencies = false;
  bool _hasInitializedMaintenance = false;
  LifecycleEventHandler? _lifecycleEventHandler;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedDependencies) {
      _maintenanceChecker = context.read<MaintenanceCheckerService>();
      _hasInitializedDependencies = true;
    }
    if (_hasInitializedDependencies) {
      widget.maintenanceService
          .checkMaintenanceStatus(forceCheck: true)
          .then((_) {
        if (mounted) {
          setState(() {
            _hasInitializedMaintenance = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _hasInitializedMaintenance) {
              _maintenanceChecker.triggerMaintenanceCheck(uiContext: context);
            }
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasInitializedMaintenance = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    if (_lifecycleEventHandler != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleEventHandler!);
    }
    super.dispose();
  }

  Widget _buildWindowsControlsSection() {
    return Positioned(
      // 顶层放置一个 Positioned Widget 作为标题栏区域
      top: 0, // 紧贴顶部
      left: 0, // 紧贴左边
      right: 0, // 紧贴右边
      height: DesktopFrameLayout.kDesktopTitleBarHeight, // 使用常量定义的高度
      child: Material(
        // 使用 Material Widget 可以设置背景色（这里是透明）
        color: Colors.white,
        // 标题栏内部使用 Row 排列
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    GlobalConstants.appIcon,
                    height: 24.0,
                    width: 24.0,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(width: 8.0),
                  AppText(
                    GlobalConstants.appName, // 使用传入或默认标题
                    color: Colors.black,
                    fontSize: 13,
                    maxLines: 1,
                    type: AppTextType.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 左侧大部分区域是可拖拽区域
            Expanded(
              child: DragToMoveArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        ...DesktopFrameLayout.desktopBarColor
                      ], // 使用传入或默认渐变
                    ),
                  ),
                ), // 拖拽区域本身不需要显示内容
              ),
            ),
            // 右侧是窗口控制按钮 (最小化, 最大化/还原, 关闭)
            WindowsControls(
              iconColor: Colors.grey[700], // 图标颜色，确保可见
              hoverColor: Colors.black.withSafeOpacity(0.1), // 鼠标悬停背景色
              closeHoverColor: Colors.red.withSafeOpacity(0.8), // 关闭按钮悬停背景色
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktop;

    if (!_hasInitializedDependencies) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<MaintenanceInfo?>(
      stream: widget.maintenanceService.maintenanceInfoStream,
      initialData: widget.maintenanceService.maintenanceInfo,
      builder: (context, maintenanceSnapshot) {
        final bool isInMaintenance = widget.maintenanceService.isInMaintenance;
        final bool allowLogin = widget.maintenanceService.allowLogin;
        final MaintenanceInfo? currentMaintenanceInfo =
            maintenanceSnapshot.data;
        final bool isAdmin = widget.authProvider.isAdmin;
        if (isInMaintenance && !allowLogin && !isAdmin) {
          final maintenanceContent = Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: MaintenanceDisplay(
              maintenanceInfo: currentMaintenanceInfo,
              remainingMinutes: widget.maintenanceService.remainingMinutes,
            ),
          );

          return isDesktop // 判断是否是桌面平台
              ? Stack(
                  // 桌面端使用 Stack 来叠加窗口控件
                  children: [
                    // 底层是上面构建的核心内容
                    maintenanceContent,
                    _buildWindowsControlsSection(),
                  ],
                )
              : maintenanceContent;
        }
        return widget.child;
      },
    );
  }
}
