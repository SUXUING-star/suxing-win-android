// lib/widgets/common/appbar/desktop_app_bar.dart
import 'package:flutter/material.dart';

class DesktopAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const DesktopAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 返回按钮
          if (showBackButton && Navigator.of(context).canPop())
            Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Color(0xFF4E9DE3)),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '返回上一页',
              ),
            ),

          // 页面标题
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E9DE3),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 额外的操作按钮
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}