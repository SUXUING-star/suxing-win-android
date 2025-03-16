// lib/widgets/common/appbar/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom; // 新增bottom参数

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom, // 添加bottom参数
  }) : super(key: key);

  @override
  Size get preferredSize {
    // 调整首选大小以适应底部组件（如果有）
    double height = Platform.isAndroid &&
        WidgetsBinding.instance.window.physicalSize.width >
            WidgetsBinding.instance.window.physicalSize.height
        ? kToolbarHeight * 0.8
        : kToolbarHeight;

    // 如果有底部组件，则增加高度
    if (bottom != null) {
      height += bottom!.preferredSize.height;
    }

    return Size.fromHeight(height);
  }

  @override
  Widget build(BuildContext context) {
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
      leading: leading != null
          ? Theme(
        data: Theme.of(context).copyWith(
          iconTheme: IconThemeData(
            size: isAndroidLandscape ? 20.0 : 24.0,
          ),
        ),
        child: leading!,
      )
          : null,
      actions: actions != null
          ? actions!.map((widget) => Theme(
        data: Theme.of(context).copyWith(
          iconTheme: IconThemeData(
            size: isAndroidLandscape ? 20.0 : 24.0,
          ),
        ),
        child: widget,
      )).toList()
          : null,
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
      bottom: bottom ?? PreferredSize( // 使用提供的bottom或默认底部边框
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
}