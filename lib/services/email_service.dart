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
      ..subject = '验证码 - 宿星茶会'
      ..text = '您的验证码是：$code\n\n验证码有效期为5分钟，请尽快使用。';

    await send(message, smtpServer);
  }
}