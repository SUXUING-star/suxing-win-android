// lib/screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// 需要 Provider 来读取 Service
import 'package:suxingchahui/services/main/forum/forum_service.dart';
import 'package:suxingchahui/services/main/game/game_service.dart';
import 'package:suxingchahui/widgets/ui/common/loading_widget.dart'; // 导入 LoadingWidget
import 'package:suxingchahui/widgets/ui/dialogs/confirm_dialog.dart';
import '../../../routes/app_routes.dart';
import '../../../services/main/user/user_service.dart';
import '../../../widgets/ui/appbar/custom_app_bar.dart';
import '../../../widgets/ui/snackbar/app_snackbar.dart'; // 导入 AppSnackBar

// --- SettingsState (保持不变) ---
class SettingsState {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final bool isLoading;
  final String? loadingMessage;

  SettingsState({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.isLoading = false,
    this.loadingMessage,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? isLoading,
    String? loadingMessage,
    bool clearLoadingMessage = false, // 新增：用于清除消息
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      isLoading: isLoading ?? this.isLoading,
      // 如果 clearLoadingMessage 为 true，则强制设为 null
      loadingMessage:
          clearLoadingMessage ? null : (loadingMessage ?? this.loadingMessage),
    );
  }
}

// --- SettingsEvent (保持不变) ---
abstract class SettingsEvent {}

class ToggleNotificationsEvent extends SettingsEvent {
  final bool value;
  ToggleNotificationsEvent(this.value);
}

class ToggleDarkModeEvent extends SettingsEvent {
  final bool value;
  ToggleDarkModeEvent(this.value);
}

class ClearHistoryEvent extends SettingsEvent {}

// --- SettingsBloc (修改 _onClearHistory 以便更好地处理完成状态) ---
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final UserService _userService;
  final GameService _gameService;
  final ForumService _postService;

  SettingsBloc(this._userService, this._gameService, this._postService)
      : super(SettingsState()) {
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<ToggleDarkModeEvent>(_onToggleDarkMode);
    on<ClearHistoryEvent>(_onClearHistory);
  }

  Future<void> _onToggleNotifications(
      ToggleNotificationsEvent event, Emitter<SettingsState> emit) async {
    // 这里可以添加保存设置的逻辑，如果需要持久化的话
    // print("SettingsBloc: Toggling notifications to ${event.value}");
    emit(state.copyWith(notificationsEnabled: event.value));
  }

  Future<void> _onToggleDarkMode(
      ToggleDarkModeEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(darkModeEnabled: event.value));
  }

  Future<void> _onClearHistory(
      ClearHistoryEvent event, Emitter<SettingsState> emit) async {
    // *** BLoC 内部管理加载状态 ***
    emit(state.copyWith(isLoading: true, loadingMessage: '正在清除浏览历史...' // 设置加载消息
        ));

    try {
      // 注意：这些应该是异步操作，如果它们是同步的，UI 可能不会及时更新
      // 假设它们是异步的或者很快完成
      await _gameService.clearGameHistory(); // 假设返回 Future
      await _postService.clearPostHistory(); // 假设返回 Future
      // *** 清除成功 ***
      print("SettingsBloc: History cleared successfully.");
      // 清除完成后，重置 isLoading 和 loadingMessage
      emit(state.copyWith(
          isLoading: false,
          clearLoadingMessage: true // 使用 clearLoadingMessage 清除消息
          ));
      // 可以在这里发送一个成功事件或状态，如果UI需要区分成功/失败
      // emit(state.copyWith(isLoading: false, clearLoadingMessage: true, successMessage: "历史已清除"));
    } catch (e, s) {
      // *** 清除失败 ***
      print("SettingsBloc: Error clearing history: $e\n$s");
      // 清除失败后，也要重置 isLoading 和 loadingMessage
      emit(state.copyWith(isLoading: false, clearLoadingMessage: true // 清除加载消息
          // 可以在这里发送一个错误事件或状态
          // errorMessage: "清除失败: $e"
          ));
      // 不需要 rethrow，让 BLoC 内部处理错误状态的传递
      // rethrow;
    }
  }
}

// --- SettingsScreen Widget ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 改为 StatelessWidget，因为状态由 Bloc 管理
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // 使用 create 而不是 value，确保每次进入页面都创建新的 Bloc 实例
      // 除非你有理由在父级管理这个 Bloc 的生命周期
      create: (context) => SettingsBloc(
        context.read<UserService>(), // 使用 context.read 获取依赖
        context.read<GameService>(),
        context.read<ForumService>(),
      ),
      child: Scaffold(
        appBar: CustomAppBar(title: '设置'),
        body: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {},
          builder: (context, state) {
            // *** 使用 Stack 来叠加加载指示器 ***
            return Stack(
              children: [
                // --- 主要设置列表 ---
                ListView(
                  children: [
                    // --- 深色模式开关 ---
                    ListTile(
                      leading: Icon(Icons.brightness_4),
                      title: Text('深色模式'),
                      trailing: Switch(
                        value: state.darkModeEnabled,
                        onChanged: (value) {
                          // 直接向 Bloc 发送事件
                          context
                              .read<SettingsBloc>()
                              .add(ToggleDarkModeEvent(value));
                        },
                      ),
                    ),
                    Divider(), // 分隔线

                    // --- 清除浏览历史 ---
                    ListTile(
                        leading: Icon(Icons.delete_sweep_outlined),
                        title: Text('清除浏览历史'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          // onTap 可以是 async
                          // 直接调用通用对话框
                          await CustomConfirmDialog.show(
                            context: context,
                            // 使用当前的 BuildContext
                            title: '确认清除',
                            message: '确定要清除所有游戏和帖子的浏览历史吗？此操作无法撤销。',
                            confirmButtonText: '确认清除',
                            confirmButtonColor: Colors.red,
                            iconData: Icons.warning_amber_rounded,
                            // 警告图标
                            iconColor: Colors.orange,
                            // 橙色图标
                            // *** onConfirm 回调，直接发送 BLoC 事件 ***
                            onConfirm: () async {
                              // onConfirm 必须是 async
                              // 不需要 try-catch，因为 BLoC 会处理结果
                              // 也不需要手动显示加载，因为 BLoC 状态会触发 UI 更新
                              print(
                                  "CustomConfirmDialog: Confirm clicked, dispatching ClearHistoryEvent.");
                              context
                                  .read<SettingsBloc>()
                                  .add(ClearHistoryEvent());
                              // 可以选择在这里给个即时反馈 SnackBar，表明操作已启动
                              AppSnackBar.showInfo(context, '正在处理...');
                            },
                            // onCancel 回调可选，这里不需要特殊处理
                          );
                        }),
                    Divider(), // 分隔线

                    // --- 关于页面 ---
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('关于'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.about);
                      },
                    ),
                    Divider(), // 分隔线
                  ],
                ),

                // --- 加载覆盖层 ---
                // *** 当 state.isLoading 为 true 时显示 ***
                if (state.isLoading)
                  // 半透明背景遮罩
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    // 使用 Center + LoadingWidget.fullScreen 来显示居中的加载指示器
                    child: Center(
                      child: LoadingWidget.fullScreen(
                        // 使用 fullScreen 样式
                        message: state.loadingMessage, // 显示 Bloc 状态中的消息
                        // 可以自定义颜色、大小等
                        // color: Colors.white,
                        // cardColor: Colors.grey[800]?.withOpacity(0.9),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
