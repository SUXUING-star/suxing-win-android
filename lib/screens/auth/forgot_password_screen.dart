// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../../services/main/email/email_service.dart';
import 'dart:async';
import '../../widgets/common/toaster/toaster.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/components/common/error_widget.dart';
import '../../widgets/components/common/loading_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _error;
  bool _codeSent = false;
  String? _verificationCode;
  int _countDown = 0;
  Timer? _timer;
  bool _isLoading = false;

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _verificationCode = EmailService.generateVerificationCode();
      await EmailService.sendPasswordResetCode(
          _emailController.text,
          _verificationCode!
      );

      _startTimer();
      setState(() {
        _codeSent = true;
        _error = null;
      });

      Toaster.success(context, "已经成功发送验证码到邮箱，请去查看！");
    } catch (e) {
      setState(() {
        _error = '用户不存在：$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;

    if (_codeController.text != _verificationCode) {
      setState(() {
        _error = '验证码错误';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!), backgroundColor: Colors.red),
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
      appBar: CustomAppBar(
        title: '找回密码',
      ),
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
          // 加载状态处理
          if (_isLoading)
            LoadingWidget.fullScreen(message: '正在发送验证码...'),

          // 找回密码表单 - 添加最大宽度约束
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 450, // 设置最大宽度
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
                          '找回密码',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '通过邮箱重置您的密码',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 24),

                        // 显示错误信息 - 使用自定义错误组件
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: CustomErrorWidget(
                              errorMessage: _error!,
                              icon: Icons.error_outline,
                              title: '错误',
                              retryText: '重试',
                              iconColor: Colors.red,
                              onRetry: () {
                                setState(() {
                                  _error = null;
                                });
                              },
                            ),
                          ),

                        // 邮箱输入
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: '邮箱',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
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

                        // 验证码输入（仅在发送验证码后显示）
                        if (_codeSent)
                          TextFormField(
                            controller: _codeController,
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
                        if (_codeSent) SizedBox(height: 16),

                        // 发送/重新发送验证码和验证按钮
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _countDown > 0 ? null : _sendVerificationCode,
                                child: Text(_codeSent
                                    ? (_countDown > 0 ? '重新发送(${_countDown}s)' : '重新发送')
                                    : '发送验证码'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(0, 48),
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
                                    minimumSize: Size(0, 48),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}