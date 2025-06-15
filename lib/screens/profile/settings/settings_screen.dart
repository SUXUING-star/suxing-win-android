// lib/screens/profile/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/user/user.dart';
import 'package:suxingchahui/providers/auth/auth_provider.dart';
import 'package:suxingchahui/services/main/forum/post_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_item.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import 'package:suxingchahui/routes/app_routes.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';

class SettingsScreen extends StatefulWidget {
  final GameService gameService;
  final PostService postService;
  final AuthProvider authProvider;
  const SettingsScreen({
    super.key,
    required this.gameService,
    required this.postService,
    required this.authProvider,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 可以在 initState 或 didChangeDependencies 中从 Provider 或其他地方加载初始值
  bool _darkModeEnabled = false; // 示例初始值
  bool _isLoading = false;
  String? _loadingMessage;
  bool _hasInitializedDependencies = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
    }
  }

  Future<void> _clearHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = '正在清除浏览历史...';
    });
    if (!widget.authProvider.isLoggedIn) {
      AppSnackBar.showLoginRequiredSnackBar(context);
      return;
    }

    try {
      // 调用清除历史的方法 (确保它们返回 Future 或可以 await)
      await widget.gameService.clearGameHistory();
      await widget.postService.clearPostHistory();

      if (!mounted) return;
      AppSnackBar.showSuccess('浏览历史已清除');
    } catch (e) {
      //print("清除历史记录时出错: $e\n$s");
      AppSnackBar.showError('清除失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      const FadeInItem(
        // 全屏加载组件
        child: LoadingWidget(
          isOverlay: true,
          message: "少女正在祈祷中...",
          overlayOpacity: 0.4,
          size: 36,
        ),
      );
    }
    return Scaffold(
      appBar: const CustomAppBar(title: '设置'),
      body: Stack(
        children: [
          ListView(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.brightness_4_outlined), // 使用 outlined 图标
                title: const Text('深色模式'),
                trailing: Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                      // 这里应该调用 ThemeProvider 来切换主题
                      // context.read<ThemeProvider>().toggleTheme(value);
                      // print("切换深色模式: $value"); // 调试输出
                    });
                  },
                ),
              ),
              const Divider(height: 1),
              StreamBuilder<User?>(
                stream: widget.authProvider.currentUserStream,
                initialData: widget.authProvider.currentUser,
                builder: (context, authSnapshot) {
                  final currentUser = authSnapshot.data;
                  if (currentUser == null) {
                    return const SizedBox.shrink();
                  } else {
                    return ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: const Text('清除浏览历史'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await CustomConfirmDialog.show(
                          context: context,
                          title: '确认清除',
                          message: '确定要清除所有游戏和帖子的浏览历史吗？此操作无法撤销。',
                          confirmButtonText: '确认清除',
                          confirmButtonColor: Colors.red,
                          iconData: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                          onConfirm: _clearHistory, // 直接传递方法引用
                        );
                      },
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.about);
                },
              ),
              const Divider(height: 1),
            ],
          ),
        ],
      ),
    );
  }
}
