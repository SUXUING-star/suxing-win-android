// lib/utils/error/app_error_codes.dart (新文件，干净独立)

import 'error_definition.dart'; // 导入干净的定义文件

/// 存储所有预定义的错误代码和信息
class AppErrorCodes {
  // --- Security Errors (SEC) --- (不可重试)
  static const rootDetected = ErrorDefinition(
      code: "SEC-001",
      userMessageTemplate: "检测到设备已Root，为了您的账号安全，请使用未Root的设备",
      isRetryable: false);
  static const emulatorDetected = ErrorDefinition(
      code: "SEC-002",
      userMessageTemplate: "不支持在模拟器中运行本应用",
      isRetryable: false);
  static const debugModeDetected = ErrorDefinition(
      code: "SEC-003",
      userMessageTemplate: "请关闭开发者选项中的USB调试功能",
      isRetryable: false);
  static const multipleInstances = ErrorDefinition(
      code: "SEC-004",
      userMessageTemplate: "应用已在运行中，请勿重复开启",
      isRetryable: false);
  static const unsafeEnvironment = ErrorDefinition(
      code: "SEC-005",
      userMessageTemplate: "检测到不安全的运行环境，请关闭相关工具后重试",
      isRetryable: false);
  static const genericSecurityError = ErrorDefinition(
      code: "SEC-100",
      userMessageTemplate: "请检查你的环境是否符合要求，请在正常环境下运行",
      isRetryable: false); // 用于 SecurityError 或包含 "SecurityError" 字符串

  // --- Hive/Storage Errors (HVE) --- (可重试)
  static const hiveError = ErrorDefinition(
      code: "HVE-001",
      userMessageTemplate: "本地数据处理异常，请尝试清理应用缓存或重新安装",
      isRetryable: true); // 包含 "HiveError"

  // --- Network Errors (NET) --- (基本都可重试)
  static const networkConnectionFailed = ErrorDefinition(
      code: "NET-001",
      userMessageTemplate:
          "无法连接到服务器，请检查网络连接是否正常。\n\n如果网络正常但仍然无法连接，可能是：\n1. 网络不稳定\n2. 服务器正在维护\n3. 防火墙设置阻止了连接",
      isRetryable:
          true); // 包含 "SocketException" 或 "MongoDB ConnectionException"
  static const networkTimeout = ErrorDefinition(
      code: "NET-002",
      userMessageTemplate: "连接服务器超时，请检查网络状态后重试",
      isRetryable: true); // 包含 "TimeoutException"

  // --- Configuration Errors (CONF) --- (部分可重试)
  static const sensitiveConfigLeakPrevented = ErrorDefinition(
      code: "CONF-002",
      userMessageTemplate: "应用初始化失败，请稍后重试",
      isRetryable: true); // 隐藏敏感信息时的提示，给个重试机会
  static const genericInitializationFailed = ErrorDefinition(
      code: "INT-001",
      userMessageTemplate: "应用初始化失败，请稍后重试",
      isRetryable: true); // 默认错误

  // --- 错误代码到 ErrorDefinition 的映射 ---
  // 这个 Map 是为了 ErrorFormatter 能方便地通过代码查找定义
  static final Map<String, ErrorDefinition> _definitionsByCode = {
    rootDetected.code: rootDetected,
    emulatorDetected.code: emulatorDetected,
    debugModeDetected.code: debugModeDetected,
    multipleInstances.code: multipleInstances,
    unsafeEnvironment.code: unsafeEnvironment,
    genericSecurityError.code: genericSecurityError,
    hiveError.code: hiveError,
    networkConnectionFailed.code: networkConnectionFailed,
    networkTimeout.code: networkTimeout,
    sensitiveConfigLeakPrevented.code: sensitiveConfigLeakPrevented,
    genericInitializationFailed.code: genericInitializationFailed,
    // *** 如果你添加了新的错误定义，记得也加到这个 Map 里！ ***
  };

  /// **公开的辅助方法：根据代码获取 ErrorDefinition**
  /// ErrorFormatter 将使用这个方法来查询 isRetryable 状态
  static ErrorDefinition? getDefinitionByCode(String code) {
    return _definitionsByCode[code];
  }

  // 私有构造，防止实例化此类
  AppErrorCodes._();
}
