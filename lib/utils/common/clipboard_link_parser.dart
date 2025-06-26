// lib/utils/common/clipboard_link_parser.dart

/// 该文件定义了 [ClipboardLinkParser] 工具类。
///
/// 该工具类提供从系统剪贴板解析特定格式文本并创建 [GameDownloadLink] 对象的功能。
library;

import 'package:flutter/services.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:suxingchahui/models/game/game.dart';

/// [ClipboardLinkParser] 类：一个用于从剪贴板解析下载链接的工具类。
class ClipboardLinkParser {
  /// 尝试从剪贴板解析文本并返回一个 [GameDownloadLink] 对象。
  ///
  /// 如果解析成功，返回一个元组 `(link, null)`。
  /// 如果剪贴板为空或格式不匹配，返回一个元组 `(null, '错误信息')`。
  ///
  /// [currentUserId]: 执行此操作的当前用户ID。
  static Future<(GameDownloadLink?, String?)> parseFromClipboard(
      {required String currentUserId}) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final String? clipboardText = clipboardData?.text;

    if (clipboardText == null || clipboardText.isEmpty) {
      return (null, '剪贴板内容为空');
    }

    final lines = clipboardText.split('\n');
    String? title;
    String? url;
    String? description;

    for (final line in lines) {
      if (line.contains('链接：')) {
        url = line.replaceAll('链接：', '').trim();
      } else if (line.contains('提取码：')) {
        description =
            '${description ?? ''}${description != null && description.isNotEmpty ? '; ' : ''}提取码：${line.replaceAll('提取码：', '').trim()}';
      } else if (title == null &&
          line.isNotEmpty &&
          !line.contains('http') &&
          !line.contains('https')) {
        title = line.trim();
      }
    }

    if (title != null && url != null) {
      final newLink = GameDownloadLink(
        id: mongo.ObjectId().oid,
        userId: currentUserId,
        title: title,
        url: url,
        description: description ?? '',
      );
      return (newLink, null);
    } else {
      return (null, '未能从剪贴板解析有效链接');
    }
  }
}
