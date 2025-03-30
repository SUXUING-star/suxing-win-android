// lib/wrapper/maintenance_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/main/maintenance/maintenance_checker_service.dart';
import '../services/main/maintenance/maintenance_service.dart';
import '../providers/auth/auth_provider.dart';

// 添加生命周期处理器
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
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<MaintenanceWrapper> createState() => _MaintenanceWrapperState();
}

class _MaintenanceWrapperState extends State<MaintenanceWrapper> {
  final MaintenanceCheckerService _maintenanceChecker = MaintenanceCheckerService();
  bool _hasInitializedMaintenance = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitializedMaintenance) {
      // 先执行初始维护检查，避免重复调用
      final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);
      maintenanceService.checkMaintenanceStatus(forceCheck: true).then((_) {
        // 只有在维护服务完成初始检查后才初始化维护检查器
        _maintenanceChecker.initialize(context);
        _hasInitializedMaintenance = true;
      });

      // 每次应用进入前台时，都检查维护状态
      WidgetsBinding.instance.addObserver(LifecycleEventHandler(
        resumeCallBack: () async {
          // 应用回到前台时，进行维护状态检查，但避免重复检查
          if (_hasInitializedMaintenance) {
            final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);
            await maintenanceService.checkMaintenanceStatus();
          }
          return Future.value(true);
        },
      ));
    }
  }

  @override
  void dispose() {
    // 释放资源
    _maintenanceChecker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceService = Provider.of<MaintenanceService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // 检查是否是管理员，如果是管理员则始终允许访问
    final bool isAdmin = authProvider.isAdmin || authProvider.isSuperAdmin;

    // 如果在维护模式下且不允许登录，且不是管理员，则显示维护界面
    if (maintenanceService.isInMaintenance && !maintenanceService.allowLogin && !isAdmin) {
      return Material(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.amber),
              SizedBox(height: 16),
              Text(
                '系统维护中',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                maintenanceService.maintenanceInfo?.message ?? '系统正在维护，请稍后再试',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              // 为管理员提供绕过入口
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }


}