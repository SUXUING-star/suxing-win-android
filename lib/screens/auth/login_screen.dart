// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import '../../services/main/user/cache/account_cache_service.dart';
import '../../utils/navigation/navigation_utils.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import './widgets/account_bubble_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFieldKey = GlobalKey();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // 账号缓存服务
  final _accountCache = AccountCacheService();

  @override
  void initState() {
    super.initState();
    // 为了防止界面构建过程中弹出菜单导致的问题，使用延迟
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSavedAccounts());
  }

  // 检查是否有保存的账号
  Future<void> _checkSavedAccounts() async {
    final accounts = _accountCache.getAllAccounts();
    if (accounts.isNotEmpty) {
      // 延迟一下再显示气泡菜单，确保界面已完全构建
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showAccountBubbleMenu();
        }
      });
    }
  }

  // 显示账号气泡菜单
  void _showAccountBubbleMenu() {
    final accounts = _accountCache.getAllAccounts();
    if (accounts.isEmpty) return;

    // 获取账号图标按钮的位置
    final RenderBox? renderBox =
        _emailFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 计算按钮在屏幕中的位置
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final offset = Offset(position.dx + size.width - 120, position.dy);

    // 显示气泡菜单
    NavigationUtils.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return AccountBubbleMenu(
            anchorContext: context,
            anchorOffset: offset,
            onAccountSelected: _autoLoginWithAccount,
          );
        },
      ),
    );
  }

  // 使用选择的账号自动登录
  void _autoLoginWithAccount(SavedAccount account) {
    setState(() {
      _emailController.text = account.email;
      _passwordController.text = account.password;
    });

    // 自动登录
    _login();
  }

  // 登录操作
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(email, password);

      // 如果勾选了记住账号，保存登录信息
      if (_rememberMe) {
        final user = authProvider.currentUser;

        // 创建登录账号缓存
        final savedAccount = SavedAccount(
          email: email,
          password: password,
          username: user?.username,
          avatarUrl: user?.avatar,
          userId: user?.id,
          level: user?.level,
          experience: user?.experience,
          lastLogin: DateTime.now(),
        );

        // 保存到缓存
        await _accountCache.saveAccount(savedAccount);
      }

      // 登录成功后跳转到首页
      if (mounted) {
        const String successMessage = "登录成功~🎉";
        NavigationUtils.navigateToHome(context, tabIndex: 0);
        AppSnackBar.showSuccess(context, successMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '登录失败：${e.toString()}';
          _isLoading = false;
        });
        if (_errorMessage != null) {
          AppSnackBar.showError(context, _errorMessage!);
        }
      }
    }
  }

  Widget _buildErrorMessageField() {
    return _errorMessage != null
        ? FadeInItem(
            // 使用 FadeInItem 包裹
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          )
        // --- 结束修改 ---
        : SizedBox.shrink();
  }

  Widget _buildEmailFormField() {
    return FormTextInputField( // <--- 替换
      key: _emailFieldKey, // GlobalKey 保持
      controller: _emailController,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: '邮箱',
        prefixIcon: Icon(Icons.email),
        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), // FormTextInputField 有默认边框
        suffixIcon: _accountCache.getAllAccounts().isNotEmpty
            ? IconButton(
          icon: Icon(Icons.account_circle),
          tooltip: '选择已保存的账号',
          onPressed: _showAccountBubbleMenu,
        )
            : null,
      ),
      keyboardType: TextInputType.emailAddress, // <--- 设置 keyboardType
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入邮箱';
        if (!value.contains('@')) return '请输入有效邮箱';
        return null;
      },
    );
  }

  Widget _buildPassWordFormField() {
    return FormTextInputField( // <--- 替换
      controller: _passwordController,
      enabled: !_isLoading,
      obscureText: _obscurePassword, // <--- 设置 obscureText
      decoration: InputDecoration(
        labelText: '密码',
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
        ),
        // border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: TextInputType.visiblePassword, // <--- 密码键盘类型
      textInputAction: TextInputAction.done, // 登录页密码后通常是 done
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入密码';
        if (value.length < 6) return '密码至少6位';
        if (value.length > 30) return '密码长度过长';
        return null;
      },
      // 可以在这里添加 onSubmitted，尝试直接登录
      // onSubmitted: (_) {
      //   if (!_isLoading) _login();
      // },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 定义基础延迟和间隔
    const Duration initialDelay = Duration(milliseconds: 200); // 登录页可以稍微慢点开始
    const Duration stagger = Duration(milliseconds: 80); // 元素间间隔

    return Scaffold(
      appBar: CustomAppBar(title: '登录'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            // 这个外部容器可以不加动画，让内部元素滑入
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 10,
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 修改这里：添加动画 ---
                  // 欢迎标题
                  FadeInSlideUpItem(
                    delay: initialDelay,
                    child: AppText(
                      '欢迎回来',
                      textAlign: TextAlign.center,
                      type: AppTextType.title,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 错误消息 (在 _buildErrorMessageField 内部添加动画)
                  _buildErrorMessageField(),

                  // 邮箱输入框
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger, // 延迟
                    child: _buildEmailFormField(),
                  ),
                  const SizedBox(height: 16),

                  // 密码输入框
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 2, // 再延迟
                    child: _buildPassWordFormField(),
                  ),
                  const SizedBox(height: 16),

                  // 记住密码和忘记密码行
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 3, // 再延迟
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() {
                            _rememberMe = value ?? false;
                          }),
                        ),
                        Text('记住账号'),
                        const Spacer(),
                        FunctionalTextButton(
                            onPressed: () => NavigationUtils.pushNamed(
                                context, '/forgot-password'), // 路由可能需要调整
                            label: '忘记密码?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 4, // 再延迟
                    child: FunctionalButton(
                      onPressed:
                          _isLoading ? ()=> {} : _login, // 保持 loading 状态禁用逻辑
                      label: '登录',
                      isEnabled: !_isLoading, // 保持 isEnabled
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 注册跳转按钮
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 5, // 最后出现
                    child: FunctionalTextButton(
                      // onPressed: () => NavigationUtils.navigateToLogin(context), // 这里应该是去注册页
                      onPressed: () => NavigationUtils.pushNamed(
                          context, '/register'), // 假设注册页路由是 /register
                      label: '还没有账号？立即注册',
                    ),
                  ),
                  // --- 结束修改 ---
                ],
              ),
            ),
          ),
        ),
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
