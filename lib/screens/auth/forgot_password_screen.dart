// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/providers/user/user_info_provider.dart';
import 'dart:async';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/services/main/email/email_service.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final InputStateService inputStateService;
  final UserInfoProvider infoProvider;
  final EmailService emailService;
  final AuthProvider authProvider;
  const ForgotPasswordScreen({
    super.key,
    required this.inputStateService,
    required this.emailService,
    required this.infoProvider,
    required this.authProvider,
  });

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _error;
  bool _codeSent = false;
  int _countDown = 0;
  Timer? _timer;
  bool _isSendingCode = false;
  bool _isVerifying = false;

  bool _hasInitializedDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
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

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '请输入有效的邮箱地址');
      AppSnackBar.showWarning(context, '请输入有效的邮箱地址');
      return;
    }

    setState(() {
      _isSendingCode = true;
      _error = null;
    });

    try {
      await widget.emailService
          .requestVerificationCode(_emailController.text, 'reset');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startTimer();
        setState(() {
          _codeSent = true;
          _error = null;
        });
        AppSnackBar.showSuccess(context, "验证码已发送至您的邮箱，请去查看！");
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '发送验证码失败: ${e.toString()}');
      AppSnackBar.showError(context, _error!);
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_codeSent) {
      setState(() => _error = '请先获取验证码');
      AppSnackBar.showWarning(context, _error!);
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final bool isCodeValid = await widget.emailService
          .verifyCode(_emailController.text, _codeController.text, 'reset');
      if (!mounted) return;

      if (isCodeValid) {
        NavigationUtils.pushReplacementNamed(context, AppRoutes.resetPassword,
            arguments: _emailController.text);
      } else {
        setState(() => _error = '验证码错误或已过期');
        AppSnackBar.showError(context, _error!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '验证码校验时发生错误: ${e.toString()}');
      AppSnackBar.showError(context, _error!);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Widget _buildEmailFormField(bool isOverallLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      controller: _emailController,
      isEnabled: !_isSendingCode && !_isVerifying,
      decoration: const InputDecoration(
        labelText: '输入邮箱',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      keyboardType: TextInputType.emailAddress, // <--- 设置 keyboardType
      textInputAction: TextInputAction.next, // 下一步是验证码（如果出现）
      validator: (value) {
        if (value == null || value.isEmpty || !value.contains('@')) {
          return '请输入有效的邮箱地址';
        }
        return null;
      },
    );
  }

  Widget _buildVerificationCodeField(bool isOverallLoading) {
    return FormTextInputField(
      inputStateService: widget.inputStateService,
      controller: _codeController,
      isEnabled: !isOverallLoading,
      decoration: const InputDecoration(
        labelText: '邮箱验证码',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
      keyboardType: TextInputType.number, // <--- 设置 keyboardType
      maxLength: 6,
      textInputAction: TextInputAction.done, // 最后一个输入是 done
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入验证码';
        if (value.length != 6) return '验证码应为6位数字';
        return null;
      },
    );
  }

  Widget _buildErrorMessageField() {
    return _error != null
        ? FadeInItem(
            // 使用 FadeInItem 包裹
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InlineErrorWidget(
                errorMessage: _error!,
                icon: Icons.error_outline,
                // retryText: '重试', // 可以去掉重试按钮，因为通常需要用户修改输入
                iconColor: Colors.red,
                // onRetry: () { setState(() { _error = null; }); },
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final bool isOverallLoading = _isSendingCode || _isVerifying;
    final String loadingMessage = '请稍候...';

    final String sendButtonLabel =
        _codeSent ? (_countDown > 0 ? '${_countDown}s' : '重新发送') : '发送验证码';
    final bool isSendButtonEnabled = !isOverallLoading && _countDown <= 0;
    final bool isVerifyButtonEnabled =
        !isOverallLoading && _codeSent; // 验证按钮也需要 _codeSent

    // --- 定义动画延迟和间隔 ---
    const Duration initialDelay = Duration(milliseconds: 200);
    const Duration stagger = Duration(milliseconds: 80);

    if (widget.authProvider.isLoggedIn) {
      return CustomErrorWidget(
        title: "停停停",
        errorMessage: "好像你已经登录了啊？？",
        onRetry: () => NavigationUtils.of(context),
        retryText: "返回上一页",
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: '找回密码'),
      body: Stack(
        children: [
          // 背景 Opacity 可以保留或移除
          // Opacity(opacity: 0.6, child: Container(width: double.infinity, height: double.infinity)),

          // --- 修改这里：为 Loading 添加动画 ---
          if (isOverallLoading)
            FadeInItem(
              // 使用 FadeInItem
              child: LoadingWidget.fullScreen(message: loadingMessage),
            ),
          // --- 结束修改 ---

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withSafeOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- 修改这里：为所有表单元素添加动画 ---
                        // 标题
                        FadeInSlideUpItem(
                          delay: initialDelay,
                          child: AppText('找回密码',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 16),
                        // 副标题
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger,
                          child: AppText('通过邮箱重置您的密码',
                              fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 24),

                        // 错误消息 (内部已加动画)
                        _buildErrorMessageField(),

                        // 邮箱输入
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 2,
                          child: _buildEmailFormField(isOverallLoading),
                        ),
                        SizedBox(height: 16),

                        // 验证码输入 (根据 _codeSent 决定是否显示)
                        // 使用 AnimatedSize 和 AnimatedOpacity 来平滑显示/隐藏
                        AnimatedSize(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: AnimatedOpacity(
                            opacity: _codeSent ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: _codeSent // 只有在 _codeSent 为 true 时才构建内容
                                ? FadeInSlideUpItem(
                                    key: ValueKey('verification_code_field'),
                                    // 给个 Key
                                    delay: Duration.zero,
                                    // 因为外层有动画，内部不需要延迟
                                    child: Padding(
                                      // 加个 Padding 避免动画跳动
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: _buildVerificationCodeField(
                                          isOverallLoading),
                                    ),
                                  )
                                : const SizedBox.shrink(), // 隐藏时不占空间
                          ),
                        ),
                        // if (_codeSent) SizedBox(height: 16), // 间距由 Padding 处理

                        // 按钮行
                        // 按钮行
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * (_codeSent ? 4 : 3),
                          child: Row(
                            children: [
                              Expanded(
                                // “发送验证码”按钮会填充大部分空间
                                child: FunctionalButton(
                                  onPressed: _sendVerificationCode,
                                  label: sendButtonLabel,
                                  isLoading: _isSendingCode,
                                  isEnabled: isSendButtonEnabled,
                                ),
                              ),
                              AnimatedOpacity(
                                opacity: _codeSent ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 300),
                                // 如果 _codeSent 为 false，AnimatedOpacity 的 child 理论上不应该有 Expanded
                                // 且 SizedBox.shrink() 也不会导致问题。
                                // 关键在于 _codeSent 为 true 时，内部 Row 不能有 Expanded
                                // 或者 AnimatedOpacity 的父级（即外层 Row）需要给它一个确定的宽度。
                                child: _codeSent
                                    ? Row(
                                        // 这个 Row 不应该有 Expanded，除非外层给它宽度
                                        mainAxisSize:
                                            MainAxisSize.min, // 让内部 Row 包裹内容
                                        children: [
                                          SizedBox(width: 16),
                                          // 不再使用 Expanded，让 FunctionalButton 自适应内容宽度
                                          FunctionalButton(
                                            onPressed: _verifyCode,
                                            label: '验证',
                                            isLoading: _isVerifying,
                                            isEnabled: isVerifyButtonEnabled,
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // 返回按钮
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * (_codeSent ? 5 : 4),
                          // 根据验证码框是否显示调整延迟
                          child: FunctionalTextButton(
                            onPressed: () => NavigationUtils.pop(context),
                            label: '返回登录',
                            isEnabled: !isOverallLoading,
                          ),
                        ),
                        // --- 结束修改 ---
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
