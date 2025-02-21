import 'dart:math';
import 'dart:async';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../../config/app_config.dart';
import '../user/user_service.dart';

class EmailService {
  static final UserService _userService = UserService();

  // 生成验证码的逻辑保持不变
  static String generateVerificationCode() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    print('key generated:$code');
    return code;
  }

  // 注册时使用的发送验证码方法
  static Future<void> sendRegistrationCode(String toEmail, String code) async {
    try {
      print('Verifying email for registration...');

      // 首先验证邮箱是否已存在
      final existingUser = await _userService.checkEmailExists(toEmail);
      if (existingUser) {
        throw Exception('该邮箱已被注册');
      }

      // 邮箱不存在，发送验证码
      print('Email available, sending verification code...');
      return await Future.any([
        _sendEmail(toEmail, code, isRegistration: true),
        Future.delayed(Duration(seconds: 10))
            .then((_) => throw TimeoutException('发送超时，请检查网络后重试')),
      ]);
    } catch (e, stackTrace) {
      print('Detailed error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // 找回密码时使用的发送验证码方法（保持原有逻辑）
  static Future<void> sendPasswordResetCode(String toEmail, String code) async {
    try {
      print('Verifying email for password reset...');

      // 首先验证邮箱是否存在
      final existingUser = await _userService.checkEmailExists(toEmail);
      if (!existingUser) {
        throw Exception('该邮箱未注册');
      }

      // 邮箱存在，发送验证码
      print('Email verified, sending reset code...');
      return await Future.any([
        _sendEmail(toEmail, code, isRegistration: false),
        Future.delayed(Duration(seconds: 10))
            .then((_) => throw TimeoutException('发送超时，请检查网络后重试')),
      ]);
    } catch (e, stackTrace) {
      print('Detailed error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // 统一的邮件发送方法，根据场景调整邮件内容
  static Future<void> _sendEmail(String toEmail, String code, {required bool isRegistration}) async {
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
      ..subject = '【宿星茶会】验证码'
      ..html = _buildVerificationEmailBody(code, isRegistration);

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }

  // 根据不同场景构建不同的邮件内容
  static String _buildVerificationEmailBody(String code, bool isRegistration) {
    final actionText = isRegistration ? '注册' : '重置密码';
    final purposeText = isRegistration ? '创建您的账号' : '重置您的密码';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>宿星茶会 - ${actionText}验证码</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          line-height: 1.6;
          color: #333;
          background-image: url('https://www.suxing.site/assets/bg-DX8HvztV.jpg');
          background-size: cover;
          background-position: center;
          background-repeat: no-repeat;
          background-attachment: fixed;
          overflow: hidden;
        }
        .container {
          max-width: 600px;
          margin: 0 auto;
          padding: 20px;
          border: 1px solid #ddd;
          background: white;
          opacity: 0.8;
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
        <p>您正在${purposeText}，验证码是：</p>
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