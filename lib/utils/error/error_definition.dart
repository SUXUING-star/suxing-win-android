// lib/utils/error/error_definition.dart (新文件，干净独立)

/// 定义一个标准化的错误信息结构
class ErrorDefinition {
  /// 唯一的错误代码 (e.g., "SEC-001", "NET-404")
  final String code;

  /// 用户友好的消息模板 (不包含代码)
  final String userMessageTemplate;

  /// 这个错误是否允许用户通过界面重试？
  final bool isRetryable;

  const ErrorDefinition({
    required this.code,
    required this.userMessageTemplate,
    required this.isRetryable,
  });

  /// 辅助方法：生成最终给用户看的消息 (带代码)
  String formatForUser() {
    return '$userMessageTemplate (代码: $code)';
  }
}