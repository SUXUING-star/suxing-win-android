// lib/widgets/common/appbar/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../../utils/device/device_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize {
    // 桌面平台主页不显示AppBar
    if (DeviceUtils.isDesktop && _isMainPage(title)) {
      return Size.zero;
    }

    // 移动平台保持原有的尺寸计算
    double height = Platform.isAndroid &&
        WidgetsBinding.instance.window.physicalSize.width >
            WidgetsBinding.instance.window.physicalSize.height
        ? kToolbarHeight * 0.8
        : kToolbarHeight;

    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }

    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    // 桌面平台主页不显示AppBar
    if (DeviceUtils.isDesktop && _isMainPage(title)) {
      return SizedBox.shrink();
    }

    // 移动平台或桌面平台的二级页面正常显示AppBar
    final bool isAndroidLandscape = Platform.isAndroid &&
        MediaQuery.of(context).orientation == Orientation.landscape;

    final double fontSize = isAndroidLandscape ? 18.0 : 20.0;
    final double bottomHeight = isAndroidLandscape ? 2.0 : 4.0;

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
      leading: leading,
      actions: actions,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: preferredSize.height - (bottom?.preferredSize.height ?? 0),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF6AB7F0),
              Color(0xFF4E9DE3),
            ],
          ),
        ),
      ),
      bottom: bottom ?? PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight),
        child: Opacity(
          opacity: 0.7,
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: bottomHeight / 4,
          ),
        ),
      ),
    );
  }

  // 判断是否是主页面（根据标题）
  bool _isMainPage(String title) {
    // 主页面标题列表
    final List<String> mainPageTitles = [
      '首页',
      '游戏',
      '外部链接',
      '论坛',
      '帖子',
      '动态',
      '个人中心',
      '我的',
    ];

    return mainPageTitles.contains(title);
  }
}