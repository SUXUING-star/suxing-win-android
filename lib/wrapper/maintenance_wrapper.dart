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
  late MaintenanceCheckerService _maintenanceChecker;
  bool _hasInitializedMaintenance = false;
  LifecycleEventHandler? _lifecycleEventHandler;

  @override
  void initState() {
    super.initState();
    _maintenanceChecker = context.read<MaintenanceCheckerService>();

    _lifecycleEventHandler = LifecycleEventHandler(
      resumeCallBack: () async {
        if (mounted && _hasInitializedMaintenance) {
          final maintenanceService = context.read<MaintenanceService>();
          await maintenanceService.checkMaintenanceStatus();
          _maintenanceChecker.triggerMaintenanceCheck(uiContext: context);
        }
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleEventHandler!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedMaintenance) {
      final maintenanceService = context.read<MaintenanceService>();

      maintenanceService.checkMaintenanceStatus(forceCheck: true).then((_) {
        if (mounted) {
          try {
            _maintenanceChecker.initialize();
            setState(() { _hasInitializedMaintenance = true; });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _maintenanceChecker.triggerMaintenanceCheck(uiContext: context);
              }
            });
          } catch (e) {
            debugPrint("Error initializing MaintenanceCheckerService: $e");
          }
        }
      }).catchError((error) {
        debugPrint("Error during initial maintenance check: $error");
        if (mounted) {
          setState(() { _hasInitializedMaintenance = true; });
        }
      });
    }

    // 监听 MaintenanceService 变化，并触发带 Context 的检查
    context.watch<MaintenanceService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasInitializedMaintenance) {
        _maintenanceChecker.triggerMaintenanceCheck(uiContext: context);
      }
    });
  }

  @override
  void dispose() {
    if (_lifecycleEventHandler != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleEventHandler!);
    }
    _maintenanceChecker.dispose();
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

          // --- *** 构建新的维护显示 Widget *** ---
          final maintenanceContent = Material( // 保证有 Material 祖先
            color: Theme.of(context).scaffoldBackgroundColor, // 使用背景色
            child: MaintenanceDisplay(
              maintenanceInfo: info,
              remainingMinutes: maintenanceService.remainingMinutes,
            ),
          );
          // --- *** 结束构建 *** ---


          // 根据平台决定是否用 DesktopFrameLayout 包裹
          return isDesktop
              ? DesktopFrameLayout(
            showSidebar: false,
            showTitleBarActions: false,
            // titleText: "系统维护中", // 可选自定义标题
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