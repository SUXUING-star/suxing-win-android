import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
  }) : super(key: key);

  @override
  Size get preferredSize {
    return Platform.isAndroid &&
        WidgetsBinding.instance.window.physicalSize.width >
            WidgetsBinding.instance.window.physicalSize.height
        ? Size.fromHeight(kToolbarHeight * 0.8)
        : Size.fromHeight(kToolbarHeight);
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
      toolbarHeight: preferredSize.height,
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
      bottom: PreferredSize(
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