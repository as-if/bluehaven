import 'package:flutter/material.dart';
import '../../core/config/kiosk_config.dart';

class EmergencyContactModal extends StatelessWidget {
  const EmergencyContactModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF071322),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const EmergencyContactModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emergency, color: Color(0xFFEF476F), size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Emergency Contacts',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildContactTile(
              title: 'On-Call Property Manager',
              number: KioskConfig.onCallNumber,
              subtitle: 'Available 24/7 for urgent lockouts & property emergencies',
              icon: Icons.phone_forwarded,
              color: const Color(0xFF00F0FF),
            ),
            const SizedBox(height: 12),
            _buildContactTile(
              title: 'Thulusdhoo Health Centre / Ambulance',
              number: KioskConfig.localHealthCenterPhone,
              subtitle: 'Island medical emergency hotline',
              icon: Icons.local_hospital,
              color: const Color(0xFFEF476F),
            ),
            const SizedBox(height: 12),
            _buildContactTile(
              title: 'Maldives Police Service (Thulusdhoo)',
              number: KioskConfig.policeStationPhone,
              subtitle: 'Local island police desk',
              icon: Icons.local_police,
              color: const Color(0xFFFFB703),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required String title,
    required String number,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
