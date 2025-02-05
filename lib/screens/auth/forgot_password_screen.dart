// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../../services/email_service.dart';
import '../../services/user_service.dart';  // 引入 AuthService

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final UserService _authService = UserService(); // 使用 AuthService
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationCode;

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. 验证邮箱是否存在
      //    如果用户存在，则发送验证码
      //    如果用户不存在，则提示用户
      try {
        await _authService.resetPassword(_emailController.text, "123456"); // 发送验证码前确保邮箱存在
        _verificationCode = EmailService.generateVerificationCode();
        await EmailService.sendVerificationCode(
            _emailController.text,
            _verificationCode!
        );

        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('验证码已发送到您的邮箱')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('用户不存在：$e')),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送验证码失败：$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;
    if (_codeController.text != _verificationCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('验证码错误')),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/reset-password',
      arguments: _emailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('找回密码')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
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
              SizedBox(height: 16),
              if (_codeSent) ...[
                TextFormField(
                  controller: _codeController,
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
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendVerificationCode,
                      child: Text(_codeSent ? '重新发送' : '发送验证码'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  if (_codeSent) ...[
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _verifyCode,
                        child: Text('验证'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}