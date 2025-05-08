// lib/utils/error/app_error_formatter.dart (修改这个文件)

// 如果你需要检查 TimeoutException 类型
// 如果你需要检查 SocketException 等类型
// import 'package:hive/hive.dart'; // 如果你需要检查 HiveError 类型
// import '../security/security_error.dart'; // 如果你需要检查 SecurityError 类型

// *** 干净地导入外部定义文件 ***

import 'package:suxingchahui/utils/error/app_error_codes.dart';

import 'app_error_definition.dart';

class AppErrorFormatter {

  /// **方法一: 格式化错误 (公共接口和返回值不变！)**
  /// Formats error messages to be user-friendly and secure, NOW INCLUDES ERROR CODE.
  static String formatErrorMessage(dynamic error) {
    // 内部调用识别逻辑，找到对应的 ErrorDefinition
    final definition = _identifyErrorDefinition(error);
    // 在日志中打印详细信息（包括是否可重试，方便调试）
    print("[ErrorFormatter] Identified Error - Code: ${definition.code}, Retryable: ${definition.isRetryable}, Original Error Type: ${error.runtimeType}");
    // 返回带代码的格式化字符串给调用者 (如 AppInitializer)
    return definition.formatForUser();
  }

  /// **方法二: 根据错误代码字符串判断是否可重试 (新增的公共辅助方法)**
  /// InitializationWrapper 将调用这个方法。
  static bool isErrorCodeRetryable(String errorCode) {
    // 通过 AppErrorCodes 公开的方法查找对应的错误定义
    final definition = AppErrorCodes.getDefinitionByCode(errorCode);
    // 如果找到了定义，返回其 isRetryable 标志
    // 如果没找到 (理论上不应该，除非代码拼写错误)，默认允许重试，给用户一个机会
    final bool isRetryable = definition?.isRetryable ?? true;
    print("[ErrorFormatter] Checked Retryable Status - Code: '$errorCode', Result: $isRetryable");
    return isRetryable;
  }

  // --- 内部核心识别逻辑 ---
  // 这个私有方法负责根据输入的错误，匹配并返回相应的 ErrorDefinition
  // 它现在直接使用 AppErrorCodes 中定义的常量
  static AppErrorDefinition _identifyErrorDefinition(dynamic error) {
    // 优先使用原始的基于错误消息字符串的判断逻辑
    String message = error.toString();
    print("↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ original messgae ↓↓↓↓↓↓↓↓↓↓");
    print(message);

    // **完全按照你原来的逻辑顺序进行判断，但返回的是 ErrorDefinition 常量**
    // Root environment detection
    if (message.contains('Root环境')) {
      return AppErrorCodes.rootDetected;
    }
    // Emulator detection
    if (message.contains('模拟器')) {
      return AppErrorCodes.emulatorDetected;
    }
    // Debug mode detection
    if (message.contains('调试模式')) {
      return AppErrorCodes.debugModeDetected;
    }
    // Multiple instance detection
    if (message.contains('多实例')) {
      return AppErrorCodes.multipleInstances;
    }
    // Unsafe environment detection
    if (message.contains('不安全的运行环境')) {
      return AppErrorCodes.unsafeEnvironment;
    }
    // Hive error
    if (message.contains('HiveError')) {
      // 注意：原消息被替换了，这里我们用 HVE-001 的模板
      return AppErrorCodes.hiveError;
    }
    // SecurityError string check
    if (message.contains('SecurityError')) {
      // 注意：原消息被替换了，这里我们用 SEC-100 的模板
      return AppErrorCodes.genericSecurityError;
    }
    // MongoDB connection errors / SocketException
    if (message.contains('MongoDB ConnectionException') || message.contains('SocketException')) {
      // 注意：原消息被替换了，这里我们用 NET-001 的模板
      return AppErrorCodes.networkConnectionFailed;
    }
    // Timeout errors
    if (message.contains('TimeoutException')) {
      // 注意：原消息被替换了，这里我们用 NET-002 的模板
      return AppErrorCodes.networkTimeout;
    }

    // Handle complex exception messages (只处理隐藏敏感信息部分)
    // **重要**: 这里的判断必须在上面所有具体判断之后
    // 如果检测到敏感信息，返回特定的错误定义 (CONF-002)
    if (message.contains('mongodb://') ||
        message.contains('localhost') ||
        message.contains('error code') || // 这个可能过于宽泛，谨慎使用
        message.contains('http://') || // 这个也可能过于宽泛
        message.contains('errno =')) {
      print("[ErrorFormatter] Detected potentially sensitive info in error message. Returning safe default.");
      return AppErrorCodes.sensitiveConfigLeakPrevented; // 使用隐藏信息时的定义
    }

    // 原来的 Exception: 提取逻辑可以去掉，因为我们不再返回提取后的 message
    // 而是直接返回上面匹配到的 ErrorDefinition 的 formatForUser() 结果。
    // 如果上面的 if 条件都未命中，说明是未知的错误类型。

    // 如果所有已知模式都未匹配，返回默认的通用初始化失败错误
    print("[ErrorFormatter] Error did not match any specific pattern. Using default 'genericInitializationFailed'. Original message: $message");
    return AppErrorCodes.genericInitializationFailed;
  }
}