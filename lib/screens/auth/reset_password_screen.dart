import 'package:flutter/material.dart';
import 'dart:async'; // 导入 Timer
import '../../services/email_service.dart';
import '../../services/user_service.dart'; // 引入 AuthService
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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
  final UserService _authService = UserService(); // 使用 AuthService

  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationCode;

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


// 修改发送验证码方法
  Future<void> _sendVerificationCode() async {
    // 只验证邮箱字段
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      _verificationCode = EmailService.generateVerificationCode();
      await EmailService.sendVerificationCode(_emailController.text, _verificationCode!);

      _startTimer(); // 启动计时器

      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('验证码已发送到您的邮箱')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送验证码失败：${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 在 build 方法中修改发送验证码按钮
  Widget _buildSendCodeButton() {
    final buttonText = _countDown > 0
        ? '重新发送(${_countDown}s)'
        : (_codeSent ? '重新发送' : '发送验证码');

    return ElevatedButton(
      onPressed: (_isLoading || _countDown > 0) ? null : _sendVerificationCode,
      child: _isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Text(buttonText),
    );
  }


  // 在 register_screen.dart 的 _handleRegister 方法中修改
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_verificationCodeController.text != _verificationCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('验证码错误')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 使用 AuthService 进行注册
      await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('注册成功，请登录')),
      );

      // 注册成功后跳转到登录页面
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
                      key: _emailFormKey,  // 使用单独的 form key
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
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('注册'),
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