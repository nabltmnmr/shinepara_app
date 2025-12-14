import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';

class WhatsAppButton extends StatelessWidget {
  final String phoneNumber;
  final String? message;

  const WhatsAppButton({
    super.key,
    this.phoneNumber = '9647744445057',
    this.message,
  });

  Future<void> _launchWhatsApp() async {
    final encodedMessage = message != null ? Uri.encodeComponent(message!) : '';
    final url = Uri.parse('https://wa.me/$phoneNumber${encodedMessage.isNotEmpty ? "?text=$encodedMessage" : ""}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'whatsapp',
      onPressed: _launchWhatsApp,
      backgroundColor: AppColors.whatsappGreen,
      child: Icon(
        Icons.chat,
        color: AppColors.white,
        size: 28,
      ),
    );
  }
}
