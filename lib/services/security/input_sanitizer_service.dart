// lib/services/security/input_sanitizer_service.dart

class InputSanitizerService {
  static final InputSanitizerService _instance = InputSanitizerService._internal();
  factory InputSanitizerService() => _instance;
  InputSanitizerService._internal();

  static const _maxInputLength = 10000; // 设置最大输入长度限制

  // 基本的输入验证和清理
  String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // 检查输入长度
    if (input.length > _maxInputLength) {
      throw Exception('输入内容超过长度限制');
    }

    // 移除所有 MongoDB 操作符
    String sanitized = _removeMongoOperators(input);

    // 转义特殊字符
    sanitized = _escapeSpecialCharacters(sanitized);

    // 移除任何潜在的 JavaScript 代码
    sanitized = _removeJavaScriptCode(sanitized);

    return sanitized.trim();
  }

  // 针对标题的特殊处理（更严格的限制）
  String sanitizeTitle(String title) {
    if (title.isEmpty) return title;

    // 标题长度限制
    if (title.length > 100) {
      throw Exception('标题长度不能超过100个字符');
    }

    String sanitized = sanitizeInput(title);

    // 移除所有 HTML 标签
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    return sanitized;
  }

  // 移除 MongoDB 操作符
  String _removeMongoOperators(String input) {
    final operators = [
      '\$eq', '\$gt', '\$gte', '\$in', '\$lt', '\$lte', '\$ne', '\$nin',
      '\$and', '\$not', '\$nor', '\$or', '\$exists', '\$type', '\$expr',
      '\$jsonSchema', '\$mod', '\$regex', '\$text', '\$where', '\$all',
      '\$elemMatch', '\$size', '\$bitsAllClear', '\$bitsAllSet',
      '\$bitsAnyClear', '\$bitsAnySet', '\$slice'
    ];

    String result = input;
    for (var operator in operators) {
      result = result.replaceAll(operator, '');
    }
    return result;
  }

  // 转义特殊字符
  String _escapeSpecialCharacters(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  // 移除潜在的 JavaScript 代码
  String _removeJavaScriptCode(String input) {
    // 移除 script 标签及其内容
    String result = input.replaceAll(
        RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
            caseSensitive: false),
        ''
    );

    // 移除 JavaScript 事件处理程序
    final eventHandlers = [
      'onclick', 'onload', 'onunload', 'onabort', 'onblur', 'onchange',
      'ondblclick', 'onerror', 'onfocus', 'onkeydown', 'onkeypress',
      'onkeyup', 'onmousedown', 'onmousemove', 'onmouseout', 'onmouseover',
      'onmouseup', 'onreset', 'onresize', 'onselect', 'onsubmit'
    ];

    for (var handler in eventHandlers) {
      result = result.replaceAll(
          RegExp('$handler\\s*=\\s*["\'][^"\']*["\']', caseSensitive: false),
          ''
      );
    }

    // 移除 javascript: 协议
    result = result.replaceAll(
        RegExp(r'javascript:', caseSensitive: false),
        ''
    );

    return result;
  }

  // 验证并清理评论内容
  String sanitizeComment(String comment) {
    if (comment.isEmpty) return comment;

    // 评论长度限制
    if (comment.length > 1000) {
      throw Exception('评论长度不能超过1000个字符');
    }

    return sanitizeInput(comment);
  }

  // 验证并清理帖子内容
  String sanitizePostContent(String content) {
    if (content.isEmpty) return content;

    // 帖子内容长度限制
    if (content.length > 5000) {
      throw Exception('帖子内容长度不能超过5000个字符');
    }

    return sanitizeInput(content);
  }

  // 验证并清理标签
  List<String> sanitizeTags(List<String> tags) {
    return tags.map((tag) {
      if (tag.length > 20) {
        throw Exception('标签长度不能超过20个字符');
      }
      return sanitizeInput(tag);
    }).toList();
  }
}