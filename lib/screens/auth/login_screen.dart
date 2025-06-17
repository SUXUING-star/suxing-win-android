// lib/screens/auth/login_screen.dart

/// 该文件定义了 LoginScreen 组件，一个用于用户登录的屏幕。
/// LoginScreen 负责处理用户认证、管理输入状态和显示登录结果。
library;

import 'package:flutter/material.dart'; // 导入 Flutter UI 组件
import 'package:provider/provider.dart'; // 导入 Provider，用于访问服务
import 'package:suxingchahui/models/user/account.dart'; // 导入账号模型
import 'package:suxingchahui/providers/navigation/sidebar_provider.dart'; // 导入侧边栏 Provider
import 'package:suxingchahui/routes/app_routes.dart'; // 导入应用路由
import 'package:suxingchahui/widgets/ui/components/user/account_bubble_menu.dart'; // 导入账号气泡菜单组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart'; // 导入淡入动画组件
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 导入向上滑入淡入动画组件
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart'; // 导入功能按钮
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart'; // 导入功能文本按钮
import 'package:suxingchahui/widgets/ui/common/error_widget.dart'; // 导入错误组件
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart'; // 导入颜色扩展工具
import 'package:suxingchahui/widgets/ui/inputs/form_text_input_field.dart'; // 导入表单文本输入框组件
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart'; // 导入应用 SnackBar 工具
import 'package:suxingchahui/widgets/ui/text/app_text.dart'; // 导入应用文本组件
import 'package:suxingchahui/widgets/ui/text/app_text_type.dart'; // 导入应用文本类型
import 'package:suxingchahui/services/main/user/cache/account_cache_service.dart'; // 导入账号缓存服务
import 'package:suxingchahui/utils/navigation/navigation_utils.dart'; // 导入导航工具类
import 'package:suxingchahui/providers/auth/auth_provider.dart'; // 导入认证 Provider
import 'package:suxingchahui/providers/inputs/input_state_provider.dart'; // 导入输入状态 Provider
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart'; // 导入自定义 AppBar

/// `LoginScreen` 类：用户登录屏幕组件。
///
/// 该屏幕提供邮箱和密码输入，支持记住账号、忘记密码和新用户注册功能。
class LoginScreen extends StatefulWidget {
  final AuthProvider authProvider; // 认证 Provider
  final InputStateService inputStateService; // 输入状态服务
  final SidebarProvider sidebarProvider; // 侧边栏 Provider
  /// 构造函数。
  ///
  /// [authProvider]：认证 Provider。
  /// [inputStateService]：输入状态服务。
  /// [sidebarProvider]：侧边栏 Provider。
  const LoginScreen({
    super.key,
    required this.authProvider,
    required this.inputStateService,
    required this.sidebarProvider,
  });

  /// 创建状态。
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

/// `_LoginScreenState` 类：`LoginScreen` 的状态管理。
///
/// 管理表单验证、输入状态、加载状态和账号缓存功能。
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // 表单键
  final _emailFieldKey = GlobalKey(); // 邮箱输入框的全局键，用于定位气泡菜单

  bool _rememberMe = true; // 记住账号状态
  bool _obscurePassword = true; // 隐藏密码状态
  bool _isLoading = false; // 登录加载状态
  String? _errorMessage; // 错误消息

  static const String emailSlotName = 'login_email'; // 邮箱输入框槽名称
  static const String passwordSlotName = 'login_password'; // 密码输入框槽名称

  late final AccountCacheService _accountCache; // 账号缓存服务实例

  bool _hasInitializedDependencies = false; // 依赖初始化标记

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      // 依赖未初始化时
      _accountCache = Provider.of<AccountCacheService>(context,
          listen: false); // 从 Provider 获取账号缓存服务
      _hasInitializedDependencies = true; // 标记为已初始化
    }
    if (_hasInitializedDependencies) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkSavedAccounts()); // 检查已保存账号
    }
  }

  /// 检查已保存账号。
  ///
  /// 如果存在已保存账号，则延迟显示账号气泡菜单。
  Future<void> _checkSavedAccounts() async {
    final accounts = _accountCache.getAllAccounts(); // 获取所有已保存账号
    if (accounts.isNotEmpty) {
      // 账号列表不为空时
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // 组件已挂载时
          _showAccountBubbleMenu(); // 显示账号气泡菜单
        }
      });
    }
  }

  /// 显示账号气泡菜单。
  ///
  /// 从邮箱输入框位置弹出菜单，供用户选择已保存的账号。
  void _showAccountBubbleMenu() {
    final accounts = _accountCache.getAllAccounts(); // 获取所有已保存账号
    if (accounts.isEmpty) return; // 账号列表为空时返回
    final RenderBox? renderBox = _emailFieldKey.currentContext
        ?.findRenderObject() as RenderBox?; // 获取邮箱输入框的渲染盒
    if (renderBox == null) return; // 渲染盒为空时返回
    final position = renderBox.localToGlobal(Offset.zero); // 邮箱输入框的全局位置
    final size = renderBox.size; // 邮箱输入框的尺寸
    final offset = Offset(position.dx + size.width / 2 - 50,
        position.dy + size.height); // 计算菜单偏移量

    NavigationUtils.of(context).push(
      // 推入新的路由
      PageRouteBuilder(
        opaque: false, // 路由不透明
        barrierDismissible: true, // 可点击外部关闭
        pageBuilder: (BuildContext context, _, __) {
          return AccountBubbleMenu(
            accounts: accounts, // 账号列表
            anchorContext: context, // 锚点上下文
            anchorOffset: offset, // 锚点偏移量
            onAccountSelected: _autoLoginWithAccount, // 账号选中回调
          );
        },
      ),
    );
  }

  /// 使用选择的账号自动登录。
  ///
  /// [account]：选中的已保存账号。
  /// 自动填充邮箱和密码，并触发登录。
  void _autoLoginWithAccount(SavedAccount account) {
    try {
      widget.inputStateService.getController(emailSlotName).text =
          account.email; // 填充邮箱
      widget.inputStateService.getController(passwordSlotName).text =
          account.password; // 填充密码
    } catch (e) {
      AppSnackBar.showError( "无法自动填充账号信息"); // 显示错误提示
      return; // 无法更新时返回
    }

    _login(); // 触发登录
  }

  /// 执行登录操作。
  ///
  /// 验证表单，调用认证服务进行登录，并处理登录结果。
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return; // 表单验证失败时返回

    setState(() {
      _isLoading = true; // 设置加载状态
      _errorMessage = null; // 清空错误消息
    });

    final email =
        widget.inputStateService.getText(emailSlotName).trim(); // 获取邮箱
    final password =
        widget.inputStateService.getText(passwordSlotName).trim(); // 获取密码

    try {
      await widget.authProvider
          .signIn(email, password, _rememberMe); // 调用认证服务登录
      widget.inputStateService.clearText(emailSlotName); // 清空邮箱输入
      widget.inputStateService.clearText(passwordSlotName); // 清空密码输入

      await Future.delayed(const Duration(milliseconds: 500)); // 延迟

      if (mounted) {
        // 组件已挂载时
        const String successMessage = "登录成功~🎉"; // 成功消息
        NavigationUtils.navigateToHome(widget.sidebarProvider, context,
            tabIndex: 0); // 导航到首页
        AppSnackBar.showSuccess( successMessage); // 显示成功提示
      }
    } catch (e) {
      // 捕获登录失败异常
      if (mounted) {
        // 组件已挂载时
        setState(() {
          _errorMessage = '登录失败：${e.toString()}'; // 设置错误消息
          _isLoading = false; // 结束加载状态
        });
        if (_errorMessage != null) {
          // 显示错误提示
          AppSnackBar.showError(_errorMessage!);
        }
      }
    } finally {
      // 无论成功失败，确保加载状态重置
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 构建错误消息字段。
  ///
  /// 如果存在错误消息，则显示淡入动画的文本。
  Widget _buildErrorMessageField() {
    return _errorMessage != null
        ? FadeInItem(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16), // 底部内边距
              child: Text(
                _errorMessage!, // 错误消息
                style: const TextStyle(color: Colors.red), // 文本样式
                textAlign: TextAlign.center, // 文本居中
              ),
            ),
          )
        : const SizedBox.shrink(); // 否则返回空组件
  }

  /// 构建邮箱表单字段。
  ///
  /// 包含邮箱输入框、前缀图标和可选的后缀图标（用于选择已保存账号）。
  Widget _buildEmailFormField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      key: _emailFieldKey, // 全局键
      slotName: emailSlotName, // 槽名称
      isEnabled: !_isLoading, // 根据加载状态禁用
      decoration: InputDecoration(
        labelText: '邮箱', // 标签文本
        prefixIcon: const Icon(Icons.email), // 前缀图标
        suffixIcon: _accountCache.getAllAccounts().isNotEmpty // 存在已保存账号时显示后缀图标
            ? IconButton(
                icon: const Icon(Icons.account_circle_outlined), // 图标
                tooltip: '选择已保存的账号', // 提示
                onPressed: _showAccountBubbleMenu, // 点击回调
              )
            : null,
      ),
      keyboardType: TextInputType.emailAddress, // 键盘类型为邮箱
      textInputAction: TextInputAction.next, // 文本输入动作为下一项
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty) return '请输入邮箱';
        if (!value.contains('@')) return '请输入有效邮箱';
        return null;
      },
    );
  }

  /// 构建密码表单字段。
  ///
  /// 包含密码输入框、前缀图标和切换密码可见性的后缀图标。
  Widget _buildPassWordFormField() {
    return FormTextInputField(
      inputStateService: widget.inputStateService, // 输入状态服务
      slotName: passwordSlotName, // 槽名称
      isEnabled: !_isLoading, // 根据加载状态禁用
      obscureText: _obscurePassword, // 隐藏密码
      decoration: InputDecoration(
        labelText: '密码', // 标签文本
        prefixIcon: const Icon(Icons.lock_outline), // 前缀图标
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword
              ? Icons.visibility_off
              : Icons.visibility), // 切换密码可见性图标
          onPressed: () => setState(() {
            _obscurePassword = !_obscurePassword; // 切换隐藏密码状态
          }),
        ),
      ),
      keyboardType: TextInputType.visiblePassword, // 键盘类型为可见密码
      textInputAction: TextInputAction.done, // 文本输入动作为完成
      validator: (value) {
        // 验证器
        if (value == null || value.isEmpty) return '请输入密码';
        if (value.length < 6) return '密码至少6位';
        if (value.length > 30) return '密码长度过长';
        return null;
      },
    );
  }

  /// 构建登录屏幕的主体 UI。
  @override
  Widget build(BuildContext context) {
    const Duration initialDelay = Duration(milliseconds: 200); // 初始延迟
    const Duration stagger = Duration(milliseconds: 80); // 交错延迟

    if (widget.authProvider.isLoggedIn) {
      // 如果用户已登录
      return CustomErrorWidget(
        title: "停停停", // 标题
        errorMessage: "好像你已经登录了啊？？", // 错误消息
        onRetry: () => NavigationUtils.of(context), // 点击重试回调
        retryText: "返回上一页", // 重试按钮文本
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: '登录'), // AppBar
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24), // 内边距
          child: Container(
            width: 400, // 宽度
            padding: const EdgeInsets.all(32), // 内边距
            decoration: BoxDecoration(
              color: Colors.white, // 背景色
              borderRadius: BorderRadius.circular(16), // 圆角
              boxShadow: [
                // 阴影
                BoxShadow(
                  color: Colors.grey.withSafeOpacity(0.2), // 阴影颜色
                  spreadRadius: 3, // 扩散半径
                  blurRadius: 10, // 模糊半径
                )
              ],
            ),
            child: Form(
              key: _formKey, // 表单键
              child: Column(
                mainAxisSize: MainAxisSize.min, // 列主轴尺寸最小化
                crossAxisAlignment: CrossAxisAlignment.stretch, // 交叉轴拉伸
                children: [
                  FadeInSlideUpItem(
                    delay: initialDelay, // 延迟
                    child: AppText(
                      '欢迎回来', // 欢迎文本
                      textAlign: TextAlign.center, // 文本居中
                      type: AppTextType.title, // 文本类型
                      fontWeight: FontWeight.bold, // 字体粗细
                    ),
                  ),
                  const SizedBox(height: 24), // 间距
                  _buildErrorMessageField(), // 错误消息字段
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger, // 延迟
                    child: _buildEmailFormField(), // 邮箱表单字段
                  ),
                  const SizedBox(height: 16), // 间距
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 2, // 延迟
                    child: _buildPassWordFormField(), // 密码表单字段
                  ),
                  const SizedBox(height: 16), // 间距
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 3, // 延迟
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberMe, // 记住账号复选框值
                          onChanged: (value) => setState(() {
                            _rememberMe = value ?? false; // 切换记住账号状态
                          }),
                        ),
                        const Text('记住账号'), // 记住账号文本
                        const Spacer(), // 间距
                        FunctionalTextButton(
                            onPressed: () => NavigationUtils.pushNamed(
                                context, AppRoutes.forgotPassword), // 导航到忘记密码页面
                            label: '忘记密码?'), // 忘记密码按钮
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // 间距
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 4, // 延迟
                    child: FunctionalButton(
                      onPressed: _isLoading ? null : _login, // 登录按钮点击回调
                      label: '登录', // 按钮文本
                      isLoading: _isLoading, // 加载状态
                      isEnabled: !_isLoading, // 启用状态
                    ),
                  ),
                  const SizedBox(height: 16), // 间距
                  FadeInSlideUpItem(
                    delay: initialDelay + stagger * 5, // 延迟
                    child: FunctionalTextButton(
                      onPressed: () => NavigationUtils.pushNamed(
                          context, AppRoutes.register), // 导航到注册页面
                      label: '还没有账号？立即注册', // 注册按钮
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
}
