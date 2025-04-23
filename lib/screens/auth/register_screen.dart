// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
// --- 确保这些是你项目中的实际路径 ---
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
// *** 引入我们封装的按钮 ***
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import 'dart:async';
import '../../services/main/email/email_service.dart';
import '../../services/main/user/user_service.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/common/loading_widget.dart';
// --- ---

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final UserService _userService = UserService();

  String? _error; // 这个 error 状态主要用于 InlineErrorWidget
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSendingCode = false;
  bool _isRegistering = false;

  Timer? _timer;
  int _countDown = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countDown = 60;
    _timer?.cancel(); // Ensure any existing timer is cancelled
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countDown > 0) {
          _countDown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _sendVerificationCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isSendingCode = true;
      _error = null; // 清除之前的内联错误
    });

    try {
      await EmailService.requestVerificationCode(
          _emailController.text, 'register');
      if (!mounted) return;
      _startTimer();
      setState(() {
        _codeSent = true;
        _error = null;
      });
      // *** 使用 AppSnackBar 替换 Toaster ***
      AppSnackBar.showSuccess(context, "验证码已发送至您的邮箱，请注意查收！");
    } catch (e) {
      if (!mounted) return;
      final errorMessage = '发送验证码失败：${e.toString()}';
      setState(() => _error = errorMessage); // 仍然设置 _error 用于 InlineErrorWidget
      AppSnackBar.showError(context, errorMessage); // 同时用 SnackBar 显示错误
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_codeSent) {
      // *** 使用 AppSnackBar 替换 原生 SnackBar ***
      AppSnackBar.showWarning(context, '请先获取验证码');
      // 同时也可以设置 _error 状态，让 InlineErrorWidget 显示
      // setState(() => _error = '请先获取验证码');
      return;
    }

    setState(() {
      _isRegistering = true;
      _error = null; // 清除之前的内联错误
    });

    bool isCodeValid = false;
    String registrationError = ''; // 用于存储注册或验证过程中的错误信息

    try {
      isCodeValid = await EmailService.verifyCode(
          _emailController.text, _verificationCodeController.text, 'register');
      if (!mounted) return;

      if (!isCodeValid) {
        registrationError = '验证码错误或已过期';
        setState(() => _error = registrationError); // 设置内联错误
        // *** 使用 AppSnackBar 替换 原生 SnackBar ***
        AppSnackBar.showError(context, registrationError);
        setState(() => _isRegistering = false); // 重置加载状态
        return;
      }

      // 验证码有效，尝试注册
      await _userService.signUp(_emailController.text, _passwordController.text,
          _usernameController.text);
      if (!mounted) return;

      // *** 使用 AppSnackBar 替换 Toaster ***
      AppSnackBar.showSuccess(context, "注册成功，即将跳转..."); // 稍微修改提示
      await Future.delayed(Duration(milliseconds: 1500)); // 延长一点时间让用户看到提示
      if (!mounted) return;
      NavigationUtils.pop(context); // 返回到登录页 (或者根据你的逻辑调整)
      // NavigationUtils.navigateToHome(context); // 注册成功后通常是返回登录让用户登录，而不是直接进 Home
    } catch (e) {
      if (!mounted) return;
      // 根据出错阶段设置错误信息
      registrationError = (isCodeValid ? '注册失败：' : '验证码校验出错：') + e.toString();
      setState(() => _error = registrationError); // 设置内联错误
      // *** 使用 AppSnackBar 替换 原生 SnackBar ***
      AppSnackBar.showError(context, registrationError);
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Widget _buildPassWordFormField(bool isLoading) {
    return FormTextInputField( // <--- 替换
      controller: _passwordController,
      enabled: !isLoading,
      obscureText: _obscurePassword, // <--- 设置 obscureText
      decoration: InputDecoration(
        labelText: '密码 (至少6位)',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // <--- 密码键盘类型
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入密码';
        if (value.length < 6) return '密码长度至少6位';
        if (value.length > 30) return '密码长度过长';
        return null;
      },
    );
  }

  Widget _buildVerificationCodeField(bool isLoading) {
    return FormTextInputField( // <--- 替换
      controller: _verificationCodeController,
      enabled: !isLoading && _codeSent,
      decoration: const InputDecoration(
        labelText: '验证码',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
      keyboardType: TextInputType.number, // <--- 设置 keyboardType
      maxLength: 6, // 可以加上长度限制
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (!_codeSent) return null;
        if (value == null || value.isEmpty) return '请输入验证码';
        if (value.length != 6) return '验证码应为6位数字';
        return null;
      },
    );
  }


  Widget _buildUserNameFormField(bool isLoading) {
    return FormTextInputField( // <--- 替换
      controller: _usernameController,
      enabled: !isLoading,
      decoration: const InputDecoration(
        labelText: '用户名',
        prefixIcon: Icon(Icons.person_outline),
        // border: OutlineInputBorder(), // 可以由 FormTextInputField 默认提供
      ),
      textInputAction: TextInputAction.next,
      validator: (value) => (value == null || value.isEmpty) ? '请输入用户名' : null,
    );
  }

  Widget _buildEmailFormField(bool isLoading) {
    final String sendCodeButtonLabel = _countDown > 0 ? '${_countDown}s' : (_codeSent ? '重新发送' : '发送验证码');
    final bool isSendCodeButtonEnabled = !isLoading && _countDown <= 0;

    // 邮箱输入部分使用 FormTextInputField
    final emailField = FormTextInputField( // <--- 替换
      key: _emailFormKey, // Form key 移到外面 Row 的 Form 上或去掉嵌套 Form
      controller: _emailController,
      enabled: !isLoading,
      decoration: const InputDecoration(
        labelText: '邮箱',
        prefixIcon: Icon(Icons.alternate_email),
      ),
      keyboardType: TextInputType.emailAddress, // <--- 设置 keyboardType
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入邮箱';
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(value)) return '请输入有效的邮箱地址';
        return null;
      },
    );

    // Row 布局和按钮保持不变
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 保持对齐
      children: [
        Expanded(
          // 这里不需要嵌套 Form 了，_emailFormKey 用于验证，直接用 emailField
          child: emailField,
        ),
        SizedBox(width: 12),
        SizedBox(
          height: 58, // 保持高度对齐
          child: FunctionalButton(
            onPressed: _sendVerificationCode,
            label: sendCodeButtonLabel,
            isLoading: _isSendingCode,
            isEnabled: isSendCodeButtonEnabled,
            padding: EdgeInsets.symmetric(horizontal: 12),
            fontSize: 14,
          ),
        ),
      ],
    );
  }


  Widget _buildRepeatPassWordFormField(bool isLoading) {
    return FormTextInputField( // <--- 替换
        controller: _confirmPasswordController,
        enabled: !isLoading,
        obscureText: _obscureConfirmPassword, // <--- 设置 obscureText
        decoration: InputDecoration(
          labelText: '确认密码',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        keyboardType: TextInputType.visiblePassword, // <--- 密码键盘类型
        textInputAction: TextInputAction.done, // 最后一个字段用 done
        validator: (value) {
          if (value == null || value.isEmpty) return '请再次输入密码';
          if (value != _passwordController.text) return '两次输入的密码不一致';
          return null;
        });
  }

  Widget _buildErrorMessageField() {
    return _error != null
        // --- 修改这里：添加动画 ---
        ? FadeInItem(
            // 使用 FadeInItem 包裹
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InlineErrorWidget(
                errorMessage: _error!.contains('验证码错误')
                    ? '验证码输入有误'
                    : _error!.contains('发送验证码失败')
                        ? '无法发送验证码'
                        : _error!.contains('注册失败')
                            ? '注册遇到问题'
                            : '请检查输入',
                icon: Icons.error_outline,
                iconColor: Colors.red.shade400,
                // onRetry: () => setState(() => _error = null), // 可以去掉重试
              ),
            ),
          )
        // --- 结束修改 ---
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _isSendingCode || _isRegistering;
    final String loadingMessage =
        _isSendingCode ? '正在发送验证码...' : (_isRegistering ? '正在注册...' : '');

    final bool isRegisterButtonEnabled = !isLoading && _codeSent;
    final bool isBackButtonEnabled = !isLoading;

    // --- 定义动画延迟和间隔 ---
    const Duration initialDelay = Duration(milliseconds: 200);
    const Duration stagger = Duration(milliseconds: 70); // 注册页元素多，间隔小点

    return Scaffold(
      appBar: CustomAppBar(title: '注册'),
      body: Stack(
        children: [
          if (isLoading) LoadingWidget.fullScreen(message: loadingMessage),

          // --- 结束修改 ---

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ]),
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- 修改这里：为所有表单元素添加动画 ---
                        // 标题
                        FadeInSlideUpItem(
                          delay: initialDelay,
                          child: AppText(
                            '创建新账号',
                            textAlign: TextAlign.center,
                            type: AppTextType.title,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),

                        // 错误消息 (内部已加动画)
                        _buildErrorMessageField(),

                        // 用户名
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger,
                          child: _buildUserNameFormField(isLoading),
                        ),
                        SizedBox(height: 16),

                        // 邮箱和发送验证码按钮行
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 2,
                          child: _buildEmailFormField(isLoading),
                        ),
                        SizedBox(height: 16),

                        // 验证码输入
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 3,
                          child: _buildVerificationCodeField(isLoading),
                        ),
                        SizedBox(height: 16),

                        // 密码输入
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 4,
                          child: _buildPassWordFormField(isLoading),
                        ),
                        SizedBox(height: 16),

                        // 确认密码
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 5,
                          child: _buildRepeatPassWordFormField(isLoading),
                        ),
                        SizedBox(height: 32),

                        // 注册按钮
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 6,
                          child: FunctionalButton(
                            onPressed: _handleRegister,
                            label: '立即注册',
                            isLoading: _isRegistering,
                            isEnabled: isRegisterButtonEnabled,
                          ),
                        ),
                        SizedBox(height: 16),

                        // 返回登录按钮
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 7,
                          child: FunctionalTextButton(
                            onPressed: () => NavigationUtils.pop(context),
                            label: '已有账号？返回登录',
                            isEnabled: isBackButtonEnabled,
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
