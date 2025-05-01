// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // *** 新增 Provider 导入 ***
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
// *** 新增 InputStateService 导入 ***
import '../../providers/inputs/input_state_provider.dart';
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
  // --- 移除 TextEditingControllers ---
  // final _usernameController = TextEditingController();
  // final _emailController = TextEditingController();
  // final _passwordController = TextEditingController();
  // final _confirmPasswordController = TextEditingController();
  // final _verificationCodeController = TextEditingController();
  // ---------------------------------


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

  Timer? _timer;
  int _countDown = 0;

  @override
  void dispose() {
    // --- 移除 Controller 的 dispose ---
    // _usernameController.dispose();
    // _emailController.dispose();
    // _passwordController.dispose();
    // _confirmPasswordController.dispose();
    // _verificationCodeController.dispose();
    // -------------------------------
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
    final InputStateService inputService;
    try {
      inputService = Provider.of<InputStateService>(context, listen: false);
    } catch (e) {
      setState(() => _error = '内部错误：无法访问输入服务');
      AppSnackBar.showError(context, _error!);
      return;
    }
    final email = inputService.getText(emailSlotName).trim();

    // 简单的邮箱格式前端校验（也可以依赖 FormField 的 validator）
    if (email.isEmpty || !email.contains('@')) {
      AppSnackBar.showWarning(context, '请输入有效的邮箱地址');
      setState(() => _error = '请输入有效的邮箱地址'); // 可以同时设置内联错误
      return;
    }

    setState(() {
      _isSendingCode = true;
      _error = null;
    });

    try {
      final emailService = context.read<EmailService>();
      await emailService.requestVerificationCode( // <--- 改成调用实例方法
          email, 'register');
      if (!mounted) return;
      _startTimer();
      setState(() {
        _codeSent = true;
        _error = null;
      });
      AppSnackBar.showSuccess(context, "验证码已发送至您的邮箱，请注意查收！");
    } catch (e) {
      if (!mounted) return;
      final errorMessage = '发送验证码失败：${e.toString()}';
      setState(() => _error = errorMessage);
      AppSnackBar.showError(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }
  // --- 结束修改 ---

  // --- 修改：处理注册，从 Service 获取所有值，成功后清除状态 ---
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_codeSent) {
      AppSnackBar.showWarning(context, '请先获取验证码');
      return;
    }

    setState(() {
      _isRegistering = true;
      _error = null;
    });

    final InputStateService inputService;
    try {
      inputService = Provider.of<InputStateService>(context, listen: false);
    } catch (e) {
      setState(() {
        _isRegistering = false;
        _error = '内部错误：无法访问输入服务';
      });
      AppSnackBar.showError(context, _error!);
      return;
    }

    // 从 Service 获取所有需要的值
    final email = inputService.getText(emailSlotName).trim();
    final username = inputService.getText(usernameSlotName).trim();
    final password =
        inputService.getText(passwordSlotName).trim(); // 注意：密码通常不trim，但如果需要就这样
    final confirmPassword =
        inputService.getText(confirmPasswordSlotName).trim(); // 同上
    final verificationCode =
        inputService.getText(verificationCodeSlotName).trim();

    // (确认密码的校验已经在 validator 里做了，这里理论上不需要再校验)
    // if (password != confirmPassword) { ... }

    bool isCodeValid = false;
    String registrationError = '';

    try {
      isCodeValid =
          await EmailService.verifyCode(email, verificationCode, 'register');
      if (!mounted) return;

      if (!isCodeValid) {
        registrationError = '验证码错误或已过期';
        setState(() => _error = registrationError);
        AppSnackBar.showError(context, registrationError);
        setState(() => _isRegistering = false);
        return;
      }
      final userService = context.read<UserService>();

      await userService.signUp(email, password, username);
      if (!mounted) return;

      // *** 注册成功后，清除所有相关的输入状态 ***
      inputService.clearText(usernameSlotName);
      inputService.clearText(emailSlotName);
      inputService.clearText(passwordSlotName);
      inputService.clearText(confirmPasswordSlotName);
      inputService.clearText(verificationCodeSlotName);
      // **************************************

      AppSnackBar.showSuccess(context, "注册成功，即将跳转...");
      await Future.delayed(Duration(milliseconds: 1000));
      if (!mounted) return;
      NavigationUtils.pop(context);
    } catch (e) {
      if (!mounted) return;
      registrationError = (isCodeValid ? '注册失败：' : '验证码校验出错：') + e.toString();
      setState(() => _error = registrationError);
      AppSnackBar.showError(context, registrationError);
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }
  // --- 结束修改 ---

  // --- 修改：使用 slotName ---
  Widget _buildPassWordFormField(bool isLoading) {
    return FormTextInputField(
      slotName: passwordSlotName, // <-- 使用 slotName
      // controller: _passwordController, // <-- 移除 controller
      enabled: !isLoading,
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
  // --- 结束修改 ---

  // --- 修改：使用 slotName ---
  Widget _buildVerificationCodeField(bool isLoading) {
    return FormTextInputField(
      slotName: verificationCodeSlotName, // <-- 使用 slotName
      // controller: _verificationCodeController, // <-- 移除 controller
      enabled: !isLoading && _codeSent,
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
      slotName: usernameSlotName, // <-- 使用 slotName
      // controller: _usernameController, // <-- 移除 controller
      enabled: !isLoading,
      decoration: const InputDecoration(
        labelText: '用户名',
        prefixIcon: Icon(Icons.person_outline),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) => (value == null || value.isEmpty) ? '请输入用户名' : null,
    );
  }
  // --- 结束修改 ---

  // --- 修改：使用 slotName ---
  Widget _buildEmailFormField(bool isLoading) {
    final String sendCodeButtonLabel =
        _countDown > 0 ? '${_countDown}s' : (_codeSent ? '重新发送' : '发送验证码');
    final bool isSendCodeButtonEnabled = !isLoading && _countDown <= 0;

    final emailField = FormTextInputField(
      slotName: emailSlotName, // <-- 使用 slotName
      // controller: _emailController, // <-- 移除 controller
      // key: _emailFormKey, // <-- 这个 key 不需要了，因为 Form 在外面
      enabled: !isLoading,
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
  // --- 结束修改 ---

  // --- 修改：使用 slotName，并修改 validator ---
  Widget _buildRepeatPassWordFormField(bool isLoading) {
    return FormTextInputField(
      slotName: confirmPasswordSlotName, // <-- 使用 slotName
      // controller: _confirmPasswordController, // <-- 移除 controller
      enabled: !isLoading,
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
        // 从 Service 获取密码字段的值进行比较
        final inputService =
            Provider.of<InputStateService>(context, listen: false);
        final password = inputService.getText(passwordSlotName); // 不需要 trim
        if (value != password) return '两次输入的密码不一致';
        return null;
      },
    );
  }
  // --- 结束修改 ---

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
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _isSendingCode || _isRegistering;
    final String loadingMessage =
        _isSendingCode ? '正在发送验证码...' : (_isRegistering ? '正在注册...' : '');

    final bool isRegisterButtonEnabled = !isLoading && _codeSent;
    final bool isBackButtonEnabled = !isLoading;

    const Duration initialDelay = Duration(milliseconds: 200);
    const Duration stagger = Duration(milliseconds: 70);

    return Scaffold(
      appBar: CustomAppBar(title: '注册'),
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
                        SizedBox(height: 16),
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
