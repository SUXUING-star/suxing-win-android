// lib/widgets/ui/pull_out_menu_host.dart
import 'package:flutter/material.dart';
import 'edge_pull_out_panel.dart'; // 引入上面的面板组件

class PullOutMenuHost extends StatelessWidget {
  /// 你的主要页面内容，通常是一个 Scaffold。
  final Widget pageContent;

  /// 要在侧拉菜单中显示的子项列表。
  final List<Widget> menuItems;

  // --- 以下为 EdgePullOutPanel 的配置参数 ---
  final Color panelColor;
  final Color handleColor;
  final IconData handleIconOpened;
  final IconData handleIconClosed;
  final double handleWidth;
  final double handleVisibleHeight;
  final double panelContentWidth;
  final Duration animationDuration;
  final Curve animationCurve;
  final double topOffset;
  final double itemSpacing;
  final bool initiallyOpen;
  final BorderRadiusGeometry? panelBorderRadius;
  final List<BoxShadow>? panelBoxShadow;

  const PullOutMenuHost({
    Key? key,
    required this.pageContent,
    required this.menuItems,
    // 从 EdgePullOutPanel 复制默认值
    this.panelColor = const Color(0xFF303030),
    this.handleColor = Colors.teal,
    this.handleIconOpened = Icons.chevron_right,
    this.handleIconClosed = Icons.chevron_left,
    this.handleWidth = 32.0,
    this.handleVisibleHeight = 56.0,
    this.panelContentWidth = 220.0,
    this.animationDuration = const Duration(milliseconds: 280),
    this.animationCurve = Curves.easeInOutCubic,
    this.topOffset = 100.0,
    this.itemSpacing = 10.0,
    this.initiallyOpen = false,
    this.panelBorderRadius,
    this.panelBoxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        pageContent, // 你的 Scaffold 在底层
        // EdgePullOutPanel 会自己处理 Positioned 和动画
        EdgePullOutPanel(
          children: menuItems,
          panelColor: panelColor,
          handleColor: handleColor,
          handleIconOpened: handleIconOpened,
          handleIconClosed: handleIconClosed,
          handleWidth: handleWidth,
          handleVisibleHeight: handleVisibleHeight,
          panelContentWidth: panelContentWidth,
          animationDuration: animationDuration,
          animationCurve: animationCurve,
          topOffset: topOffset,
          itemSpacing: itemSpacing,
          initiallyOpen: initiallyOpen,
          panelBorderRadius: panelBorderRadius,
          panelBoxShadow: panelBoxShadow,
        ),
      ],
    );
  }
}
