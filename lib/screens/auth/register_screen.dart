// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/account.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import 'dart:async';
import 'package:suxingchahui/services/main/email/email_service.dart';
import 'package:suxingchahui/services/main/user/user_service.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
// --- ---

class RegisterScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final UserService userService;
  final InputStateService inputStateService;
  final EmailService emailService;
  const RegisterScreen({
    super.key,
    required this.userService,
    required this.authProvider,
    required this.inputStateService,
    required this.emailService,
  });

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SnackBarNotifierMixin {
  final _formKey = GlobalKey<FormState>();
  // --- 定义 Slot 名称 ---
  static const String usernameSlotName = 'register_username';
  static const String emailSlotName = 'register_email';
  static const String passwordSlotName = 'register_password';
  static const String confirmPasswordSlotName = 'register_confirm_password';
  static const String verificationCodeSlotName = 'register_verification_code';
  // --------------------

  String? _error;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSendingCode = false;
  bool _isRegistering = false;
  bool _rememberMe = true;

  Timer? _timer;
  int _countDown = 0;
  late final AuthProvider _authProvider;
  late final UserService _userService;

  bool _hasInitializedDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _authProvider = widget.authProvider;
      _userService = widget.userService;
      _hasInitializedDependencies = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countDown = 60;
    _timer?.cancel();
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

  // --- 修改：发送验证码，从 Service 获取 Email ---
  Future<void> _sendVerificationCode() async {
    // 验证逻辑现在只依赖 FormTextInputField 内部的 validator
    // 但我们仍然需要邮箱值来发送请求

    final email = widget.inputStateService.getText(emailSlotName).trim();

    // 简单的邮箱格式前端校验（也可以依赖 FormField 的 validator）
    if (email.isEmpty || !email.contains('@')) {
      showSnackbar(message: '请输入有效的邮箱地址', type: SnackbarType.warning);
      setState(() => _error = '请输入有效的邮箱地址'); // 可以同时设置内联错误
      return;
    }

    setState(() {
      _isSendingCode = true;
      _error = null;
    });

    try {
      await widget.emailService.requestVerificationCode(email, 'register');
      if (!mounted) return;
      _startTimer();
      setState(() {
        _codeSent = true;
        _error = null;
      });
      showSnackbar(message: "验证码已发送至您的邮箱，请注意查收！", type: SnackbarType.success);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = '发送验证码失败：${e.toString()}';
      setState(() => _error = errorMessage);
      showSnackbar(message: errorMessage, type: SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  // --- 修改：处理注册，从 Service 获取所有值，成功后清除状态 ---
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_codeSent) {
      showSnackbar(message: '请先获取验证码', type: SnackbarType.warning);
      return;
    }

    setState(() {
      _isRegistering = true;
      _error = null;
    });

    // 从 Service 获取所有需要的值
    final email = widget.inputStateService.getText(emailSlotName).trim();
    final username = widget.inputStateService.getText(usernameSlotName).trim();
    final password = widget.inputStateService.getText(passwordSlotName);
    final verificationCode =
        widget.inputStateService.getText(verificationCodeSlotName).trim();

    bool isCodeValid = false;
    String registrationError = '';

    try {
      isCodeValid = await widget.emailService
          .verifyCode(email, verificationCode, 'register');
      if (!mounted) return;

      if (!isCodeValid) {
        registrationError = '验证码错误或已过期';
        setState(() => _error = registrationError);
        showSnackbar(message: registrationError, type: SnackbarType.error);
        setState(() => _isRegistering = false);
        return;
      }

      SavedAccount? savedAccount;
      if (_rememberMe) {
        final user = _authProvider.currentUser;
        savedAccount = SavedAccount(
          email: email,
          password: password, // 注意：这里保存的是用户输入的密码
          username: user?.username,
          avatarUrl: user?.avatar,
          userId: user?.id,
          level: user?.level,
          experience: user?.experience,
          lastLogin: DateTime.now(),
        );
      }

      await _userService.signUp(email, password, username, savedAccount);
      if (!mounted) return;

      // 注册成功后，清除所有相关的输入状态
      widget.inputStateService.clearText(usernameSlotName);
      widget.inputStateService.clearText(emailSlotName);
      widget.inputStateService.clearText(passwordSlotName);
      widget.inputStateService.clearText(confirmPasswordSlotName);
      widget.inputStateService.clearText(verificationCodeSlotName);

      showSnackbar(message: "注册成功，即将跳转...", type: SnackbarType.success);
      await Future.delayed(Duration(milliseconds: 1000));
      if (!mounted) return;
      NavigationUtils.pop(context);
    } catch (e) {
      if (!mounted) return;
      registrationError = (isCodeValid ? '注册失败：' : '验证码校验出错：') + e.toString();
      setState(() => _error = registrationError);
      showSnackbar(message: registrationError, type: SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Widget _buildPassWordFormField(bool isLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      slotName: passwordSlotName,
      isEnabled: !isLoading,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: '密码 (至少6位)',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      keyboardType: TextInputType.visiblePassword,
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
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      slotName: verificationCodeSlotName, // <-- 使用 slotName
      isEnabled: !isLoading && _codeSent,
      decoration: const InputDecoration(
        labelText: '验证码',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
      keyboardType: TextInputType.number,
      maxLength: 6,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (!_codeSent) return null; // 如果没发送验证码，不校验
        if (value == null || value.isEmpty) return '请输入验证码';
        if (value.length != 6) return '验证码应为6位数字';
        return null;
      },
    );
  }
  // --- 结束修改 ---

  // --- 修改：使用 slotName ---
  Widget _buildUserNameFormField(bool isLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      slotName: usernameSlotName, // <-- 使用 slotName
      isEnabled: !isLoading,
      decoration: const InputDecoration(
        labelText: '用户名',
        prefixIcon: Icon(Icons.person_outline),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) => (value == null || value.isEmpty) ? '请输入用户名' : null,
    );
  }

  Widget _buildEmailFormField(bool isLoading) {
    final String sendCodeButtonLabel =
        _countDown > 0 ? '${_countDown}s' : (_codeSent ? '重新发送' : '发送验证码');
    final bool isSendCodeButtonEnabled = !isLoading && _countDown <= 0;

    final emailField = FormTextInputField(
      inputStateService: widget.inputStateService,
      slotName: emailSlotName,
      isEnabled: !isLoading,
      decoration: const InputDecoration(
        labelText: '邮箱',
        prefixIcon: Icon(Icons.alternate_email),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入邮箱';
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(value)) return '请输入有效的邮箱地址';
        return null;
      },
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: emailField,
        ),
        SizedBox(width: 12),
        SizedBox(
          height: 58, // 尝试保持按钮高度与输入框对齐
          child: FunctionalButton(
            onPressed: _sendVerificationCode, // 按下按钮时发送验证码
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
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      slotName: confirmPasswordSlotName,
      isEnabled: !isLoading,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: '确认密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) return '请再次输入密码';

        final password =
            widget.inputStateService.getText(passwordSlotName); // 不需要 trim
        if (value != password) return '两次输入的密码不一致';
        return null;
      },
    );
  }

  Widget _buildErrorMessageField() {
    return _error != null
        ? FadeInItem(
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
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    final bool isLoading = _isSendingCode || _isRegistering;
    final String loadingMessage =
        _isSendingCode ? '正在发送验证码...' : (_isRegistering ? '正在注册...' : '');

    final bool isRegisterButtonEnabled = !isLoading && _codeSent;
    final bool isBackButtonEnabled = !isLoading;

    const Duration initialDelay = Duration(milliseconds: 200);
    const Duration stagger = Duration(milliseconds: 70);

    return Scaffold(
      appBar: const CustomAppBar(title: '注册'),
      body: Stack(
        children: [
          if (isLoading) LoadingWidget.fullScreen(message: loadingMessage),
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
                            color: Colors.black.withAlpha(200),
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
                        _buildErrorMessageField(),
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger,
                          child: _buildUserNameFormField(isLoading), // 已修改
                        ),
                        SizedBox(height: 16),
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 2,
                          child: _buildEmailFormField(isLoading), // 已修改
                        ),
                        SizedBox(height: 16),
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 3,
                          child: _buildVerificationCodeField(isLoading), // 已修改
                        ),
                        SizedBox(height: 16),
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 4,
                          child: _buildPassWordFormField(isLoading), // 已修改
                        ),
                        SizedBox(height: 16),
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 5,
                          child:
                              _buildRepeatPassWordFormField(isLoading), // 已修改
                        ),
                        SizedBox(height: 32),
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 6,
                          child: FunctionalButton(
                            onPressed: _handleRegister, // 已修改
                            label: '立即注册',
                            isLoading: _isRegistering,
                            isEnabled: isRegisterButtonEnabled,
                          ),
                        ),
                        SizedBox(height: 8),
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() {
                            _rememberMe = value ?? false;
                          }),
                        ),
                        Text('记住账号'),
                        SizedBox(height: 8),
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
