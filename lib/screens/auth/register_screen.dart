// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/main/email/email_service.dart';
import '../../services/main/user/user_service.dart';
import '../../utils/load/loading_route_observer.dart';
import '../../widgets/common/toaster/toaster.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';

class RegisterScreen extends StatefulWidget {
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
  final UserService _authService = UserService();

  String? _error;
  bool _codeSent = false;
  String? _verificationCode;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 添加计时器相关变量
  Timer? _timer;
  int _countDown = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _timer?.cancel(); // 清理计时器
    super.dispose();
  }

  void _startTimer() {
    _countDown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    // 只验证邮箱字段
    if (!_emailFormKey.currentState!.validate()) return;

    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      _verificationCode = EmailService.generateVerificationCode();
      await EmailService.sendRegistrationCode(
          _emailController.text, _verificationCode!);

      _startTimer(); // 启动计时器
      setState(() {
        _codeSent = true;
        _error = null;
      });

      Toaster.success(context, "已经成功发送验证码到邮箱，请去查看！");
    } catch (e) {
      setState(() {
        _error = '发送验证码失败：${e.toString()}';
        Toaster.error(context, "发送验证码失败");
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: Colors.red),
      );
    } finally {
      loadingObserver.hideLoading();
    }
  }

  Future<void> _handleRegister() async {
    // 验证所有表单字段
    if (!_formKey.currentState!.validate()) return;

    // 验证码检查
    if (_verificationCodeController.text != _verificationCode) {
      setState(() {
        _error = '验证码错误';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: Colors.red),
      );
      return;
    }

    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );

      // 清除错误状态
      setState(() {
        _error = null;
      });

      Toaster.success(context, "注册成功，请进行登录");

      // 注册成功后跳转到登录页面
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: Colors.red),
      );
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '注册',
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 半透明遮罩
          Opacity(
            opacity: 0.6,
            child: Container(
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // 注册表单 - 添加最大宽度约束
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500, // 设置最大宽度，注册表单略宽
              ),
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
                        // 标题
                        Text(
                          '创建新账号',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),

                        // 用户名输入
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: '用户名',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入用户名';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // 邮箱和验证码输入
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Form(
                                key: _emailFormKey,
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: '邮箱',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入邮箱';
                                    }
                                    if (!value.contains('@')) {
                                      return '请输入有效的邮箱地址';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            SizedBox(
                              width: 130, // 固定发送验证码按钮宽度
                              child: ElevatedButton(
                                onPressed: _error != null || _countDown > 0
                                    ? null
                                    : _sendVerificationCode,
                                child: Text(
                                  _countDown > 0
                                      ? '重新发送(${_countDown}s)'
                                      : (_codeSent ? '重新发送' : '发送验证码'),
                                  textAlign: TextAlign.center,
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // 验证码输入
                        TextFormField(
                          controller: _verificationCodeController,
                          decoration: InputDecoration(
                            labelText: '验证码',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.code),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入验证码';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // 密码输入（带显示/隐藏功能）
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            if (value.length < 6) {
                              return '密码长度至少6位';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),

                        // 确认密码
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: '确认密码',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return '两次输入的密码不一致';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),

                        // 注册按钮
                        ElevatedButton(
                          onPressed: _handleRegister,
                          child: Text('注册'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        SizedBox(height: 16),

                        // 登录跳转
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('已有账号？返回登录'),
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