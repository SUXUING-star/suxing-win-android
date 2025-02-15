// lib/screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../routes/app_routes.dart';
import '../../../services/history/game_history_service.dart';
import '../../../services/history/post_history_service.dart';
import '../../../services/user_service.dart';
import '../../../utils/loading_route_observer.dart';
import '../../../widgets/common/custom_app_bar.dart';

// 状态
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
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
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
  final GameHistoryService _gameHistoryService;
  final PostHistoryService _postHistoryService;

  SettingsBloc(
      this._userService,
      this._gameHistoryService,
      this._postHistoryService
      ) : super(SettingsState()) {
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
    try {
      emit(state.copyWith(
          isLoading: true,
          loadingMessage: '正在清除浏览历史...'
      ));

      _gameHistoryService.clearGameHistory();
      _postHistoryService.clearPostHistory();

      emit(state.copyWith(
          isLoading: false,
          loadingMessage: null
      ));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false,
          loadingMessage: null
      ));

      rethrow;
    }
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    _settingsBloc = SettingsBloc(
      context.read<UserService>(),
      context.read<GameHistoryService>(),
      context.read<PostHistoryService>(),
    );
  }

  @override
  void dispose() {
    _settingsBloc.close();
    super.dispose();
  }

  void _showClearHistoryDialog() {
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
              _clearHistory(context);
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  void _clearHistory(BuildContext context) async {
    final loadingObserver = Navigator.of(context)
        .widget.observers
        .whereType<LoadingRouteObserver>()
        .first;

    loadingObserver.showLoading();
    try {
      context.read<SettingsBloc>().add(ClearHistoryEvent());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('浏览历史已清除')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清除失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      loadingObserver.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _settingsBloc,
      child: Scaffold(
        appBar: CustomAppBar(
            title: '设置'
        ),
        body: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state.isLoading) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.loadingMessage ?? '处理中...')),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                ListView(
                  children: [

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
                      leading: Icon(Icons.info_outline),
                      title: Text('关于'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.about);
                      },
                    ),
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
}