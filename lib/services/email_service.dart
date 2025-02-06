import 'dart:math';
import 'dart:async';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/app_config.dart';

class EmailService {
  static String generateVerificationCode() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    print('key generated:$code');
    return code;
  }

  static Future<void> sendVerificationCode(String toEmail, String code) async {
    try {
      print('Starting to send email...');
      return await Future.any([
        _sendEmail(toEmail, code),
        Future.delayed(Duration(seconds: 10)).then((_) =>
        throw TimeoutException('发送超时，请检查网络后重试')),
      ]);
    } catch (e, stackTrace) {
      print('Detailed error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _sendEmail(String toEmail, String code) async {
    final smtpServer = SmtpServer(
      AppConfig.emailSmtpHost,
      username: AppConfig.emailFrom,
      password: AppConfig.emailAuthCode,
      port: int.parse(AppConfig.emailSmtpPort),
      ssl: false,
      ignoreBadCertificate: true,
    );

    final message = Message()
      ..from = Address(AppConfig.emailFrom, '宿星茶会')
      ..recipients.add(toEmail)
      ..subject = '【宿星茶会】验证码'  // 更清晰的主题
      ..html = _buildVerificationEmailBody(code); // 使用HTML模板

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}'); // 打印发送报告
    } catch (e) {
      print('Error sending email: $e');
      rethrow; // 重新抛出异常，让上层处理
    }
  }

  // 构建HTML邮件内容
  static String _buildVerificationEmailBody(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>宿星茶会 - 验证码</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          border: 1px solid #ddd;
        }
        .header {
          text-align: center;
          margin-bottom: 20px;
        }
        .code {
          font-size: 24px;
          font-weight: bold;
          color: #007bff;
        }
        .footer {
          margin-top: 20px;
          text-align: center;
          font-size: 12px;
          color: #777;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>宿星茶会</h1>
          <p>感谢您使用宿星茶会！</p>
        </div>
        <p>您的验证码是：</p>
        <p class="code">$code</p>
        <p>此验证码将在 5 分钟内有效，请尽快使用。</p>
        <p>如果您没有进行此操作，请忽略此邮件。</p>
        <div class="footer">
          <p>此邮件由系统自动发送，请勿回复。</p>
          <p>© 2024 宿星茶会</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}