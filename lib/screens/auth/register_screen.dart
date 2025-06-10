// lib/screens/auth/register_screen.dart

/// 该文件定义了 RegisterScreen 组件，一个用于用户注册的屏幕。
/// RegisterScreen 负责处理用户注册流程，包括发送验证码、验证和账号创建。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:suxingchahui/models/user/account.dart'; // 导入账号模型
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // 导入功能文本按钮
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 导入表单文本输入框组件
import 'package:suxingchahui/widgets/ui/snackbar/app_snackBar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart'; // 导入应用文本类型
import 'dart:async'; // 导入 Timer
import 'package:suxingchahui/services/main/email/email_service.dart'; // 导入邮箱服务
import 'package:suxingchahui/services/main/user/user_service.dart'; // 导入用户服务
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入加载组件

/// `RegisterScreen` 类：用户注册屏幕组件。
///
/// 该屏幕提供用户注册所需的所有输入字段，包括用户名、邮箱、密码、确认密码和验证码，
/// 并处理注册流程和结果。
class RegisterScreen extends StatefulWidget {
  final AuthProvider authProvider; // 认证 Provider
  final UserService userService; // 用户服务
  final InputStateService inputStateService; // 输入状态服务
  final EmailService emailService; // 邮箱服务
  /// 构造函数。
  ///
  /// [userService]：用户服务。
  /// [authProvider]：认证 Provider。
  /// [inputStateService]：输入状态服务。
  /// [emailService]：邮箱服务。
  const RegisterScreen({
    super.key,
    required this.userService,
    required this.authProvider,
    required this.inputStateService,
    required this.emailService,
  });

  /// 创建状态。
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

/// `_RegisterScreenState` 类：`RegisterScreen` 的状态管理。
///
/// 管理表单验证、输入状态、验证码发送、注册过程和计时器。
class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // 表单键

  static const String usernameSlotName = 'register_username'; // 用户名输入框槽名称
  static const String emailSlotName = 'register_email'; // 邮箱输入框槽名称
  static const String passwordSlotName = 'register_password'; // 密码输入框槽名称
  static const String confirmPasswordSlotName =
      'register_confirm_password'; // 确认密码输入框槽名称
  static const String verificationCodeSlotName =
      'register_verification_code'; // 验证码输入框槽名称

  String? _error; // 错误消息
  bool _codeSent = false; // 验证码是否已发送
  bool _obscurePassword = true; // 隐藏密码状态
  bool _obscureConfirmPassword = true; // 隐藏确认密码状态
  bool _isSendingCode = false; // 是否正在发送验证码
  bool _isRegistering = false; // 是否正在注册
  bool _rememberMe = true; // 记住账号状态

  Timer? _timer; // 计时器
  int _countDown = 0; // 倒计时

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
    final email =
        widget.inputStateService.getText(emailSlotName).trim(); // 获取邮箱

    if (email.isEmpty || !email.contains('@')) {
      // 邮箱格式无效时显示警告
      AppSnackBar.showWarning('请输入有效的邮箱地址');
      setState(() => _error = '请输入有效的邮箱地址'); // 设置内联错误
      return;
    }

    setState(() {
      _isSendingCode = true; // 设置发送验证码状态
      _error = null; // 清空错误消息
    });

    try {
      await widget.emailService
          .requestVerificationCode(email, 'register'); // 请求验证码
      if (!mounted) return; // 组件未挂载时返回
      _startTimer(); // 启动倒计时
      setState(() {
        _codeSent = true; // 标记验证码已发送
        _error = null; // 清空错误消息
      });
      AppSnackBar.showSuccess("验证码已发送至您的邮箱，请注意查收！");
    } catch (e) {
      if (!mounted) return; // 组件未挂载时返回
      final errorMessage = '发送验证码失败：${e.toString()}'; // 错误消息
      setState(() => _error = errorMessage); // 设置错误消息
      AppSnackBar.showError(errorMessage);
    } finally {
      if (mounted) {
        // 确保加载状态重置
        setState(() => _isSendingCode = false);
      }
    }
  }

  /// 处理注册。
  ///
  /// 验证表单、验证验证码，并调用用户服务进行注册。
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return; // 表单验证失败时返回
    if (!_codeSent) {
      // 验证码未发送时显示警告
      AppSnackBar.showWarning('请先获取验证码');
      return;
    }

    setState(() {
      _isRegistering = true; // 设置注册状态
      _error = null; // 清空错误消息
    });

    final email =
        widget.inputStateService.getText(emailSlotName).trim(); // 获取邮箱
    final username =
        widget.inputStateService.getText(usernameSlotName).trim(); // 获取用户名
    final password = widget.inputStateService.getText(passwordSlotName); // 获取密码
    final verificationCode = widget.inputStateService
        .getText(verificationCodeSlotName)
        .trim(); // 获取验证码

    bool isCodeValid = false; // 验证码是否有效
    String registrationError = ''; // 注册错误消息

    try {
      isCodeValid = await widget.emailService
          .verifyCode(email, verificationCode, 'register'); // 验证验证码
      if (!mounted) return; // 组件未挂载时返回

      if (!isCodeValid) {
        // 验证码无效时
        registrationError = '验证码错误或已过期'; // 错误消息
        setState(() => _error = registrationError); // 设置错误消息
        AppSnackBar.showError(registrationError);
        setState(() => _isRegistering = false); // 结束注册状态
        return;
      }

      SavedAccount? savedAccount; // 已保存账号
      if (_rememberMe) {
        // 记住账号时创建 SavedAccount
        final user = widget.authProvider.currentUser;
        savedAccount = SavedAccount(
          email: email,
          password: password,
          username: user?.username,
          avatarUrl: user?.avatar,
          userId: user?.id,
          level: user?.level,
          experience: user?.experience,
          lastLogin: DateTime.now(),
        );
      }

      await widget.userService
          .signUp(email, password, username, savedAccount); // 调用用户服务注册
      if (!mounted) return; // 组件未挂载时返回

      widget.inputStateService.clearText(usernameSlotName); // 清空用户名输入
      widget.inputStateService.clearText(emailSlotName); // 清空邮箱输入
      widget.inputStateService.clearText(passwordSlotName); // 清空密码输入
      widget.inputStateService.clearText(confirmPasswordSlotName); // 清空确认密码输入
      widget.inputStateService.clearText(verificationCodeSlotName); // 清空验证码输入

      AppSnackBar.showSuccess("注册成功，即将跳转...");
      await Future.delayed(const Duration(milliseconds: 1000)); // 延迟
      if (!mounted) return; // 组件未挂载时返回
      NavigationUtils.pop(context); // 弹出当前路由
    } catch (e) {
      // 捕获注册失败异常
      if (!mounted) return; // 组件未挂载时返回
      registrationError =
          (isCodeValid ? '注册失败：' : '验证码校验出错：') + e.toString(); // 错误消息
      setState(() => _error = registrationError); // 设置错误消息
      AppSnackBar.showError(registrationError);
    } finally {
      if (mounted) {
        // 确保加载状态重置
        setState(() => _isRegistering = false);
      }
    }
  }

  /// 构建密码表单字段。
  ///
  /// [isLoading]：是否正在加载。
  Widget _buildPassWordFormField(bool isLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      slotName: passwordSlotName, // 槽名称
      isEnabled: !isLoading, // 根据加载状态禁用
      obscureText: _obscurePassword, // 隐藏密码
      decoration: InputDecoration(
        labelText: '密码 (至少6位)', // 标签文本
        prefixIcon: const Icon(Icons.lock_outline), // 前缀图标
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined), // 切换密码可见性图标
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword), // 切换隐藏密码状态
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // 键盘类型为可见密码
      textInputAction: TextInputAction.next, // 文本输入动作为下一项
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty) return '请输入密码';
        if (value.length < 6) return '密码长度至少6位';
        if (value.length > 30) return '密码长度过长';
        return null;
      },
    );
  }

  /// 构建验证码表单字段。
  ///
  /// [isLoading]：是否正在加载。
  Widget _buildVerificationCodeField(bool isLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      slotName: verificationCodeSlotName, // 槽名称
      isEnabled: !isLoading && _codeSent, // 根据加载状态和验证码发送状态禁用
      decoration: const InputDecoration(
        labelText: '验证码', // 标签文本
        prefixIcon: Icon(Icons.pin_outlined), // 前缀图标
      ),
      keyboardType: TextInputType.number, // 键盘类型为数字
      maxLength: 6, // 最大长度为 6
      textInputAction: TextInputAction.next, // 文本输入动作为下一项
      validator: (value) {
        // 验证器
        if (!_codeSent) return null; // 验证码未发送时不校验
        if (value == null || value.isEmpty) return '请输入验证码';
        if (value.length != 6) return '验证码应为6位数字';
        return null;
      },
    );
  }

  /// 构建用户名表单字段。
  ///
  /// [isLoading]：是否正在加载。
  Widget _buildUserNameFormField(bool isLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      slotName: usernameSlotName, // 槽名称
      isEnabled: !isLoading, // 根据加载状态禁用
      decoration: const InputDecoration(
        labelText: '用户名', // 标签文本
        prefixIcon: Icon(Icons.person_outline), // 前缀图标
      ),
      textInputAction: TextInputAction.next, // 文本输入动作为下一项
      validator: (value) =>
          (value == null || value.isEmpty) ? '请输入用户名' : null, // 验证器
    );
  }

  /// 构建邮箱表单字段。
  ///
  /// [isLoading]：是否正在加载。
  Widget _buildEmailFormField(bool isLoading) {
    final String sendCodeButtonLabel = _countDown > 0
        ? '${_countDown}s'
        : (_codeSent ? '重新发送' : '发送验证码'); // 发送验证码按钮文本
    final bool isSendCodeButtonEnabled =
        !isLoading && _countDown <= 0; // 发送验证码按钮是否启用

    final emailField = FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      slotName: emailSlotName, // 槽名称
      isEnabled: !isLoading, // 根据加载状态禁用
      decoration: const InputDecoration(
        labelText: '邮箱', // 标签文本
        prefixIcon: Icon(Icons.alternate_email), // 前缀图标
      ),
      keyboardType: TextInputType.emailAddress, // 键盘类型为邮箱
      textInputAction: TextInputAction.next, // 文本输入动作为下一项
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty) return '请输入邮箱';
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(value)) return '请输入有效的邮箱地址';
        return null;
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴顶部对齐
      children: [
        Expanded(
          child: emailField, // 邮箱输入框
        ),
        const SizedBox(width: 12), // 间距
        SizedBox(
          height: 58, // 高度
          child: FunctionalButton(
            onPressed: _sendVerificationCode, // 点击发送验证码
            label: sendCodeButtonLabel, // 按钮文本
            isLoading: _isSendingCode, // 加载状态
            isEnabled: isSendCodeButtonEnabled, // 启用状态
            padding: const EdgeInsets.symmetric(horizontal: 12), // 内边距
            fontSize: 14, // 字体大小
          ),
        ),
      ],
    );
  }

  /// 构建重复密码表单字段。
  ///
  /// [isLoading]：是否正在加载。
  Widget _buildRepeatPassWordFormField(bool isLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      slotName: confirmPasswordSlotName, // 槽名称
      isEnabled: !isLoading, // 根据加载状态禁用
      obscureText: _obscureConfirmPassword, // 隐藏确认密码
      decoration: InputDecoration(
        labelText: '确认密码', // 标签文本
        prefixIcon: const Icon(Icons.lock_outline), // 前缀图标
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined), // 切换确认密码可见性图标
          onPressed: () => setState(() =>
              _obscureConfirmPassword = !_obscureConfirmPassword), // 切换隐藏确认密码状态
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // 键盘类型为可见密码
      textInputAction: TextInputAction.done, // 文本输入动作为完成
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty) return '请再次输入密码';

        final password =
            widget.inputStateService.getText(passwordSlotName); // 获取密码
        if (value != password) return '两次输入的密码不一致'; // 检查两次密码是否一致
        return null;
      },
    );
  }

  /// 构建错误消息字段。
  ///
  /// 根据错误内容显示不同的错误消息和图标。
  Widget _buildErrorMessageField() {
    return _error != null
        ? FadeInItem(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0), // 底部内边距
              child: InlineErrorWidget(
                errorMessage: _error!.contains('验证码错误') // 根据错误内容显示不同消息
                    ? '验证码输入有误'
                    : _error!.contains('发送验证码失败')
                        ? '无法发送验证码'
                        : _error!.contains('注册失败')
                            ? '注册遇到问题'
                            : '请检查输入',
                icon: Icons.error_outline, // 图标
                iconColor: Colors.red.shade400, // 颜色
              ),
            ),
          )
        : const SizedBox.shrink(); // 否则返回空组件
  }

  /// 构建注册屏幕的主体 UI。
  @override
  Widget build(BuildContext context) {
    final bool isLoading = _isSendingCode || _isRegistering; // 是否正在加载

    final bool isRegisterButtonEnabled = !isLoading && _codeSent; // 注册按钮是否启用
    final bool isBackButtonEnabled = !isLoading; // 返回按钮是否启用

    const Duration initialDelay = Duration(milliseconds: 200); // 初始延迟
    const Duration stagger = Duration(milliseconds: 70); // 交错延迟

    if (widget.authProvider.isLoggedIn) {
      // 如果用户已登录
      return CustomErrorWidget(
        title: "停停停", // 标题
        errorMessage: "你已经登录了啊？你怎么还在注册账号？", // 错误消息
        onRetry: () => NavigationUtils.of(context), // 点击重试回调
        retryText: "返回上一页", // 重试按钮文本
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: '注册'), // AppBar
      body: Stack(
        children: [
          if (isLoading)
            _isSendingCode
                ? const LoadingWidget(
                    isOverlay: true,
                    message: '正在发送验证码...',
                    overlayOpacity: 0.4,
                    size: 36,
                  )
                : const LoadingWidget(
                    isOverlay: true,
                    overlayOpacity: 0.4,
                    size: 36,
                  ), // 加载消息

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500), // 约束最大宽度
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0), // 内边距
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor, // 背景色
                      borderRadius: BorderRadius.circular(16), // 圆角
                      boxShadow: [
                        // 阴影
                        BoxShadow(
                            color: Colors.black.withAlpha(200),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  padding: const EdgeInsets.all(24), // 内边距
                  child: Form(
                    key: _formKey, // 表单键
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化
                      crossAxisAlignment: CrossAxisAlignment.stretch, // 交叉轴拉伸
                      children: [
                        FadeInSlideUpItem(
                          delay: initialDelay, // 延迟
                          child: AppText(
                            '创建新账号', // 标题文本
                            textAlign: TextAlign.center, // 文本居中
                            type: AppTextType.title, // 文本类型
                            fontWeight: FontWeight.bold, // 字体粗细
                          ),
                        ),
                        const SizedBox(height: 24), // 间距
                        _buildErrorMessageField(), // 错误消息字段
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger, // 延迟
                          child: _buildUserNameFormField(isLoading), // 用户名输入框
                        ),
                        const SizedBox(height: 16), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 2, // 延迟
                          child: _buildEmailFormField(isLoading), // 邮箱输入框
                        ),
                        const SizedBox(height: 16), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 3, // 延迟
                          child:
                              _buildVerificationCodeField(isLoading), // 验证码输入框
                        ),
                        const SizedBox(height: 16), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 4, // 延迟
                          child: _buildPassWordFormField(isLoading), // 密码输入框
                        ),
                        const SizedBox(height: 16), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 5, // 延迟
                          child: _buildRepeatPassWordFormField(
                              isLoading), // 确认密码输入框
                        ),
                        const SizedBox(height: 32), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 6, // 延迟
                          child: FunctionalButton(
                            onPressed: _handleRegister, // 注册按钮点击回调
                            label: '立即注册', // 按钮文本
                            isLoading: _isRegistering, // 加载状态
                            isEnabled: isRegisterButtonEnabled, // 启用状态
                          ),
                        ),
                        const SizedBox(height: 8), // 间距
                        Checkbox(
                          value: _rememberMe, // 记住账号复选框值
                          onChanged: (value) => setState(() {
                            _rememberMe = value ?? false; // 切换记住账号状态
                          }),
                        ),
                        const Text('记住账号'), // 记住账号文本
                        const SizedBox(height: 8), // 间距
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 7, // 延迟
                          child: FunctionalTextButton(
                            onPressed: () =>
                                NavigationUtils.pop(context), // 点击返回登录页
                            label: '已有账号？返回登录', // 按钮文本
                            isEnabled: isBackButtonEnabled, // 启用状态
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
