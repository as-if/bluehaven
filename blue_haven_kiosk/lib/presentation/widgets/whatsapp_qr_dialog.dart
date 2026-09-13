import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/config/kiosk_config.dart';

class WhatsAppQRDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String customMessage;

  const WhatsAppQRDialog({
    super.key,
    this.title = 'Scan to Chat on WhatsApp',
    this.subtitle = 'Connect directly with our remote reception team on your phone.',
    this.customMessage = KioskConfig.whatsappMessage,
  });

  static void show(BuildContext context, {String? title, String? subtitle, String? customMessage}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => WhatsAppQRDialog(
        title: title ?? 'Scan to Chat on WhatsApp',
        subtitle: subtitle ?? 'Connect directly with our remote reception team on your phone.',
        customMessage: customMessage ?? KioskConfig.whatsappMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = 'https://wa.me/${KioskConfig.whatsappNumber}?text=${Uri.encodeComponent(customMessage)}';

    return Dialog(
      backgroundColor: const Color(0xFF0C1D36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble, color: Color(0xFF25D366), size: 32),
                    SizedBox(width: 12),
                    Text(
                      'WhatsApp Desk',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'WhatsApp: +960 ${KioskConfig.whatsappNumber.substring(3)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF00F0FF)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
