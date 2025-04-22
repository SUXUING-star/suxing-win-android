// lib/wrapper/maintenance_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/layouts/desktop/desktop_frame_layout.dart';
import 'package:suxingchahui/utils/datetime/date_time_formatter.dart'; // 确保引入格式化工具
import 'package:suxingchahui/utils/device/device_utils.dart';
import '../services/main/maintenance/maintenance_checker_service.dart';
import '../services/main/maintenance/maintenance_service.dart';
import '../providers/auth/auth_provider.dart';
import '../models/maintenance/maintenance_info.dart'; // 引入 MaintenanceInfo 模型

// 添加生命周期处理器 (这部分不变)
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
  final Widget child;

  const MaintenanceWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  final MaintenanceCheckerService _maintenanceChecker =
      MaintenanceCheckerService();
  bool _hasInitializedMaintenance = false;
  LifecycleEventHandler? _lifecycleEventHandler; // 保存引用以便移除

  @override
  void initState() {
    super.initState();
    // 在 initState 中创建，在 dispose 中移除
    _lifecycleEventHandler = LifecycleEventHandler(
      resumeCallBack: () async {
        // 应用回到前台时，进行维护状态检查，但避免重复检查
        // 确保 context 仍然有效并且 _hasInitializedMaintenance 为 true
        if (mounted && _hasInitializedMaintenance) {
          final maintenanceService =
              Provider.of<MaintenanceService>(context, listen: false);
          await maintenanceService.checkMaintenanceStatus();
        }
        // Flutter 3.0+ 需要返回 Future<void>，旧版本可能是 Future<bool>
        // return Future.value(true); // 如果需要返回 bool
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleEventHandler!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedMaintenance) {
      // 获取服务实例
      final maintenanceService =
          Provider.of<MaintenanceService>(context, listen: false);

      // 先执行初始维护检查
      maintenanceService.checkMaintenanceStatus(forceCheck: true).then((_) {
        // 只有在维护服务完成初始检查后才初始化维护检查器
        // 并且确保 widget 仍然挂载
        if (mounted) {
          // 确保 context 仍然有效
          try {
            _maintenanceChecker.initialize(context);
            setState(() {
              // 更新状态，触发可能的 UI 重建（如果初始检查后就在维护）
              _hasInitializedMaintenance = true;
            });
          } catch (e) {
            debugPrint(
                "Error initializing MaintenanceCheckerService in didChangeDependencies: $e");
            // 处理 context 可能失效的情况
          }
        }
      }).catchError((error) {
        debugPrint("Error during initial maintenance check: $error");
        // 即使初始检查失败，也标记为已完成，避免阻塞
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
    // 移除监听器
    if (_lifecycleEventHandler != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleEventHandler!);
    }
    // 释放资源
    _maintenanceChecker.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getMaintenanceVisuals(String maintenanceType) {
    switch (maintenanceType) {
      case 'emergency':
        return {'icon': Icons.warning_amber_rounded, 'color': Colors.red};
      case 'upgrade':
        return {'icon': Icons.system_update_alt, 'color': Colors.blue};
      case 'scheduled':
      default:
        return {'icon': Icons.schedule, 'color': Colors.orange};
    }
  }

  // --- 新增：辅助方法，用于格式化剩余时间 ---
  String _formatRemainingTime(int minutes) {
    if (minutes <= 0) return "即将结束";
    if (minutes < 60) {
      return "$minutes 分钟";
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return "$hours 小时";
      }
      return "$hours 小时 $remainingMinutes 分钟";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktop; // 在这里判断平台

    return Consumer2<MaintenanceService, AuthProvider>(
      builder: (context, maintenanceService, authProvider, child) {
        final bool isAdmin = authProvider.isAdmin || authProvider.isSuperAdmin;
        final MaintenanceInfo? info = maintenanceService.maintenanceInfo;

        // --- 判断是否需要显示维护界面 ---
        if (maintenanceService.isInMaintenance &&
            !maintenanceService.allowLogin &&
            !isAdmin) {
          // --- 构建维护界面内容 ---
          Widget maintenanceContent;
          if (info == null && maintenanceService.isChecking) {
            maintenanceContent = const Material(
                child: Center(child: CircularProgressIndicator()));
          } else if (info == null) {
            maintenanceContent = const Material(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.construction, size: 64, color: Colors.amber),
                      SizedBox(height: 16),
                      Text(
                        '系统维护中',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '获取维护详情失败，请稍后再试。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // --- 构建详细维护内容 (无 Frame ) ---
            final visuals = _getMaintenanceVisuals(info.maintenanceType);
            maintenanceContent = Material(
              // 直接返回 Material 内容
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 不再需要条件 SizedBox for padding here, DesktopFrameLayout handles it
                      Icon(visuals['icon'], size: 64, color: visuals['color']),
                      const SizedBox(height: 20),
                      Text(_getMaintenanceTitle(info.maintenanceType),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(info.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 24),
                      _buildTimeInfo(context, "预计结束时间:",
                          DateTimeFormatter.formatStandard(info.endTime)),
                      if (maintenanceService.remainingMinutes > 0) ...[
                        const SizedBox(height: 8),
                        _buildTimeInfo(
                            context,
                            "预计剩余时间:",
                            _formatRemainingTime(
                                maintenanceService.remainingMinutes)),
                      ],
                      const SizedBox(height: 30),
                      Text("给您带来不便，敬请谅解。",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          }

          // *** 根据平台决定是否用 DesktopFrameLayout 包裹 ***
          return isDesktop
              ? DesktopFrameLayout(
                  showSidebar: false, // 不显示侧边栏
                  showTitleBarActions: false, // 不显示动作按钮
                  // 可以自定义标题栏
                  // titleText: "系统维护中",
                  child: maintenanceContent, // 把内容传进去
                )
              : maintenanceContent; // 非桌面直接显示内容
        }

        // --- 不在维护模式或允许访问 ---
        return child!; // 返回 Consumer 传入的 child
      },
      child: widget.child, // 把 widget.child 传给 Consumer
    );
  }

  // --- 新增：辅助方法，获取维护标题 ---
  String _getMaintenanceTitle(String maintenanceType) {
    switch (maintenanceType) {
      case 'emergency':
        return '系统紧急维护中';
      case 'upgrade':
        return '系统升级维护中';
      case 'scheduled':
      default:
        return '系统维护中';
    }
  }

  // --- 新增：辅助方法，构建时间信息行 ---
  Widget _buildTimeInfo(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 居中显示
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
