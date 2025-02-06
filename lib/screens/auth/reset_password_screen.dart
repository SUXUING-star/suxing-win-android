// lib/screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../utils/loading_route_observer.dart';
import '../../widgets/common/toaster.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final UserService _authService = UserService();
  String? _error;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) return;

    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();

    try {
      await _authService.resetPassword(
        widget.email,
        _passwordController.text,
      );

      // 清除错误状态
      setState(() {
        _error = null;
      });

      Toaster.success(context, "重置密码成功，用新的密码进行登录吧！");

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() {
        _error = '重置密码失败：${e.toString()}';
      });
      Toaster.error(context, "重置密码失败");
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('重置密码')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '新密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入新密码';
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
                  labelText: '确认新密码',
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
                onPressed: _resetPassword,
                child: Text('重置密码'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}