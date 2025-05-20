// lib/providers/user/user_data_status.dart (或者放在 user_info_provider.dart 里)
import 'package:suxingchahui/models/user/user.dart'; // 确保路径正确

enum LoadStatus { initial, loading, loaded, error }

class UserDataStatus {
  final LoadStatus status;
  final User? user;
  final dynamic error; // 可以存储错误信息

  UserDataStatus._({
    this.status = LoadStatus.initial,
    this.user,
    this.error,
  });

  factory UserDataStatus.initial() => UserDataStatus._();
  factory UserDataStatus.loading() =>
      UserDataStatus._(status: LoadStatus.loading);
  factory UserDataStatus.loaded(User user) =>
      UserDataStatus._(status: LoadStatus.loaded, user: user);
  factory UserDataStatus.error(dynamic error) =>
      UserDataStatus._(status: LoadStatus.error, error: error);

  // 你可以添加 getter 方便使用
  bool get isLoading => status == LoadStatus.loading;
  bool get hasData => status == LoadStatus.loaded && user != null;
  bool get hasError => status == LoadStatus.error;
}

