// lib/screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/snackbar_notifier_mixin.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import '../../services/main/user/user_service.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import '../../widgets/ui/common/error_widget.dart';
import '../../widgets/ui/common/loading_widget.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SnackBarNotifierMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late final UserService _userService;

  bool _hasInitializedDependencies = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _userService = context.read<UserService>();
      _hasInitializedDependencies = true;
    }
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _userService.resetPassword(
        widget.email,
        _passwordController.text,
      );

      showSnackbar(message: "重置密码成功，用新的密码进行登录吧！", type: SnackbarType.success);

      if (!mounted) return;
      NavigationUtils.navigateToLogin(context);
    } catch (e) {
      setState(() {
        _error = '重置密码失败：${e.toString()}';
      });
      showSnackbar(message: "重置密码失败", type: SnackbarType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildNewPassWordFormField() {
    return FormTextInputField(
      controller: _passwordController,
      isEnabled: !_isLoading,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: '新密码',
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon:
              Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // <--- 密码键盘类型
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入新密码';
        if (value.length < 6) return '密码长度至少6位';
        if (value.length > 30) return '密码长度过长';
        return null;
      },
    );
  }

  Widget _buildRepeatPassWordFormField() {
    return FormTextInputField(
      controller: _confirmPasswordController,
      isEnabled: !_isLoading,
      obscureText: _obscureConfirmPassword, // <--- 设置 obscureText
      decoration: InputDecoration(
        labelText: '确认新密码',
        // border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword
              ? Icons.visibility_off
              : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // <--- 密码键盘类型
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value != _passwordController.text) return '两次输入的密码不一致';
        return null;
      },
    );
  }

  Widget _buildErrorMessageField() {
    return _error != null
        // --- 修改这里：添加动画 ---
        ? FadeInItem(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InlineErrorWidget(
                errorMessage: _error!,
                icon: Icons.error_outline,
                iconColor: Colors.red,
              ),
            ),
          )
        // --- 结束修改 ---
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    buildSnackBar(context);
    // --- 定义动画延迟和间隔 ---
    const Duration initialDelay = Duration(milliseconds: 200);
    const Duration stagger = Duration(milliseconds: 80);

    return Scaffold(
      appBar: CustomAppBar(
        title: '重置密码',
      ),
      body: Stack(
        children: [
          if (_isLoading)
            FadeInItem(
              // 使用 FadeInItem
              child: LoadingWidget.fullScreen(message: '正在重置密码...'),
            ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 450, // 设置最大宽度
              ),
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
                          child: AppText(
                            '重置密码',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        // 副标题
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger,
                          child: AppText(
                            '为您的账号设置新密码',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 24),

                        // 错误消息 (内部已加动画)
                        _buildErrorMessageField(),

                        // 新密码输入
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 2,
                          child: _buildNewPassWordFormField(),
                        ),
                        SizedBox(height: 16),

                        // 确认新密码输入
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 3,
                          child: _buildRepeatPassWordFormField(),
                        ),
                        SizedBox(height: 24),

                        // 重置密码按钮
                        FadeInSlideUpItem(
                          delay: initialDelay + stagger * 4,
                          child: FunctionalButton(
                            onPressed: _isLoading ? () => {} : _resetPassword,
                            // 保持 loading 禁用逻辑
                            label: '重置密码',
                            isEnabled: !_isLoading, // 保持 isEnabled
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
