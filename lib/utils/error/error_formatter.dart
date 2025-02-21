// lib/utils/error/error_formatter.dart

class ErrorFormatter {
  /// Formats error messages to be user-friendly and secure
  static String formatErrorMessage(dynamic error) {
    String message = error.toString();

    // Root environment detection
    if (message.contains('Root环境')) {
      return '检测到设备已Root，为了您的账号安全，请使用未Root的设备';
    }

    // Emulator detection
    if (message.contains('模拟器')) {
      return '不支持在模拟器中运行本应用';
    }

    // Debug mode detection
    if (message.contains('调试模式')) {
      return '请关闭开发者选项中的USB调试功能';
    }

    // Multiple instance detection
    if (message.contains('多实例')) {
      return '应用已在运行中，请勿重复开启';
    }

    // Unsafe environment detection
    if (message.contains('不安全的运行环境')) {
      return '检测到不安全的运行环境，请关闭相关工具后重试';
    }

    // Hive error
    if (message.contains('HiveError')) {
      return '请检查你的环境是否符合要求，请在正常环境下运行。';
    }

    // SecurityError
    if (message.contains('SecurityError')) {
      return '请检查你的环境是否符合要求，请在正常环境下运行。';
    }

    // MongoDB connection errors
    if (message.contains('MongoDB ConnectionException') ||
        message.contains('SocketException')) {
      return '无法连接到服务器，请检查网络连接是否正常。\n\n如果网络正常但仍然无法连接，可能是：\n1. 网络不稳定\n2. 服务器正在维护\n3. 防火墙设置阻止了连接';
    }

    // Timeout errors
    if (message.contains('TimeoutException')) {
      return '连接服务器超时，请检查网络状态后重试。';
    }

    // Handle complex exception messages
    if (message.contains('Exception:')) {
      final colonIndex = message.indexOf(':');
      if (colonIndex != -1 && message.length > colonIndex + 2) {
        message = message.substring(colonIndex + 2).trim();

        // Hide sensitive connection details
        if (message.contains('mongodb://') ||
            message.contains('localhost') ||
            message.contains('error code') ||
            message.contains('errno =')) {
          return '应用初始化失败，请稍后重试。';
        }

        return message;
      }
    }

    // Default error message
    return '应用初始化失败，请稍后重试。';
  }
}