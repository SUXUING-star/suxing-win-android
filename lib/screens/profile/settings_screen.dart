// lib/screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../routes/app_routes.dart';
import '../../services/history_service.dart';
import '../../services/user_service.dart';

// 状态
class SettingsState {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final bool isLoading; // 添加 loading 状态

  SettingsState({
    required this.notificationsEnabled,
    required this.darkModeEnabled,
    this.isLoading = false,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? isLoading,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 事件
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

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final UserService _userService;
  final HistoryService _historyService;

  SettingsBloc(this._userService, this._historyService)
      : super(SettingsState(notificationsEnabled: true, darkModeEnabled: false)) {
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<ToggleDarkModeEvent>(_onToggleDarkMode);
    on<ClearHistoryEvent>(_onClearHistory);
  }

  Future<void> _onToggleNotifications(
      ToggleNotificationsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(notificationsEnabled: event.value));
  }

  Future<void> _onToggleDarkMode(
      ToggleDarkModeEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(darkModeEnabled: event.value));
  }

  Future<void> _onClearHistory(
      ClearHistoryEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true)); // 设置 loading 状态
    try {
      await _historyService.clearHistory();
      emit(state.copyWith(isLoading: false)); // 取消 loading 状态
      // 在 UI 中展示成功消息
    } catch (e) {
      print('Clear history error: $e');
      emit(state.copyWith(isLoading: false)); // 取消 loading 状态
      // 在 UI 中展示失败消息
    }
  }
}

// 修改 SettingsScreen
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(
        context.read<UserService>(),
        context.read<HistoryService>(),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text('设置')),
        body: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            // 处理清除历史记录的结果，展示 SnackBar
            if (!state.isLoading) {  // 仅在清除历史记录结束后显示
              if (state != context.read<SettingsBloc>().state){ // 确保 listener 里的 state 是真正触发改变的 state
                if (_isHistoryClearSuccessful(context)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('浏览历史已清除')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('清除失败')),
                  );
                }
              }

            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                ListView(
                  children: [
                    ListTile(
                      leading: Icon(Icons.notifications),
                      title: Text('消息通知'),
                      trailing: Switch(
                        value: state.notificationsEnabled,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(ToggleNotificationsEvent(value));
                        },
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.brightness_4),
                      title: Text('深色模式'),
                      trailing: Switch(
                        value: state.darkModeEnabled,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(ToggleDarkModeEvent(value));
                        },
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('清除浏览历史'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('清除浏览历史'),
                            content: Text('确定要清除所有浏览历史吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('取消'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<SettingsBloc>().add(ClearHistoryEvent());
                                },
                                child: Text('确定'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.security),
                      title: Text('隐私政策'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: 跳转到隐私政策页面
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('关于'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.about);
                      },
                    ),
                    // ... 其他设置项
                  ],
                ),
                if (state.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // A function to determine if history clear was successful.
  // Because there is no success feedback from the `HistoryService.clearHistory` function,
  // a placeholder implementation returns true if no error occurred during the history clear.
  bool _isHistoryClearSuccessful(BuildContext context) {
    // A placeholder implementation
    return true;
  }
}