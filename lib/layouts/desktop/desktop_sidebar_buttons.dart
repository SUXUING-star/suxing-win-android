// lib/widgets/layouts/desktop/desktop_sidebar_mobile_buttons.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/components/badge/layout/checkin_badge.dart';
import '../../widgets/components/badge/layout/update_button.dart';
import '../../widgets/components/badge/layout/message_badge.dart';
import '../../widgets/components/indicators/announcement_indicator.dart';
class DesktopSidebarMobileButtons extends StatelessWidget {
  const DesktopSidebarMobileButtons({Key? key}) : super(key: key);

  // 通用的指示器按钮构建方法，添加悬停效果和光标样式
  Widget _buildIndicatorButton(BuildContext context, {required Widget child}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // 点击事件由子组件处理
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white.withOpacity(0.2),
          splashColor: Colors.white.withOpacity(0.3),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // 更新按钮
          _buildIndicatorButton(
            context,
            child: UpdateButton(),
          ),
          SizedBox(height: 16),

          // 公告指示器
          _buildIndicatorButton(
            context,
            child: AnnouncementIndicator(),
          ),
          SizedBox(height: 16),

          // 消息徽章 - 只有在登录时显示
          if (authProvider.isLoggedIn)
            _buildIndicatorButton(
              context,
              child: MessageBadge(),
            ),
          SizedBox(height: 16),
          _buildIndicatorButton(
            context,
            child: CheckInBadge(),
          ),
        ],
      ),
    );
  }
}