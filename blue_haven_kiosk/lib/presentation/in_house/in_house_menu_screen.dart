import 'package:flutter/material.dart';
import '../chat/tiered_chat_screen.dart';
import '../widgets/kiosk_app_bar.dart';
import '../widgets/whatsapp_qr_dialog.dart';
import 'island_guide_screen.dart';
import 'lockout_recovery_screen.dart';
import 'service_requests_screen.dart';

class InHouseMenuScreen extends StatelessWidget {
  const InHouseMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Scaffold(
      appBar: const KioskAppBar(showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 40.0 : 20.0,
            vertical: isLandscape ? 20.0 : 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // High Prominence WhatsApp Primary Action Banner
              InkWell(
                onTap: () => WhatsAppQRDialog.show(
                  context,
                  title: 'WhatsApp Concierge Desk',
                  subtitle: 'Move conversation straight to WhatsApp on your phone for immediate host assistance.',
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF25D366), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 36),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📱 Chat with Front Desk on WhatsApp (Recommended)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Scan QR to continue all requests, room chat & advice directly on your phone',
                              style: TextStyle(fontSize: 15, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Grid of In-House Actions
              Expanded(
                child: GridView.count(
                  crossAxisCount: isLandscape ? 3 : 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: isLandscape ? 1.4 : 1.1,
                  children: [
                    _buildMenuCard(
                      context: context,
                      title: 'Service Requests',
                      subtitle: 'Towels, drinking water, housekeeping, maintenance',
                      icon: Icons.cleaning_services,
                      color: const Color(0xFF00F0FF),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ServiceRequestsScreen()),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Locked Out?',
                      subtitle: '2FA verification code to your phone for temporary PIN',
                      icon: Icons.lock_open,
                      color: const Color(0xFFEF476F),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LockoutRecoveryScreen()),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Ferry, Tide & Surf',
                      subtitle: 'Timetables, speedboat departures, wave forecasts',
                      icon: Icons.waves,
                      color: const Color(0xFFFFB703),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const IslandGuideScreen(initialTab: 0)),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Island Guide',
                      subtitle: 'Cafés, shops, mosque prayer times, ATM, beach rules',
                      icon: Icons.map,
                      color: const Color(0xFF06D6A0),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const IslandGuideScreen(initialTab: 1)),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Ask AI Concierge',
                      subtitle: 'Offline answers: Wi-Fi, breakfast times, power plugs',
                      icon: Icons.auto_awesome,
                      color: const Color(0xFF9D4EDD),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TieredChatScreen()),
                        );
                      },
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Video Call Host',
                      subtitle: 'Direct two-way video link to on-duty manager',
                      icon: Icons.video_call,
                      color: const Color(0xFF0077B6),
                      onTap: () {
                        WhatsAppQRDialog.show(
                          context,
                          title: 'Connecting to Host',
                          subtitle: 'Scan to message the manager immediately or use the video call screen.',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E2238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
