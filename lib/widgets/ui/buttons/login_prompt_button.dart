// lib/widgets/ui/buttons/login_prompt_button.dart

/// 该文件定义了 LoginPromptButton 组件，一个用于提示用户登录的按钮。
/// LoginPromptButton 显示一条消息和登录按钮，用于引导用户进行登录操作。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具

/// `LoginPromptButton` 类：提示用户登录的按钮组件。
///
/// 该组件提供一条消息和登录按钮，点击按钮可导航到登录页面或执行自定义回调。
class LoginPromptButton extends StatelessWidget {
  final String message; // 提示消息
  final String buttonText; // 按钮文本
  final VoidCallback? onLoginPressed; // 登录按钮点击回调
  final EdgeInsetsGeometry padding; // 内边距
  final Color backgroundColor; // 背景色
  final double opacity; // 透明度
  final BorderRadius? borderRadius; // 边框圆角

  /// 构造函数。
  ///
  /// [message]：消息。
  /// [buttonText]：按钮文本。
  /// [onLoginPressed]：登录回调。
  /// [padding]：内边距。
  /// [backgroundColor]：背景色。
  /// [opacity]：透明度。
  /// [borderRadius]：圆角。
  const LoginPromptButton({
    super.key,
    this.message = '登录后继续操作',
    this.buttonText = '登录',
    this.onLoginPressed,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor = Colors.white,
    this.opacity = 1.0,
    this.borderRadius,
  });

  /// 构建登录提示按钮。
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity, // 透明度
      child: Container(
        padding: padding, // 内边距
        decoration: BoxDecoration(
          color: backgroundColor, // 背景色
          borderRadius: borderRadius ?? BorderRadius.circular(12), // 圆角
          boxShadow: [
            // 阴影
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
            crossAxisAlignment: CrossAxisAlignment.center, // 水平居中
            children: [
              Text(
                message, // 消息文本
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center, // 文本居中
              ),
              const SizedBox(height: 12), // 间距
              FunctionalButton(
                onPressed: onLoginPressed ?? // 点击回调
                    () => NavigationUtils.navigateToLogin(context), // 导航到登录页面
                label: buttonText, // 按钮文本
                icon: Icons.login, // 登录图标
              ),
            ],
          ),
        ),
      ),
    );
  }
}
