// lib/utils/remote_key_manager.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart' as crypto;
import '../../config/app_config.dart';

class RemoteKeyManager {
  static const String _keyServiceUrl = AppConfig.keyServiceUrl;
  static String? _cachedKey;

  // 补充0到指定长度
  static String _padLeft(String text, int length) {
    if (text.length >= length) return text;
    return '0' * (length - text.length) + text;
  }

  // 基于日期生成解密密钥
  static String _generateDailyKey() {
    final now = DateTime.now();
    final baseKey = '${now.year}'
        '${_padLeft(now.month.toString(), 2)}'
        '${_padLeft(now.day.toString(), 2)}';

    final bytes = utf8.encode(baseKey);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  // 从十六进制字符串转换为字节数组
  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      final num = int.parse(hex.substring(i, i + 2), radix: 16);
      result[i ~/ 2] = num;
    }
    return result;
  }

  // AES解密
  static String _decryptAES(String encryptedHex, String ivHex, String dailyKey) {
    final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key(Uint8List.fromList(utf8.encode(dailyKey))),
          mode: encrypt.AESMode.cbc,
        )
    );

    final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(_hexToBytes(encryptedHex)),
        iv: encrypt.IV(_hexToBytes(ivHex))
    );

    return utf8.decode(decrypted);
  }

  // 获取密钥段
  static Future<Map<String, String>> _fetchKeySegment(String part) async {
    final response = await http.get(Uri.parse('$_keyServiceUrl/segment/$part'));

    if (response.statusCode != 200) {
      throw Exception('获取密钥段失败: $part');
    }

    final data = jsonDecode(response.body);
    if (!data['success']) {
      throw Exception(data['error'] ?? '未知错误');
    }

    return {
      'data': data['data'],
      'iv': data['iv']
    };
  }

  // 获取完整的密钥
  static Future<String> getKey() async {
    // 如果已经有缓存的密钥，直接返回
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    try {
      // 获取两个密钥段
      final part1 = await _fetchKeySegment('part1');
      final part2 = await _fetchKeySegment('part2');

      // 生成解密密钥
      final dailyKey = _generateDailyKey();

      // 解密两段
      final decryptedPart1 = _decryptAES(part1['data']!, part1['iv']!, dailyKey);
      final decryptedPart2 = _decryptAES(part2['data']!, part2['iv']!, dailyKey);

      // 组合完整密钥
      _cachedKey = decryptedPart1 + decryptedPart2;
      return _cachedKey!;

    } catch (e) {
      print('获取远程密钥失败: $e');
      rethrow;
    }
  }
}