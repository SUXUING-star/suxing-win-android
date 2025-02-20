// lib/utils/config_decrypt.dart
import 'dart:convert';
import 'package:fernet/fernet.dart';
import './remote_key_manager.dart';
import '../../config/encrypted_config.dart';

class ConfigDecrypt {
  static Map<String, dynamic>? _decryptedConfig;
  static late final Fernet _fernet;

  static Future<void> initialize() async {
    if (_decryptedConfig != null) return;

    try {
      // 从远程获取密钥
      final key = await RemoteKeyManager.getKey();

      // 初始化 Fernet
      final encodedKey = base64Url.encode(utf8.encode(key));
      _fernet = Fernet(encodedKey);

      // 解密配置
      _decryptedConfig = await _decryptConfig(EncryptedConfig.values);
    } catch (e) {
      print('配置初始化失败: $e');
      rethrow;
    }
  }

  // 其余方法保持不变
  static Future<Map<String, dynamic>> _decryptConfig(Map<String, dynamic> encrypted) async {
    final decrypted = <String, dynamic>{};

    for (final entry in encrypted.entries) {
      if (entry.value is Map) {
        decrypted[entry.key] = await _decryptConfig(Map<String, dynamic>.from(entry.value));
      } else if (entry.value is String) {
        try {
          final decryptedValue = await _fernet.decrypt(entry.value);
          decrypted[entry.key] = utf8.decode(decryptedValue);
        } catch (e) {
          print('解密失败 ${entry.key}: $e');
          decrypted[entry.key] = entry.value;
        }
      } else {
        decrypted[entry.key] = entry.value;
      }
    }

    return decrypted;
  }

  static T? getValue<T>(String path) {
    if (_decryptedConfig == null) {
      throw Exception('配置未初始化! 请先调用 initialize()');
    }

    final parts = path.split('.');
    dynamic current = _decryptedConfig;

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current as T?;
  }
}