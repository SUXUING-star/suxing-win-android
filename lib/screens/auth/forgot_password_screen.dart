// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
// --- 确保这些是你项目中的实际路径 ---
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // <--- 引入 ElevatedButton 封装
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // <--- 引入 TextButton 封装
import 'package:suxingchahui/widgets/ui/common/error_widget.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import '../../services/main/email/email_service.dart';
import 'dart:async';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/ui/common/loading_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ... (其他状态变量和方法保持不变) ...
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _error;
  bool _codeSent = false;
  int _countDown = 0;
  Timer? _timer;
  bool _isSendingCode = false;
  bool _isVerifying = false;


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
      await EmailService.requestVerificationCode(
          _emailController.text, 'reset');
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
      final bool isCodeValid = await EmailService.verifyCode(
          _emailController.text, _codeController.text, 'reset');
      if (!mounted) return;

      if (isCodeValid) {
        NavigationUtils.pushReplacementNamed(context, '/reset-password',
            arguments: _emailController.text);
      } else {
        setState(() => _error = '验证码错误或已过期');
        AppSnackBar.showError(context,_error!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '验证码校验时发生错误: ${e.toString()}');
      AppSnackBar.showError(context,_error!);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 整体加载状态，用于禁用输入框和返回按钮等
    final bool isOverallLoading = _isSendingCode || _isVerifying;
    final String loadingMessage = '请稍候...';

    // --- 计算发送按钮的标签和状态 ---
    final String sendButtonLabel =
        _codeSent ? (_countDown > 0 ? '${_countDown}s' : '重新发送') : '发送验证码';
    // 发送按钮是否可用：不在加载中 且 倒计时结束
    final bool isSendButtonEnabled = !isOverallLoading && _countDown <= 0;

    // --- 计算验证按钮的状态 ---
    // 验证按钮是否可用：不在加载中
    final bool isVerifyButtonEnabled = !isOverallLoading;

    return Scaffold(
      appBar: CustomAppBar(title: '找回密码'),
      body: Stack(
        children: [
          Opacity(
              opacity: 0.6,
              child:
                  Container(width: double.infinity, height: double.infinity)),
          // 加载状态处理 (保持不变)
          if (isOverallLoading)
            LoadingWidget.fullScreen(message: loadingMessage),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('找回密码',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        SizedBox(height: 16),
                        Text('通过邮箱重置您的密码',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        SizedBox(height: 24),

                        // 显示错误信息 - 使用自定义错误组件
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: InlineErrorWidget(
                              errorMessage: _error!,
                              icon: Icons.error_outline,
                              retryText: '重试',
                              iconColor: Colors.red,
                              onRetry: () {
                                setState(() {
                                  _error = null;
                                });
                              },
                            ),
                          ),

                        // 邮箱输入 (保持不变, 使用 isOverallLoading 控制 enabled)
                        TextFormField(
                          controller: _emailController,
                          enabled: !isOverallLoading, // 使用整体加载状态
                          decoration: InputDecoration(
                              labelText: '邮箱',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email)),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) return '请输入有效的邮箱地址';
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // 验证码输入 (保持不变, 使用 isOverallLoading 控制 enabled)
                        if (_codeSent)
                          TextFormField(
                            controller: _codeController,
                            enabled: !isOverallLoading, // 使用整体加载状态
                            decoration: InputDecoration(
                                labelText: '验证码',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.code)),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!_codeSent) return null;
                              if (value == null || value.isEmpty)
                                return '请输入验证码';
                              if (value.length != 6) return '验证码应为6位数字';
                              return null;
                            },
                          ),
                        if (_codeSent) SizedBox(height: 16),

                        // --- 使用新的 FunctionalButton ---
                        Row(
                          children: [
                            Expanded(
                              child: FunctionalButton(
                                // <--- 替换发送/重发按钮
                                onPressed: _sendVerificationCode,
                                label: sendButtonLabel, // 使用计算好的标签
                                isLoading: _isSendingCode, // 传递发送的加载状态
                                isEnabled: isSendButtonEnabled, // 传递计算好的可用状态
                                // 可以按需调整 padding 等样式参数
                                // padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                            // 验证按钮 (保持不变的逻辑，只替换组件)
                            if (_codeSent) ...[
                              SizedBox(width: 16),
                              Expanded(
                                child: FunctionalButton(
                                  // <--- 替换验证按钮
                                  onPressed: _verifyCode,
                                  label: '验证',
                                  isLoading: _isVerifying, // 传递验证的加载状态
                                  isEnabled:
                                      isVerifyButtonEnabled, // 传递计算好的可用状态
                                  // padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 16),

                        // --- 使用新的 FunctionalTextButton 添加返回按钮 ---
                        FunctionalTextButton(
                          // <--- 添加返回按钮
                          onPressed: () => NavigationUtils.pop(context),
                          label: '返回登录',
                          isEnabled: !isOverallLoading, // 加载时禁用
                          // 可以加个返回图标
                          // icon: Icons.arrow_back,
                          // customColor: Colors.grey, // 如果想用灰色
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
