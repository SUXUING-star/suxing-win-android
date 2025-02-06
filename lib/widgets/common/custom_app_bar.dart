// lib/widgets/common/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Size get preferredSize => Size.fromHeight(bottom != null ? kToolbarHeight + 48 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.lightBlueAccent,
      leading: leading,
      actions: actions,
      bottom: bottom,
    );
  }
}