// lib/widgets/ui/components/badge/share_code_badge.dart

/// 定义了 [ShareCodeBadge] 组件，一个用于触发“使用分享口令”功能的专用UI组件。
library;

import 'package:flutter/material.dart';
import 'package:suxingchahui/widgets/ui/utils/share_code_handler.dart';

/// 一个专用的徽章按钮，用于打开“使用分享口令”对话框。
///
/// 点击时会调用 [ShareCodeHandler.showShareCodeInputDialog]。
class ShareCodeBadge extends StatelessWidget {
  /// 构造函数。
  const ShareCodeBadge({super.key});

  /// 构建徽章按钮的用户界面。
  @override
  Widget build(BuildContext context) {
    const double diameter = 24.0;
    const double iconSize = 16.0;
    final Color backgroundColor = Colors.blue.shade400;
    const Color iconColor = Colors.white;

    return GestureDetector(
      onTap: () => ShareCodeHandler.showShareCodeInputDialog(context),
      child: Tooltip(
        message: '使用分享口令',
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.qr_code,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
