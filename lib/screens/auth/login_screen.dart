// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import '../../services/main/user/cache/account_cache_service.dart';
import '../../utils/navigation/navigation_utils.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import './widgets/account_bubble_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
        NavigationUtils.navigateToHome(context, tabIndex: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '登录失败：${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '登录'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
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
                  Text(
                    '欢迎回来',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // 错误提示
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // 邮箱输入
                  TextFormField(
                    key: _emailFieldKey,
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      // 添加账号选择按钮
                      suffixIcon: _accountCache.getAllAccounts().isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.account_circle),
                              tooltip: '选择已保存的账号',
                              onPressed: _showAccountBubbleMenu,
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入邮箱';
                      if (!value.contains('@')) return '请输入有效邮箱';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 密码输入
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '请输入密码';
                      if (value.length < 6) return '密码至少6位';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 记住密码
                  Row(
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
                              context, '/forgot-password'),
                          label: '忘记密码?'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 登录按钮
                  FunctionalButton(
                    onPressed: _login,
                    label: '登录',
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // 注册跳转
                  FunctionalTextButton(
                    onPressed: () =>
                        NavigationUtils.pushNamed(context, '/register'),
                    label: '还没有账号？立即注册',
                  ),
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
