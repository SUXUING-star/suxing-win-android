// lib/models/error/idempotency_error_details.dart

// 用于携带错误信息的简单数据类
import 'package:suxingchahui/models/error/idempotency_error_code.dart';

class IdempotencyErrorDetails {
  final IdempotencyExceptionCode code;
  final String message;
  final DateTime timestamp; // 记录错误发生时间，可选

  IdempotencyErrorDetails({
    required this.code,
    required this.message,
  }) : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is IdempotencyErrorDetails &&
              runtimeType == other.runtimeType &&
              code == other.code &&
              message == other.message &&
              timestamp == other.timestamp; // 比较时间戳确保是同一个错误实例

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ timestamp.hashCode;
}