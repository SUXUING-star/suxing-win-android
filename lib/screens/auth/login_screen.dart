// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/models/user/account.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart';
import '../../services/main/user/cache/account_cache_service.dart';
import '../../utils/navigation/navigation_utils.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/inputs/input_state_provider.dart';
import '../../widgets/ui/appbar/custom_app_bar.dart';
import './widgets/account_bubble_menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey(); // 这个 GlobalKey 仍然需要用于定位气泡菜单

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // 账号缓存服务
  late AccountCacheService _accountCache;
  bool _isAccountCacheInitialized = false;

  // --- 定义 slot 名称 ---
  static const String emailSlotName = 'login_email';
  static const String passwordSlotName = 'login_password';
  // --------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSavedAccounts());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAccountCacheInitialized) {
      // 避免重复获取和调用
      _accountCache = Provider.of<AccountCacheService>(context, listen: false);
      _isAccountCacheInitialized = true;
      _checkSavedAccounts(); // _checkSavedAccounts 会用 _accountCache
    }
  }

  Future<void> _checkSavedAccounts() async {
    final accounts = _accountCache.getAllAccounts();
    if (accounts.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showAccountBubbleMenu();
        }
      });
    }
  }

  void _showAccountBubbleMenu() {
    final accounts = _accountCache.getAllAccounts();
    if (accounts.isEmpty) return;
    final RenderBox? renderBox =
        _emailFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    // 稍微调整偏移量以更好地定位菜单
    final offset =
        Offset(position.dx + size.width / 2 - 50, position.dy + size.height);

    NavigationUtils.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return AccountBubbleMenu(
            anchorContext: context, // 使用 LoginScreen 的 context 作为 anchor
            anchorOffset: offset,
            onAccountSelected: _autoLoginWithAccount,
          );
        },
      ),
    );
  }

  // --- 修改：使用选择的账号自动登录，更新 InputStateService ---
  void _autoLoginWithAccount(SavedAccount account) {
    // 获取 InputStateService 并更新状态
    try {
      final inputService =
          Provider.of<InputStateService>(context, listen: false);
      // 使用 getController().text = ... 来触发更新，这样 TextInputField 会自动刷新
      inputService.getController(emailSlotName).text = account.email;
      inputService.getController(passwordSlotName).text = account.password;
      // 更新记住我状态（如果需要的话，或者保持当前选择）
      // setState(() { _rememberMe = true; });
    } catch (e) {
      print("Error accessing InputStateService in _autoLoginWithAccount: $e");
      // 可以考虑显示一个错误提示
      AppSnackBar.showError(context, "无法自动填充账号信息");
      return; // 无法更新，直接返回
    }

    // 触发登录
    _login();
  }
  // --- 结束修改 ---

  // --- 修改：登录操作，从 InputStateService 获取值，并在成功后清除状态 ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 获取 InputStateService
    final InputStateService inputService;
    try {
      inputService = Provider.of<InputStateService>(context, listen: false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '内部错误：无法访问输入状态服务。';
      });
      AppSnackBar.showError(context, _errorMessage!);
      return;
    }

    // 从 Service 获取值
    final email = inputService.getText(emailSlotName).trim();

    final password = inputService.getText(passwordSlotName).trim();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      SavedAccount? savedAccount;
      // 如果勾选了记住账号，保存登录信息
      if (_rememberMe) {
        final user = authProvider.currentUser;
        savedAccount = SavedAccount(
          email: email,
          password: password, // 注意：这里保存的是用户输入的密码
          username: user?.username,
          avatarUrl: user?.avatar,
          userId: user?.id,
          level: user?.level,
          experience: user?.experience,
          lastLogin: DateTime.now(),
        );
      }
      // 委托authProvider传递
      // ui组件不需要管理添加和删除缓存
      await authProvider.signIn(email, password, savedAccount);
      // 登录成功后，清除输入状态
      inputService.clearText(emailSlotName);
      inputService.clearText(passwordSlotName);

      await Future.delayed(Duration(milliseconds: 500)); // 稍微减少延迟

      if (mounted) {
        const String successMessage = "登录成功~🎉";
        NavigationUtils.navigateToHome(context, tabIndex: 0);
        AppSnackBar.showSuccess(context, successMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '登录失败：${e.toString()}';
          _isLoading = false; // 登录失败也要结束 loading
        });
        if (_errorMessage != null) {
          AppSnackBar.showError(context, _errorMessage!);
        }
      }
    } finally {
      // 确保无论成功失败，如果组件还在挂载，都结束 loading 状态
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // --- 结束修改 ---

  Widget _buildErrorMessageField() {
    return _errorMessage != null
        ? FadeInItem(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          )
        : SizedBox.shrink();
  }

  // --- 修改：使用 slotName ---
  Widget _buildEmailFormField() {
    return FormTextInputField(
      key: _emailFieldKey, // GlobalKey 保持
      slotName: emailSlotName, // <-- 使用 slotName
      isEnabled: !_isLoading,
      decoration: InputDecoration(
        labelText: '邮箱',
        prefixIcon: Icon(Icons.email),
        suffixIcon: _accountCache.getAllAccounts().isNotEmpty
            ? IconButton(
                icon:
                    Icon(Icons.account_circle_outlined), // 使用 outlined 图标可能更清晰
                tooltip: '选择已保存的账号',
                onPressed: _showAccountBubbleMenu,
              )
            : null,
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入邮箱';
        if (!value.contains('@')) return '请输入有效邮箱';
        return null;
      },
    );
  }

  // --- 修改：使用 slotName ---
  Widget _buildPassWordFormField() {
    return FormTextInputField(
      slotName: passwordSlotName, // <-- 使用 slotName
      // controller: _passwordController, // <-- 移除 controller
      isEnabled: !_isLoading,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: '密码',
        prefixIcon: Icon(Icons.lock_outline), // 使用 outlined 图标
        suffixIcon: IconButton(
          icon:
              Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() {
            _obscurePassword = !_obscurePassword;
          }),
        ),
      ),
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done, // 保留 done
      validator: (value) {
        if (value == null || value.isEmpty) return '请输入密码';
        if (value.length < 6) return '密码至少6位';
        if (value.length > 30) return '密码长度过长';
        return null;
      },
    );
  }
  // --- 结束修改 ---

  @override
  Widget build(BuildContext context) {
    const Duration initialDelay = Duration(milliseconds: 200);
    const Duration stagger = Duration(milliseconds: 80);

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
                  color: Colors.grey.withSafeOpacity(0.2),
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
                  _buildErrorMessageField(),
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger,
                    child: _buildEmailFormField(), // 已修改为使用 slotName
                  ),
                  const SizedBox(height: 16),
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 2,
                    child: _buildPassWordFormField(), // 已修改为使用 slotName
                  ),
                  const SizedBox(height: 16),
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 3,
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
                                context, '/forgot-password'),
                            label: '忘记密码?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 4,
                    child: FunctionalButton(
                      onPressed:
                          _isLoading ? () {} : _login, // 保持 loading 状态禁用逻辑
                      label: '登录',
                      isLoading: _isLoading, // <-- 传递 isLoading 状态
                      isEnabled: !_isLoading, // 明确传递 isEnabled
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 5,
                    child: FunctionalTextButton(
                      onPressed: () =>
                          NavigationUtils.pushNamed(context, '/register'),
                      label: '还没有账号？立即注册',
                    ),
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
    super.dispose();
  }
}
