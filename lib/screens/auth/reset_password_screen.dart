// lib/screens/auth/reset_password_screen.dart

/// 该文件定义了 ResetPasswordScreen 组件，一个用于重置密码的屏幕。
/// ResetPasswordScreen 负责处理新密码的设置和密码重置流程。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 导入表单文本输入框组件
import 'package:suxingchahui/widgets/ui/snackBar/app_snack_bar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:suxingchahui/services/main/user/user_service.dart'; // 导入用户服务
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件

/// `ResetPasswordScreen` 类：重置密码屏幕组件。
///
/// 该屏幕提供新密码和确认密码输入，并处理密码重置操作。
class ResetPasswordScreen extends StatefulWidget {
  final String email; // 用于重置密码的邮箱
  final UserService userService; // 用户服务
  final InputStateService inputStateService; // 输入状态服务
  final AuthProvider authProvider; // 认证 Provider

  /// 构造函数。
  ///
  /// [email]：邮箱。
  /// [userService]：用户服务。
  /// [inputStateService]：输入状态服务。
  /// [authProvider]：认证 Provider。
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.userService,
    required this.inputStateService,
    required this.authProvider,
  });

  /// 创建状态。
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

/// `_ResetPasswordScreenState` 类：`ResetPasswordScreen` 的状态管理。
///
/// 管理表单验证、输入控制器、加载状态和密码重置流程。
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // 表单键
  final _passwordController = TextEditingController(); // 密码输入控制器
  final _confirmPasswordController = TextEditingController(); // 确认密码输入控制器
  String? _error; // 错误消息
  bool _obscurePassword = true; // 隐藏密码状态
  bool _obscureConfirmPassword = true; // 隐藏确认密码状态
  bool _isLoading = false; // 加载状态

  bool _hasInitializedDependencies = false; // 依赖初始化标记

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      // 依赖未初始化时
      _hasInitializedDependencies = true; // 标记为已初始化
    }
  }

  @override
  void dispose() {
    _passwordController.dispose(); // 销毁密码输入控制器
    _confirmPasswordController.dispose(); // 销毁确认密码输入控制器
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ResetPasswordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.email != widget.email) {
      // 邮箱变化时
      setState(() {});
    }
  }

  /// 重置密码。
  ///
  /// 验证表单，调用用户服务进行密码重置，并处理结果。
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return; // 表单验证失败时返回

    setState(() {
      _isLoading = true; // 设置加载状态
      _error = null; // 清空错误消息
    });

    try {
      await widget.userService.resetPassword(
        widget.email,
        _passwordController.text,
      ); // 调用用户服务重置密码

      AppSnackBar.showSuccess("重置密码成功，用新的密码进行登录吧！");

      if (!mounted) return; // 组件未挂载时返回
      NavigationUtils.navigateToLogin(context); // 导航到登录页面
    } catch (e) {
      // 捕获重置密码失败异常
      setState(() {
        _error = '重置密码失败：${e.toString()}'; // 设置错误消息
      });
      AppSnackBar.showError("重置密码失败,${e.toString()}");
    } finally {
      // 无论成功失败，确保加载状态重置
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 构建新密码表单字段。
  Widget _buildNewPassWordFormField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      controller: _passwordController, // 控制器
      isEnabled: !_isLoading, // 根据加载状态禁用
      obscureText: _obscurePassword, // 隐藏密码
      decoration: InputDecoration(
        labelText: '新密码', // 标签文本
        prefixIcon: const Icon(Icons.lock), // 前缀图标
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword
              ? Icons.visibility_off
              : Icons.visibility), // 切换密码可见性图标
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword; // 切换隐藏密码状态
            });
          },
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // 键盘类型
      textInputAction: TextInputAction.next, // 文本输入动作
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty) return '请输入新密码';
        if (value.length < 6) return '密码长度至少6位';
        if (value.length > 30) return '密码长度过长';
        return null;
      },
    );
  }

  /// 构建重复密码表单字段。
  Widget _buildRepeatPassWordFormField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      controller: _confirmPasswordController, // 控制器
      isEnabled: !_isLoading, // 根据加载状态禁用
      obscureText: _obscureConfirmPassword, // 隐藏确认密码
      decoration: InputDecoration(
        labelText: '确认新密码', // 标签文本
        prefixIcon: const Icon(Icons.lock), // 前缀图标
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword
              ? Icons.visibility_off
              : Icons.visibility), // 切换确认密码可见性图标
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword; // 切换隐藏确认密码状态
            });
          },
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // 键盘类型
      textInputAction: TextInputAction.done, // 文本输入动作
      validator: (value) {
        // 验证器
        if (value != _passwordController.text) {
          return '两次输入的密码不一致'; // 检查两次密码是否一致
        }
        return null;
      },
    );
  }

  /// 构建错误消息字段。
  ///
  /// 如果存在错误消息，则显示淡入动画的内联错误组件。
  Widget _buildErrorMessageField() {
    return _error != null
        ? FadeInItem(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // 底部内边距
              child: InlineErrorWidget(
                errorMessage: _error!, // 错误消息
                icon: Icons.error_outline, // 图标
                iconColor: Colors.red, // 颜色
              ),
            ),
          )
        : const SizedBox.shrink(); // 否则返回空组件
  }

  /// 构建重置密码屏幕的主体 UI。
  @override
  Widget build(BuildContext context) {
    const Duration initialDelay = Duration(milliseconds: 200); // 初始延迟
    const Duration stagger = Duration(milliseconds: 80); // 交错延迟

    if (widget.authProvider.isLoggedIn) {
      // 如果用户已登录
      return CustomErrorWidget(
        title: "停停停", // 标题
        errorMessage: "好像你已经登录了啊？？", // 错误消息
        onRetry: () => NavigationUtils.of(context), // 点击重试回调
        retryText: "返回上一页", // 重试按钮文本
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: '重置密码',
      ), // AppBar
      body: Stack(
        children: [
          if (_isLoading) // 如果正在加载，显示全屏加载组件
            const FadeInItem(
              // 全屏加载组件
              child: LoadingWidget(
                isOverlay: true,
                message: "正在重置密码...",
                overlayOpacity: 0.4,
                size: 36,
              ),
            ), //
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450, // 约束最大宽度
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0), // 内边距
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withSafeOpacity(0.9), // 背景色
                    borderRadius: BorderRadius.circular(16), // 圆角
                  ),
                  padding: const EdgeInsets.all(24), // 内边距
                  child: Form(
                    key: _formKey, // 表单键
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化
                      children: [
                        FadeInSlideUpItem(
                          delay: initialDelay, // 延迟
                          child: const AppText(
                            '重置密码', // 标题
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger, // 延迟
                          child: const AppText(
                            '为您的账号设置新密码', // 副标题
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24), // 间距

                        _buildErrorMessageField(), // 错误消息字段

                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 2, // 延迟
                          child: _buildNewPassWordFormField(), // 新密码输入框
                        ),
                        const SizedBox(height: 16), // 间距

                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 3, // 延迟
                          child: _buildRepeatPassWordFormField(), // 确认新密码输入框
                        ),
                        const SizedBox(height: 24), // 间距

                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 4, // 延迟
                          child: FunctionalButton(
                            onPressed: _isLoading
                                ? () => {}
                                : _resetPassword, // 重置密码按钮点击回调
                            label: '重置密码', // 按钮文本
                            isEnabled: !_isLoading, // 启用状态
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
