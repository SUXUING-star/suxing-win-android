// lib/screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../widgets/ui/snackbar/app_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 可以在 initState 或 didChangeDependencies 中从 Provider 或其他地方加载初始值
  bool _darkModeEnabled = false; // 示例初始值
  bool _isLoading = false;
  String? _loadingMessage;
  bool _hasInitializedDependencies = false;
  //late final ThemeProvider _themeProvider;
  late final ForumService _forumService;
  late final GameService _gameService;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedDependencies) {
      //_themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _gameService = context.read<GameService>();
      _forumService = context.read<ForumService>();
      _hasInitializedDependencies = true;
    }
    // if (_hasInitializedDependencies) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) {
    //       setState(() {
    //         _darkModeEnabled = _themeProvider.isDarkMode;
    //       });
    //     }
    //   });
    // }
  }

  Future<void> _clearHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = '正在清除浏览历史...';
    });

    try {
      // 调用清除历史的方法 (确保它们返回 Future 或可以 await)
      await _gameService.clearGameHistory();
      await _forumService.clearPostHistory(); // 确认方法名正确

      if (!mounted) return;
      AppSnackBar.showSuccess(context, '浏览历史已清除');
    } catch (e, s) {
      //print("清除历史记录时出错: $e\n$s");
      if (!mounted) return;
      AppSnackBar.showError(context, '清除失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '设置'),
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
              ListTile(
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
          if (_isLoading)
            Container(
              color: Colors.black.withSafeOpacity(0.5),
              child: Center(
                child: LoadingWidget.fullScreen(
                  message: _loadingMessage,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
