// lib/providers/user/user_data_status.dart

/// 该文件定义了用户数据加载状态相关的枚举和类。
/// 它封装了用户数据的加载过程中的不同状态。
library;


import 'package:suxingchahui/models/user/user.dart'; // 导入用户模型

/// `LoadStatus` 枚举：表示数据加载的不同阶段。
enum LoadStatus {
  initial, // 初始状态，未开始加载
  loading, // 正在加载数据
  loaded, // 数据加载成功
  error, // 数据加载失败
}

/// `UserDataStatus` 类：封装用户数据的加载状态、数据和错误信息。
///
/// 该类提供统一的接口来表示用户数据的生命周期状态。
class UserDataStatus {
  final LoadStatus status; // 当前数据加载状态
  final User? user; // 加载成功的用户数据，加载中或失败时为 null
  final dynamic error; // 加载失败时的错误信息

  /// 私有构造函数。
  ///
  /// 用于内部创建 `UserDataStatus` 实例。
  UserDataStatus._({
    this.status = LoadStatus.initial,
    this.user,
    this.error,
  });

  /// 工厂构造函数：创建初始状态的 `UserDataStatus` 实例。
  factory UserDataStatus.initial() => UserDataStatus._();

  /// 工厂构造函数：创建加载中状态的 `UserDataStatus` 实例。
  factory UserDataStatus.loading() =>
      UserDataStatus._(status: LoadStatus.loading);

  /// 工厂构造函数：创建加载成功状态的 `UserDataStatus` 实例。
  ///
  /// [user]：加载成功的用户数据。
  factory UserDataStatus.loaded(User user) =>
      UserDataStatus._(status: LoadStatus.loaded, user: user);

  /// 工厂构造函数：创建加载失败状态的 `UserDataStatus` 实例。
  ///
  /// [error]：加载失败时捕获的错误对象。
  factory UserDataStatus.error(dynamic error) =>
      UserDataStatus._(status: LoadStatus.error, error: error);

  /// 判断当前状态是否为加载中。
  bool get isLoading => status == LoadStatus.loading;

  /// 判断当前状态是否为已加载且包含有效用户数据。
  bool get hasData => status == LoadStatus.loaded && user != null;

  /// 判断当前状态是否为错误。
  bool get hasError => status == LoadStatus.error;
}
