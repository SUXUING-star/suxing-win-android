// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/common/toaster/toaster.dart';
import '../../widgets/common/appbar/custom_app_bar.dart';
import '../../widgets/components/common/error_widget.dart';
import '../../widgets/components/common/loading_widget.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  late Box<String> _box;
  String? _error;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox<String>('loginBox');
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final savedEmail = _box.get('email');
    final savedPassword = _box.get('password');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _box.put('email', _emailController.text);
      await _box.put('password', _passwordController.text);
    } else {
      await _box.delete('email');
      await _box.delete('password');
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        _emailController.text,
        _passwordController.text,
      );

      await _saveCredentials();
      Toaster.success(context, '登录成功');
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() {
        _error = '登录失败: ${e.toString()}';
      });
      Toaster.error(context, '登录失败');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '登录',
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

          // 加载状态
          if (_isLoading)
            LoadingWidget.fullScreen(message: '正在登录...'),

          // 登录表单 - 添加最大宽度约束
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 450, // 设置最大宽度，避免在桌面上太宽
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
                        // Logo 或应用标题
                        Text(
                          '欢迎回来',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),

                        // 显示错误信息
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: CustomErrorWidget(
                              errorMessage: _error!,
                              icon: Icons.error_outline,
                              title: '登录错误',
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
                        SizedBox(height: 16),

                        // 密码输入，添加显示/隐藏密码功能
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

                        // 记住密码和忘记密码
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                              },
                            ),
                            Text('记住密码'),
                            Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/forgot-password');
                              },
                              child: Text('忘记密码？'),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // 登录按钮
                        ElevatedButton(
                          onPressed: () => _handleLogin(context),
                          child: Text('登录'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        SizedBox(height: 16),

                        // 注册跳转
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text('还没有账号？立即注册'),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}