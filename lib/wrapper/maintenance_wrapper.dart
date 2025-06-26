// lib/wrapper/maintenance_wrapper.dart

/// 处理应用核心状态（如维护、网络）的顶级包装器。
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/components/maintenance_display.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_checker_service.dart';
import 'package:suxingchahui/services/main/maintenance/maintenance_service.dart';
import 'package:suxingchahui/services/main/network/network_manager.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/models/maintenance/maintenance_info.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import 'package:suxingchahui/windows/ui/windows_controls.dart';
import 'package:suxingchahui/widgets/ui/utils/network_error_widget.dart';
import 'package:window_manager/window_manager.dart';

/// 应用生命周期事件处理器。
class _LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;

  /// 创建一个 [_LifecycleEventHandler] 实例。
  _LifecycleEventHandler({required this.resumeCallBack});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await resumeCallBack();
    }
  }
}

/// 维护及网络状态包装器。
class MaintenanceNetworkWrapper extends StatefulWidget {
  final AuthProvider authProvider;
  final MaintenanceService maintenanceService;
  final NetworkManager networkManager;
  final Widget child;

  /// 创建一个 [MaintenanceNetworkWrapper] 实例。
  const MaintenanceNetworkWrapper({
    super.key,
    required this.authProvider,
    required this.maintenanceService,
    required this.networkManager,
    required this.child,
  });

  @override
  State<MaintenanceNetworkWrapper> createState() => _MaintenanceNetworkWrapperState();
}

class _MaintenanceNetworkWrapperState extends State<MaintenanceNetworkWrapper> {
  late final MaintenanceCheckerService _maintenanceChecker;
  bool _hasInitializedDependencies = false;
  bool _hasInitializedMaintenance = false;
  _LifecycleEventHandler? _lifecycleEventHandler;

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
          setState(() => _hasInitializedMaintenance = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _hasInitializedMaintenance) {
              _maintenanceChecker.triggerMaintenanceCheck(uiContext: context);
            }
          });
        }
      }).catchError((error) {
        if (mounted) setState(() => _hasInitializedMaintenance = true);
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

  /// 构建 Windows 窗口控制区域。
  Widget _buildWindowsControlsSection() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: DesktopFrameLayout.kDesktopTitleBarHeight,
      child: Material(
        color: Colors.white,
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
                    GlobalConstants.appName,
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
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [...GlobalConstants.desktopBarColor],
                    ),
                  ),
                ),
              ),
            ),
            WindowsControls(
              iconColor: Colors.grey[700],
              hoverColor: Colors.black.withSafeOpacity(0.1),
              closeHoverColor: Colors.red.withSafeOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建动态的维护遮罩。
  Widget _buildMaintenanceOverlay(BuildContext context) {
    return StreamBuilder<MaintenanceInfo?>(
      stream: widget.maintenanceService.maintenanceInfoStream,
      initialData: widget.maintenanceService.maintenanceInfo,
      builder: (context, maintenanceSnapshot) {
        final bool isInMaintenance = widget.maintenanceService.isInMaintenance;
        final bool allowLogin = widget.maintenanceService.allowLogin;
        final bool isAdmin = widget.authProvider.isAdmin;

        if (isInMaintenance && !allowLogin && !isAdmin) {
          final MaintenanceInfo? currentMaintenanceInfo =
              maintenanceSnapshot.data;
          final maintenanceContent = Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: MaintenanceDisplay(
              maintenanceInfo: currentMaintenanceInfo,
              remainingMinutes: widget.maintenanceService.remainingMinutes,
            ),
          );

          final isDesktop = DeviceUtils.isDesktop;
          return isDesktop
              ? Stack(
                  children: [
                    maintenanceContent,
                    _buildWindowsControlsSection(),
                  ],
                )
              : maintenanceContent;
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInitializedDependencies) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 底层: 主应用内容
        widget.child,

        // 中层: 维护遮罩
        _buildMaintenanceOverlay(context),

        // 顶层: 网络错误提示
        NetworkErrorWidget(networkManager: widget.networkManager),
      ],
    );
  }
}
