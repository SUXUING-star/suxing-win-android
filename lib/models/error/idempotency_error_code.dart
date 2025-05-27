// lib/models/error/idempotency_error_code.dart


class IdempotencyException implements Exception {
  final String message;
  final IdempotencyExceptionCode? code;
  IdempotencyException(this.message, {this.code});
  @override
  String toString() => 'IdempotencyException: $message (code: ${code?.name})';
}

enum IdempotencyExceptionCode {
  alreadyProcessed('IDEMPOTENCY_ALREADY_PROCESSED'),
  inProgress('IDEMPOTENCY_IN_PROGRESS'),
  dbReadError('IDEMPOTENCY_DB_READ_ERROR'), // 对应后端错误码
  lockError('IDEMPOTENCY_LOCK_ERROR'), // 对应后端错误码
  dbUpdateError('IDEMPOTENCY_DB_UPDATE_ERROR'), // 对应后端错误码
  unknown('UNKNOWN');

  final String value;
  const IdempotencyExceptionCode(this.value);
  factory IdempotencyExceptionCode.fromString(String? codeString) {
    if (codeString == null) return IdempotencyExceptionCode.unknown;
    for (var code in values) {
      if (code.value == codeString) return code;
    }
    return IdempotencyExceptionCode.unknown;
  }
}