// lib/widgets/ui/buttons/login_prompt.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
// 确保 FunctionalButton 的导入路径正确
import 'functional_button.dart'; // 或者更具体的路径，例如 '../functional_button.dart' 或 '../../path/to/functional_button.dart'

class LoginPrompt extends StatelessWidget {
  final String message;
  final String buttonText;
  final VoidCallback? onLoginPressed;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double opacity;
  final BorderRadius? borderRadius;

  const LoginPrompt({
    super.key,
    this.message = '登录后继续操作',
    this.buttonText = '登录',
    this.onLoginPressed,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor = Colors.white,
    this.opacity = 1.0,
    this.borderRadius,
    // (可选) 如果添加了上面的参数，这里也要加上
    // this.buttonIcon = Icons.login, // 设置默认图标
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withSafeOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              // --- 将 ElevatedButton 替换为 FunctionalButton ---
              FunctionalButton(
                onPressed: onLoginPressed ?? () => NavigationUtils.navigateToLogin(context),
                label: buttonText,
                icon: Icons.login, // 使用默认的登录图标，或者使用 buttonIcon 参数
              ),
            ],
          ),
        ),
      ),
    );
  }
}