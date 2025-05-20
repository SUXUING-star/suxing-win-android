// lib/wrapper/maintenance_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/widgets/ui/components/maintenance_display.dart';
import '../services/main/maintenance/maintenance_checker_service.dart';
import '../services/main/maintenance/maintenance_service.dart';
import '../providers/auth/auth_provider.dart';
import '../models/maintenance/maintenance_info.dart';

// LifecycleEventHandler 不变
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  LifecycleEventHandler({required this.resumeCallBack});
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await resumeCallBack();
    }
  }
}

class MaintenanceWrapper extends StatefulWidget {
  final Widget child;
  const MaintenanceWrapper({super.key, required this.child});
  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  late final MaintenanceCheckerService _maintenanceChecker;
  late final MaintenanceService _maintenanceService;
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
      _maintenanceService = context.watch<MaintenanceService>();
      _hasInitializedDependencies = true;
    }

    if (_hasInitializedDependencies) {
      _maintenanceService.checkMaintenanceStatus(forceCheck: true).then((_) {
        // ---- then 回调，在 Future 完成后执行 ----
        if (mounted) {
          // 检查 _MaintenanceWrapperState 是否 mounted
          try {
            setState(() {
              _hasInitializedMaintenance = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // ---- addPostFrameCallback 的回调 ----
              if (mounted) {
                // 再次检查
                // 'context' 在这里是 didChangeDependencies 的 context (即 this.context)
                // Linter 可能会因为外层的 .then() 异步间隙而警告
                _maintenanceChecker.triggerMaintenanceCheck(uiContext: context);
              }
            });
          } catch (e) {
            // debugPrint("Error initializing MaintenanceCheckerService: $e");
          }
        }
      }).catchError((error) {
        // ---- catchError 回调，也在 Future 完成后执行 ----
        // debugPrint("Error during initial maintenance check: $error");
        if (mounted) {
          // 检查 _MaintenanceWrapperState 是否 mounted
          setState(() {
            _hasInitializedMaintenance = true;
          });
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ---- addPostFrameCallback 的回调 ----
        if (mounted &&
            _hasInitializedDependencies &&
            _hasInitializedMaintenance) {
          _maintenanceChecker.triggerMaintenanceCheck(uiContext: context);
        }
      });
    }
  }

  @override
  void dispose() {
    if (_lifecycleEventHandler != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleEventHandler!);
    }
    if (_hasInitializedDependencies && mounted) {
      _maintenanceChecker.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktop;

    return Consumer2<MaintenanceService, AuthProvider>(
      builder: (context, maintenanceService, authProvider, child) {
        final bool isAdmin = authProvider.isAdmin || authProvider.isSuperAdmin;
        final MaintenanceInfo? info = maintenanceService.maintenanceInfo;

        // --- 判断是否需要显示维护界面 ---
        if (maintenanceService.isInMaintenance &&
            !maintenanceService.allowLogin &&
            !isAdmin) {
          final maintenanceContent = Material(
            // 保证有 Material 祖先
            color: Theme.of(context).scaffoldBackgroundColor, // 使用背景色
            child: MaintenanceDisplay(
              maintenanceInfo: info,
              remainingMinutes: maintenanceService.remainingMinutes,
            ),
          );

          // 根据平台决定是否用 DesktopFrameLayout 包裹
          return isDesktop
              ? DesktopFrameLayout(
                  showSidebar: false,
                  showTitleBarActions: false,
                  child: maintenanceContent,
                )
              : maintenanceContent;
        }

        // --- 不在维护模式或允许访问 ---
        return child!;
      },
      child: widget.child,
    );
  }
}
