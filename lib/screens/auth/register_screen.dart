// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
// --- 确保这些是你项目中的实际路径 ---
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
// *** 引入我们封装的按钮 ***
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // <--- 引入 ElevatedButton 封装
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // <--- 引入 TextButton 封装
// --- 其他 imports 保持不变 ---
import 'dart:async';
import '../../services/main/email/email_service.dart';
import '../../services/main/user/user_service.dart';
import '../../widgets/common/toaster/toaster.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/common/loading_widget.dart';
// --- ---

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ... (其他状态变量和方法保持不变) ...
  final _formKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final UserService _userService = UserService();

  String? _error;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSendingCode = false;
  bool _isRegistering = false;

  Timer? _timer;
  int _countDown = 0;

  // ... (dispose, _startTimer, _sendVerificationCode, _handleRegister 方法保持不变) ...
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
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isSendingCode = true;
      _error = null;
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
      Toaster.success(context, "验证码已发送至您的邮箱，请注意查收！");
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '发送验证码失败：${e.toString()}');
      Toaster.error(context, _error!);
    } finally {
      if (mounted) {
        setState(() => _isSendingCode = false);
      }
    }
  }


  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_codeSent) {
      setState(() => _error = '请先获取验证码');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请先获取验证码'), backgroundColor: Colors.orange));
      return;
    }

    setState(() {
      _isRegistering = true;
      _error = null;
    });

    bool isCodeValid = false;
    try {
      isCodeValid = await EmailService.verifyCode(
          _emailController.text, _verificationCodeController.text, 'register');
      if (!mounted) return;

      if (!isCodeValid) {
        setState(() => _error = '验证码错误或已过期');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_error!), backgroundColor: Colors.red));
        setState(() => _isRegistering = false); // 重置加载状态
        return;
      }

      await _userService.signUp(_emailController.text, _passwordController.text,
          _usernameController.text);
      if (!mounted) return;

      Toaster.success(context, "注册成功，即将跳转登录...");
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
      NavigationUtils.pop(context); // 返回到登录页
      NavigationUtils.navigateToHome(context); // 可能不需要直接跳 Home
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _error = (isCodeValid ? '注册失败：' : '验证码校验出错：') + e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 整体加载状态
    final bool isLoading = _isSendingCode || _isRegistering;
    final String loadingMessage =
        _isSendingCode ? '正在发送验证码...' : (_isRegistering ? '正在注册...' : '');

    // --- 计算发送按钮的标签和状态 ---
    final String sendCodeButtonLabel =
        _countDown > 0 ? '${_countDown}s' : (_codeSent ? '重新发送' : '发送验证码');
    // 发送按钮是否可用：不在加载中 且 倒计时结束
    final bool isSendCodeButtonEnabled = !isLoading && _countDown <= 0;

    // --- 计算注册按钮的状态 ---
    // 注册按钮是否可用：不在加载中 且 验证码已发送 (防止未发送就点击)
    final bool isRegisterButtonEnabled = !isLoading && _codeSent;

    // --- 计算返回按钮的状态 ---
    final bool isBackButtonEnabled = !isLoading;

    return Scaffold(
      appBar: CustomAppBar(title: '注册'),
      body: Stack(
        children: [
          Opacity(
              opacity: 0.6,
              child:
                  Container(width: double.infinity, height: double.infinity)),
          // 加载状态 (保持不变)
          if (isLoading) LoadingWidget.fullScreen(message: loadingMessage),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
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
                        Text('创建新账号',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        SizedBox(height: 16),

                        // 错误信息 (保持不变)
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: InlineErrorWidget(
                              errorMessage: _error!.contains("验证码") ? '验证码错误' : '注册错误',
                              icon: Icons.error_outline,
                              retryText: '知道了',
                              iconColor: Colors.red,
                              onRetry: () => setState(() => _error = null),
                            ),
                          ),

                        // 用户名 (保持不变, 使用 isLoading 控制 enabled)
                        TextFormField(
                          controller: _usernameController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                              labelText: '用户名',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person)),
                          validator: (value) => (value == null || value.isEmpty)
                              ? '请输入用户名'
                              : null,
                        ),
                        SizedBox(height: 16),

                        // 邮箱和发送验证码按钮行
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // 保持对齐
                          children: [
                            Expanded(
                              child: Form(
                                // 邮箱的 Form Key (保持不变)
                                key: _emailFormKey,
                                child: TextFormField(
                                  controller: _emailController,
                                  enabled: !isLoading, // 使用整体 loading 状态
                                  decoration: InputDecoration(
                                      labelText: '邮箱',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email)),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return '请输入邮箱';
                                    if (!value.contains('@'))
                                      return '请输入有效的邮箱地址';
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // --- 使用 FunctionalButton 并保持尺寸 ---
                            SizedBox(
                              // 用 SizedBox 包裹来固定尺寸
                              width: 130, // 保持原来的宽度
                              height: 58, // 保持原来的高度 (约等于 TextFormField 高度)
                              child: FunctionalButton(
                                // <--- 替换发送/重发按钮
                                onPressed: _sendVerificationCode,
                                label: sendCodeButtonLabel, // 使用计算好的标签
                                isLoading: _isSendingCode, // 传递发送状态
                                isEnabled: isSendCodeButtonEnabled, // 传递可用状态
                                fontSize: 14, // 字体可以小一点
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 0), // 调整内边距适应高度
                                // icon: Icons.send, // 如果想加图标
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // 验证码输入 (保持不变, enabled 状态调整)
                        TextFormField(
                          controller: _verificationCodeController,
                          // 只有 codeSent 且不在加载时才启用
                          enabled: !isLoading && _codeSent,
                          decoration: InputDecoration(
                              labelText: '验证码',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.code)),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!_codeSent) return null; // 未发送时不校验
                            if (value == null || value.isEmpty) return '请输入验证码';
                            if (value.length != 6) return '验证码应为6位数字';
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // 密码输入 (保持不变, 使用 isLoading 控制 enabled)
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return '请输入密码';
                            if (value.length < 6) return '密码长度至少6位';
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // 确认密码 (保持不变, 使用 isLoading 控制 enabled)
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !isLoading,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: '确认密码',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (value) =>
                              (value != _passwordController.text)
                                  ? '两次输入的密码不一致'
                                  : null,
                        ),
                        SizedBox(height: 24),

                        // --- 使用 FunctionalButton 替换注册按钮 ---
                        FunctionalButton(
                          // <--- 替换注册按钮
                          onPressed: _handleRegister,
                          label: '注册',
                          isLoading: _isRegistering, // 传递注册状态
                          isEnabled: isRegisterButtonEnabled, // 传递可用状态
                          // 可以让按钮宽一点
                          // padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        ),
                        SizedBox(height: 16),

                        // --- 使用 FunctionalTextButton 替换返回登录按钮 ---
                        FunctionalTextButton(
                          // <--- 替换返回登录按钮
                          onPressed: () => NavigationUtils.pop(context),
                          label: '已有账号？返回登录',
                          isEnabled: isBackButtonEnabled, // 传递可用状态
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
