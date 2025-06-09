// lib/screens/auth/forgot_password_screen.dart

/// 该文件定义了 ForgotPasswordScreen 组件，一个用于找回密码的屏幕。
/// ForgotPasswordScreen 负责处理密码重置流程，包括发送验证码和验证。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/providers/user/user_info_provider.dart'; // 导入用户信息 Provider
import 'dart:async'; // 导入 Timer
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // 导入功能文本按钮
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 导入表单文本输入框组件
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart'; // 导入应用 SnackBar 工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:suxingchahui/services/main/email/email_service.dart'; // 导入邮箱服务
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件

/// `ForgotPasswordScreen` 类：找回密码屏幕组件。
///
/// 该屏幕提供邮箱输入、验证码发送和验证功能，以引导用户重置密码。
class ForgotPasswordScreen extends StatefulWidget {
  final InputStateService inputStateService; // 输入状态服务
  final UserInfoProvider infoProvider; // 用户信息 Provider
  final EmailService emailService; // 邮箱服务
  final AuthProvider authProvider; // 认证 Provider
  /// 构造函数。
  ///
  /// [inputStateService]：输入状态服务。
  /// [emailService]：邮箱服务。
  /// [infoProvider]：用户信息 Provider。
  /// [authProvider]：认证 Provider。
  const ForgotPasswordScreen({
    super.key,
    required this.inputStateService,
    required this.emailService,
    required this.infoProvider,
    required this.authProvider,
  });

  /// 创建状态。
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

/// `_ForgotPasswordScreenState` 类：`ForgotPasswordScreen` 的状态管理。
///
/// 管理表单验证、输入控制器、验证码发送、验证和计时器。
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // 表单键
  final _emailController = TextEditingController(); // 邮箱输入控制器
  final _codeController = TextEditingController(); // 验证码输入控制器
  String? _error; // 错误消息
  bool _codeSent = false; // 验证码是否已发送
  int _countDown = 0; // 倒计时
  Timer? _timer; // 计时器
  bool _isSendingCode = false; // 是否正在发送验证码
  bool _isVerifying = false; // 是否正在验证

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
    _emailController.dispose(); // 销毁邮箱输入控制器
    _codeController.dispose(); // 销毁验证码输入控制器
    _timer?.cancel(); // 取消计时器
    super.dispose();
  }

  /// 启动倒计时。
  ///
  /// 设置倒计时为 60 秒，并每秒更新一次。
  void _startTimer() {
    _countDown = 60; // 倒计时初始值
    _timer?.cancel(); // 取消现有计时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        // 组件未挂载时取消计时器
        timer.cancel();
        return;
      }
      setState(() {
        if (_countDown > 0) {
          _countDown--; // 倒计时递减
        } else {
          _timer?.cancel(); // 倒计时结束时取消计时器
        }
      });
    });
  }

  /// 发送验证码。
  ///
  /// 验证邮箱格式，调用邮箱服务发送验证码，并处理结果。
  Future<void> _sendVerificationCode() async {
    final email = _emailController.text; // 获取邮箱
    if (email.isEmpty || !email.contains('@')) {
      // 邮箱格式无效时
      setState(() => _error = '请输入有效的邮箱地址'); // 设置错误消息
      AppSnackBar.showWarning('请输入有效的邮箱地址'); // 显示警告
      return;
    }

    setState(() {
      _isSendingCode = true; // 设置发送验证码状态
      _error = null; // 清空错误消息
    });

    try {
      await widget.emailService
          .requestVerificationCode(_emailController.text, 'reset'); // 请求验证码
      if (!mounted) return; // 组件未挂载时返回
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // 再次检查挂载状态
        _startTimer(); // 启动倒计时
        setState(() {
          _codeSent = true; // 标记验证码已发送
          _error = null; // 清空错误消息
        });
        AppSnackBar.showSuccess("验证码已发送至您的邮箱，请去查看！"); // 显示成功提示
      });
    } catch (e) {
      if (!mounted) return; // 组件未挂载时返回
      setState(() => _error = '发送验证码失败: ${e.toString()}'); // 设置错误消息
      AppSnackBar.showError(_error!); // 显示错误提示
    } finally {
      if (mounted) {
        // 确保加载状态重置
        setState(() => _isSendingCode = false);
      }
    }
  }

  /// 验证验证码。
  ///
  /// 验证表单、检查验证码是否已发送，并调用邮箱服务验证。
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return; // 表单验证失败时返回
    if (!_codeSent) {
      // 验证码未发送时
      setState(() => _error = '请先获取验证码'); // 设置错误消息
      AppSnackBar.showWarning(_error!); // 显示警告
      return;
    }

    setState(() {
      _isVerifying = true; // 设置验证状态
      _error = null; // 清空错误消息
    });

    try {
      final bool isCodeValid = await widget.emailService.verifyCode(
          _emailController.text, _codeController.text, 'reset'); // 验证验证码
      if (!mounted) return; // 组件未挂载时返回

      if (isCodeValid) {
        // 验证码有效时
        NavigationUtils.pushReplacementNamed(context, AppRoutes.resetPassword,
            arguments: _emailController.text); // 导航到重置密码页面
      } else {
        // 验证码无效时
        setState(() => _error = '验证码错误或已过期'); // 设置错误消息
        AppSnackBar.showError(_error!); // 显示错误提示
      }
    } catch (e) {
      // 捕获验证错误
      if (!mounted) return; // 组件未挂载时返回
      setState(() => _error = '验证码校验时发生错误: ${e.toString()}'); // 设置错误消息
      AppSnackBar.showError(_error!); // 显示错误提示
    } finally {
      if (mounted) {
        // 确保加载状态重置
        setState(() => _isVerifying = false);
      }
    }
  }

  /// 构建邮箱表单字段。
  ///
  /// [isOverallLoading]：是否整体加载中。
  Widget _buildEmailFormField(bool isOverallLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      controller: _emailController, // 控制器
      isEnabled: !_isSendingCode && !_isVerifying, // 根据加载状态禁用
      decoration: const InputDecoration(
        labelText: '输入邮箱', // 标签文本
        prefixIcon: Icon(Icons.email_outlined), // 前缀图标
      ),
      keyboardType: TextInputType.emailAddress, // 键盘类型
      textInputAction: TextInputAction.next, // 文本输入动作
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty || !value.contains('@')) {
          return '请输入有效的邮箱地址';
        }
        return null;
      },
    );
  }

  /// 构建验证码表单字段。
  ///
  /// [isOverallLoading]：是否整体加载中。
  Widget _buildVerificationCodeField(bool isOverallLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      controller: _codeController, // 控制器
      isEnabled: !isOverallLoading, // 根据加载状态禁用
      decoration: const InputDecoration(
        labelText: '邮箱验证码', // 标签文本
        prefixIcon: Icon(Icons.pin_outlined), // 前缀图标
      ),
      keyboardType: TextInputType.number, // 键盘类型
      maxLength: 6, // 最大长度
      textInputAction: TextInputAction.done, // 文本输入动作
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty) return '请输入验证码';
        if (value.length != 6) return '验证码应为6位数字';
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

  /// 构建找回密码屏幕的主体 UI。
  @override
  Widget build(BuildContext context) {
    final bool isOverallLoading = _isSendingCode || _isVerifying; // 是否整体加载中

    final String sendButtonLabel = _codeSent
        ? (_countDown > 0 ? '${_countDown}s' : '重新发送')
        : '发送验证码'; // 发送验证码按钮文本
    final bool isSendButtonEnabled =
        !isOverallLoading && _countDown <= 0; // 发送按钮是否启用
    final bool isVerifyButtonEnabled =
        !isOverallLoading && _codeSent; // 验证按钮是否启用

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
      appBar: const CustomAppBar(title: '找回密码'), // AppBar
      body: Stack(
        children: [
          if (isOverallLoading) // 如果正在加载，显示全屏加载组件
            const FadeInItem(
                child: LoadingWidget(
              isOverlay: true,
              message: '正在拼命加载...',
              overlayOpacity: 0.4,
              size: 36,
            )),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), // 约束最大宽度
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
                          child: const AppText('找回密码',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87), // 标题
                        ),
                        const SizedBox(height: 16), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger, // 延迟
                          child: const AppText('通过邮箱重置您的密码',
                              fontSize: 16, color: Colors.grey), // 副标题
                        ),
                        const SizedBox(height: 24), // 间距

                        _buildErrorMessageField(), // 错误消息字段

                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 2, // 延迟
                          child:
                              _buildEmailFormField(isOverallLoading), // 邮箱输入框
                        ),
                        const SizedBox(height: 16), // 间距

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300), // 动画时长
                          curve: Curves.easeInOut, // 动画曲线
                          child: AnimatedOpacity(
                            opacity: _codeSent ? 1.0 : 0.0, // 透明度
                            duration: const Duration(milliseconds: 300), // 动画时长
                            child: _codeSent // 验证码已发送时显示验证码输入框
                                ? FadeInSlideUpItem(
                                    key: const ValueKey(
                                        'verification_code_field'), // 唯一键
                                    delay: Duration.zero, // 延迟
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 16.0), // 底部内边距
                                      child: _buildVerificationCodeField(
                                          isOverallLoading), // 验证码输入框
                                    ),
                                  )
                                : const SizedBox.shrink(), // 否则返回空组件
                          ),
                        ),

                        FadeInSlideUpItem(
                          delay: initialDelay +
                              stagger * (_codeSent ? 4 : 3), // 延迟
                          child: Row(
                            children: [
                              Expanded(
                                child: FunctionalButton(
                                  onPressed: _sendVerificationCode, // 点击发送验证码
                                  label: sendButtonLabel, // 按钮文本
                                  isLoading: _isSendingCode, // 加载状态
                                  isEnabled: isSendButtonEnabled, // 启用状态
                                ),
                              ),
                              AnimatedOpacity(
                                opacity: _codeSent ? 1.0 : 0.0, // 透明度
                                duration:
                                    const Duration(milliseconds: 300), // 动画时长
                                child: _codeSent
                                    ? Row(
                                        mainAxisSize:
                                            MainAxisSize.min, // 行主轴尺寸最小化
                                        children: [
                                          const SizedBox(width: 16), // 间距
                                          FunctionalButton(
                                            onPressed: _verifyCode, // 点击验证
                                            label: '验证', // 按钮文本
                                            isLoading: _isVerifying, // 加载状态
                                            isEnabled:
                                                isVerifyButtonEnabled, // 启用状态
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(), // 否则返回空组件
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16), // 间距

                        FadeInSlideUpItem(
                          delay: initialDelay +
                              stagger * (_codeSent ? 5 : 4), // 延迟
                          child: FunctionalTextButton(
                            onPressed: () =>
                                NavigationUtils.pop(context), // 点击返回登录
                            label: '返回登录', // 按钮文本
                            isEnabled: !isOverallLoading, // 启用状态
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
