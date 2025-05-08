// lib/utils/error/api_exception.dart
import 'api_error_definitions.dart'; // 确保这个文件路径正确

class ApiException implements Exception {
  final int httpStatusCode;
  final String apiErrorCode;       // 后端的业务错误码 (例如 "INVALID_CREDENTIALS")
  final String effectiveMessage;   // !!!!! 这个就是最终给用户看的干净消息 !!!!!
  final ApiErrorDescriptor descriptor; // 匹配到的错误描述符
  final dynamic originalData;     // 可选的: 后端返回的完整原始错误数据

  ApiException({
    required this.httpStatusCode,
    required this.apiErrorCode,
    required this.effectiveMessage, // 这个在 ApiErrorHandler 中已经正确赋值了
    required this.descriptor,
    this.originalData,
  });

  bool get isRetryable => descriptor.isRetryable;

  /// **核心修改在这里：toString() 现在只返回给用户看的干净消息**
  @override
  String toString() {
    return effectiveMessage; // 就返回这个，其他的都不要！
  }

  /// 如果你仍然需要在某些地方（比如日志）打印详细信息，可以保留或添加一个这样的方法
  String toDetailedString() {
    return 'ApiException: [HTTP $httpStatusCode] ${descriptor.code} - "$effectiveMessage" (Retryable: $isRetryable) ${originalData != null ? "(Data: $originalData)" : ""}';
  }
}