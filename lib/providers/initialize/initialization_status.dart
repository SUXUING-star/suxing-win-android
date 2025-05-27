// lib/providers/initialize/initialization_status.dart
/// 定义应用初始化过程的几种状态
enum InitializationStatus {
  /// 初始状态或空闲状态
  idle,

  /// 正在进行初始化
  inProgress,

  /// 初始化过程中发生错误
  error,

  /// 初始化成功完成
  completed,
}