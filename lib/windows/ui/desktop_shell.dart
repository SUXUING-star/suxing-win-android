// lib/widgets/ui/desktop_shell.dart (或你放的地方)
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'windows_controls.dart'; // 确保导入

class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // *** 去掉 Directionality 包裹 ***
    return DragToMoveArea( // 直接返回 DragToMoveArea
      child: Stack(
        children: [
          // 主要内容
          Positioned.fill(
            child: child, // 这个 child 是从 MaterialApp builder 传进来的
          ),
          // 窗口控件
          const Positioned(
            top: 0,
            right: 0,
            child: WindowsControls(),
          ),
        ],
      ),
    );
  }
}