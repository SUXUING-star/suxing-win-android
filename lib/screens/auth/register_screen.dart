// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/email_service.dart';
import '../../services/user_service.dart';
import '../../utils/loading_route_observer.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/loading_route_observer.dart';
import '../../widgets/common/toaster.dart';

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

  // 添加计时器相关变量
  Timer? _timer;
  int _countDown = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadingObserver = Navigator.of(context)
          .widget.observers
          .whereType<LoadingRouteObserver>()
          .first;

      // 不需要初始加载动画
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _timer?.cancel();  // 清理计时器
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
      await EmailService.sendVerificationCode(_emailController.text, _verificationCode!);

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
      Navigator.pushReplacementNamed(context, '/login');
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

  // 发送验证码按钮
  Widget _buildSendCodeButton() {
    final buttonText = _countDown > 0
        ? '重新发送(${_countDown}s)'
        : (_codeSent ? '重新发送' : '发送验证码');

    return ElevatedButton(
      onPressed: (_error != null || _countDown > 0) ? null : _sendVerificationCode,
      child: Text(buttonText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('注册')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 显示错误信息
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
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
                        ),
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
                  _buildSendCodeButton(),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _verificationCodeController,
                decoration: InputDecoration(
                  labelText: '验证码',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入验证码';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
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
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '两次输入的密码不一致';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleRegister,
                child: Text('注册'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
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
    );
  }
}