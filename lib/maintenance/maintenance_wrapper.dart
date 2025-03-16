// lib/widgets/maintenance/maintenance_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/main/maintenance/maintenance_checker_service.dart';
import '../../services/main/maintenance/maintenance_service.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初始化维护检查器
    _maintenanceChecker.initialize(context);

    // 每次应用进入前台时，都检查维护状态
    WidgetsBinding.instance.addObserver(LifecycleEventHandler(
      resumeCallBack: () async {
        // 应用回到前台时，进行维护状态检查
        final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);
        await maintenanceService.checkMaintenanceStatus();
        return Future.value(true);
      },
    ));
  }

  @override
  void dispose() {
    // 释放资源
    _maintenanceChecker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 这个包装器只是传递子部件，实际检查由MaintenanceCheckerService负责
    return widget.child;
  }
}