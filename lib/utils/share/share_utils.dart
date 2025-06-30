// lib/utils/share/share_utils.dart

/// 定义了 ShareUtils，一个用于生成和解析应用内分享口令的通用工具类。
library;

import 'dart:convert';
import 'dart:math';
import 'package:suxingchahui/constants/global_constants.dart';

/// 分享类型枚举，用于区分不同业务的分享。
class ShareUtils {
  static const String game = 'game';
  static const String post = 'post';

  final String type;
  const ShareUtils({
    required this.type,
  });

  static const shareGame = ShareUtils(type: game);
  static const sharePost = ShareUtils(type: post);

  // --- 私有核心逻辑 (这部分不变) ---
  static const String _salt = 'sxc_rocks_';
  static const String _delimiter = '€';
  static const List<String> _prefixPool = [
    '(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧',
    'ฅ(●´ω｀●)ฅ',
    '✨🚀✨',
    '(*ゝω・)ﾉ',
    'biu~biu~biu~',
    '芜湖，起飞！'
  ];
  static const List<String> _suffixPool = [
    '✧ﾟ･:*',
    'ฅ(●´ω｀●)ฅ',
    '✨🛸✨',
    'ヾ(・ω<*)',
    '啾咪~',
    '拿来吧你！'
  ];
  static const Map<ShareUtils, List<String>> _sloganPool = {
    shareGame: [
      '我发现了个神作「%s」，快来van！',
      '墙裂推荐这个游戏「%s」，不好玩你砍我！',
      '大的要来了！这个「%s」绝对是宝藏！'
    ],
    sharePost: [
      '看到个有意思的帖子「%s」，你也来看看！',
      '这个帖子「%s」的讨论太顶了，速来！',
      '关于「%s」的帖子，有点东西，分享给你。'
    ],
  };

  static String _encode({required String id, required ShareUtils type}) {
    final payload = '$_salt${type.type}|$id';
    final bytes = utf8.encode(payload);
    return base64Url.encode(bytes);
  }

  static ({ShareUtils type, String id})? _decode(String encodedStr) {
    try {
      final bytes = base64Url.decode(encodedStr);
      final payload = utf8.decode(bytes);
      if (!payload.startsWith(_salt)) return null;
      final cleanPayload = payload.substring(_salt.length);
      final parts = cleanPayload.split('|');
      if (parts.length != 2) return null;
      final typeName = parts[0];
      final id = parts[1];
      final type = ShareUtils(type: typeName);
      return (type: type, id: id);
    } catch (e) {
      return null;
    }
  }

  // --- 公共 API ---

  /// 生成带有火星文视觉混淆、随机文案和【清晰用户引导】的分享消息。
  static String generateShareMessage({
    required String id,
    required String title,
    required ShareUtils shareType,
  }) {
    // 1. 核心数据编码
    final encodedPayload = _encode(id: id, type: shareType);

    // 2. 随机元素选择
    final random = Random();
    final prefix = _prefixPool[random.nextInt(_prefixPool.length)];
    final suffix = _suffixPool[random.nextInt(_suffixPool.length)];
    final slogans = _sloganPool[shareType] ?? ['发现一个有趣的内容「%s」'];
    final randomSlogan = slogans[random.nextInt(slogans.length)];
    final formattedSlogan = randomSlogan.replaceAll('%s', title);

    // 3. 组装火星文密令部分
    final fireCode = '$prefix$_delimiter$encodedPayload$_delimiter$suffix';

    // 4. 【灵魂回来了！】定义清晰的用户引导语
    const String userGuide = '👉复制整段消息，打开【${GlobalConstants.appName}】即可直达👈';

    // 5. 组装成最终的、结构清晰的完整消息
    final message = '$formattedSlogan\n\n$fireCode\n\n$userGuide';

    return message;
  }

  // 解析方法 (不变)
  static ({ShareUtils type, String id})? parseShareMessage(String message) {
    final regExp = RegExp('$_delimiter(.*?)$_delimiter');
    final match = regExp.firstMatch(message);
    if (match != null && match.groupCount >= 1) {
      final encodedPayload = match.group(1);
      if (encodedPayload != null) {
        return _decode(encodedPayload);
      }
    }
    return null;
  }
}
