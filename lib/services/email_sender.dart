import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailSender {
  static const String _username = 'amitbajracharya4444@gmail.com';
  static const String _appPassword = 'csqc nmly pdqs mdko';

  static Future<void> sendResetCode({
    required String toEmail,
    required String code,
  }) async {
    final smtpServer = gmail(_username, _appPassword);

    final message = Message()
      ..from = Address(_username, 'AssembleX Support')
      ..recipients.add(toEmail)
      ..subject = 'Your AssembleX password reset code'
      ..text = 'Your password reset code is: ' + code;

    await send(message, smtpServer);
  }
}
