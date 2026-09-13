import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/island_time_helper.dart';
import '../providers/kiosk_session_provider.dart';
import 'emergency_contact_modal.dart';
import 'whatsapp_qr_dialog.dart';

class KioskAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBack;

  const KioskAppBar({
    super.key,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80.0);

  @override
  ConsumerState<KioskAppBar> createState() => _KioskAppBarState();
}

class _KioskAppBarState extends ConsumerState<KioskAppBar> {
  late String _timeString;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final formatted = _formatTime(DateTime.now());
    if (mounted && formatted != _timeString) {
      setState(() => _timeString = formatted);
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(kioskSessionNotifierProvider);
    final currentLang = session?.language ?? 'en';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF071322).withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (widget.showBackButton) ...[
              InkWell(
                onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text('Back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
            // Greeting & Property Header
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    IslandTimeHelper.getTimeAwareGreeting(),
                    style: const TextStyle(fontSize: 16, color: Color(0xFF00F0FF), fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    'Blue Haven • Thulusdhoo',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Live Clock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF00F0FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _timeString,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Language Selector Dropdown
            PopupMenuButton<String>(
              initialValue: currentLang,
              onSelected: (lang) => ref.read(kioskSessionNotifierProvider.notifier).setLanguage(lang),
              color: const Color(0xFF0E2238),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.white70, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      currentLang.toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'en', child: Text('🇬🇧 English (EN)', style: TextStyle(color: Colors.white, fontSize: 18))),
                PopupMenuItem(value: 'it', child: Text('🇮🇹 Italiano (IT)', style: TextStyle(color: Colors.white, fontSize: 18))),
                PopupMenuItem(value: 'ru', child: Text('🇷🇺 Русский (RU)', style: TextStyle(color: Colors.white, fontSize: 18))),
                PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français (FR)', style: TextStyle(color: Colors.white, fontSize: 18))),
                PopupMenuItem(value: 'de', child: Text('🇩🇪 Deutsch (DE)', style: TextStyle(color: Colors.white, fontSize: 18))),
              ],
            ),
            const SizedBox(width: 14),

            // WhatsApp QR Modal Button
            InkWell(
              onTap: () => WhatsAppQRDialog.show(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF25D366), width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Color(0xFF25D366), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'WhatsApp',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF25D366)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Emergency Contacts Button
            InkWell(
              onTap: () => EmergencyContactModal.show(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF476F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF476F), width: 1.5),
                ),
                child: const Icon(Icons.sos, color: Color(0xFFEF476F), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
