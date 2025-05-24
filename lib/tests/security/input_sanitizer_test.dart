// // lib/tests/security/input_sanitizer_test.dart
//
// import 'package:test/test.dart';
// import '../../services/main/security/input_sanitizer_service.dart';
//
// void main() {
//   late InputSanitizerService sanitizer;
//
//   setUp(() {
//     sanitizer = InputSanitizerService();
//   });
//
//   group('标题注入测试', () {
//     test('MongoDB 注入测试', () {
//       final maliciousInputs = [
//         // MongoDB 操作符注入
//         'Title \$where: function() { while(1) { return false; }}',
//         'Title{\$gt:""}',
//         'Title{\$ne:null}',
//
//         // JavaScript 代码注入
//         '<script>alert("XSS")</script>标题',
//         'javascript:alert("注入")标题',
//
//         // HTML 注入
//         '<img src="x" onerror="alert(\'XSS\')">标题',
//
//         // 事件处理程序注入
//         '<div onclick="alert(\'click\')">标题</div>',
//
//         // 超长标题
//         'a' * 150,  // 超过100字符的标题
//       ];
//
//       for (var input in maliciousInputs) {
//         try {
//           final sanitized = sanitizer.sanitizeTitle(input);
//           expect(sanitized, isNot(contains('\$')));
//           expect(sanitized, isNot(contains('<script>')));
//           expect(sanitized, isNot(contains('javascript:')));
//           expect(sanitized.length, lessThanOrEqualTo(100));
//         } catch (e) {
//           // 某些情况下应该抛出异常（比如标题过长）
//           expect(e, isA<Exception>());
//         }
//       }
//     });
//   });
//
//   group('评论注入测试', () {
//     test('XSS注入测试', () {
//       final maliciousComments = [
//         // 基础 XSS
//         '<script>alert("攻击")</script>评论',
//
//         // 图片 XSS
//         '<img src="x" onerror="alert(\'XSS\')">',
//
//         // 内联事件
//         '<div onmouseover="alert(\'移动\')">测试</div>',
//
//         // MongoDB 查询注入
//         '{\$where: "sleep(5000)"}',
//
//         // HTML 编码绕过
//         '&#60;script&#62;alert("编码")&#60;/script&#62;',
//
//         // 长度测试
//         '很长的评论' * 200,  // 超过1000字符
//       ];
//
//       for (var comment in maliciousComments) {
//         try {
//           final sanitized = sanitizer.sanitizeComment(comment);
//           expect(sanitized, isNot(contains('<script>')));
//           expect(sanitized, isNot(contains('\$where')));
//           expect(sanitized.length, lessThanOrEqualTo(1000));
//         } catch (e) {
//           expect(e, isA<Exception>());
//         }
//       }
//     });
//   });
//
//   group('帖子内容注入测试', () {
//     test('复杂注入测试', () {
//       final maliciousContents = [
//         // 混合注入
//         '''
//         <script>
//           \$where: function() {
//             while(1) {
//               db.collection.find({})
//             }
//           }
//         </script>
//         ''',
//
//         // 链接注入
//         '<a href="javascript:alert(\'点击\')">链接</a>',
//
//         // 样式注入
//         '<div style="position:absolute;top:0;left:0;width:100%;height:100%;background:red;">覆盖</div>',
//
//         // iframe 注入
//         '<iframe src="javascript:alert(\'iframe\')" />',
//
//         // base64 编码注入
//         'data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==',
//
//         // 评论符号
//         '-- MySQL注释',
//         '/* 多行注释测试 */',
//
//         // 超长内容
//         '很长的内容' * 1000,  // 超过5000字符
//       ];
//
//       for (var content in maliciousContents) {
//         try {
//           final sanitized = sanitizer.sanitizePostContent(content);
//           expect(sanitized, isNot(contains('<script>')));
//           expect(sanitized, isNot(contains('javascript:')));
//           expect(sanitized, isNot(contains('\$where')));
//           expect(sanitized.length, lessThanOrEqualTo(5000));
//         } catch (e) {
//           expect(e, isA<Exception>());
//         }
//       }
//     });
//   });
//
//   group('标签注入测试', () {
//     test('标签注入测试', () {
//       final maliciousTags = [
//         // MongoDB 注入
//         '{\$ne: 1}',
//
//         // 长标签
//         '非常长的标签名称超过了20个字符的限制',
//
//         // 特殊字符
//         '<script>tag</script>',
//         'javascript:alert("tag")',
//
//         // HTML 标签
//         '<img src=x onerror=alert("tag")>',
//       ];
//
//       try {
//         final sanitized = sanitizer.sanitizeTags(maliciousTags);
//         for (var tag in sanitized) {
//           expect(tag, isNot(contains('\$')));
//           expect(tag, isNot(contains('<')));
//           expect(tag, isNot(contains('javascript:')));
//           expect(tag.length, lessThanOrEqualTo(20));
//         }
//       } catch (e) {
//         expect(e, isA<Exception>());
//       }
//     });
//   });
// }
//
// // 手动测试样例
// void manualTestExamples() {
//   final sanitizer = InputSanitizerService();
//
//   // 1. 测试标题注入
//   print('=== 测试标题注入 ===');
//   final maliciousTitle = '<script>alert("XSS")</script>Hello{\$ne:1}';
//   try {
//     final cleanTitle = sanitizer.sanitizeTitle(maliciousTitle);
//     print('原始标题: $maliciousTitle');
//     print('清理后: $cleanTitle');
//   } catch (e) {
//     print('标题验证失败: $e');
//   }
//
//   // 2. 测试评论注入
//   print('\n=== 测试评论注入 ===');
//   final maliciousComment = '{\$where: function() { while(1) { return false; }}}';
//   try {
//     final cleanComment = sanitizer.sanitizeComment(maliciousComment);
//     print('原始评论: $maliciousComment');
//     print('清理后: $cleanComment');
//   } catch (e) {
//     print('评论验证失败: $e');
//   }
//
//   // 3. 测试帖子内容注入
//   print('\n=== 测试帖子内容注入 ===');
//   final maliciousPost = '''
//     <div onclick="alert('click')">
//       {\$where: "sleep(5000)"}
//       <script>alert("XSS")</script>
//     </div>
//   ''';
//   try {
//     final cleanPost = sanitizer.sanitizePostContent(maliciousPost);
//     // print('原始帖子: $maliciousPost');
//     // print('清理后: $cleanPost');
//   } catch (e) {
//     // print('帖子验证失败: $e');
//   }
//
//   // 4. 测试标签注入
//   print('\n=== 测试标签注入 ===');
//   final maliciousTags = [
//     '<script>tag</script>',
//     '{\$ne: null}',
//     '超长标签名称超过二十个字符'
//   ];
//   try {
//     final cleanTags = sanitizer.sanitizeTags(maliciousTags);
//     print('原始标签: $maliciousTags');
//     print('清理后: $cleanTags');
//   } catch (e) {
//     print('标签验证失败: $e');
//   }
// }