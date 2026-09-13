import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/island_time_helper.dart';
import '../day_use/day_use_catalog_screen.dart';
import '../in_house/in_house_menu_screen.dart';
import '../walk_in/just_looking_screen.dart';
import '../walk_in/walk_in_flow_screen.dart';
import '../widgets/kiosk_app_bar.dart';
import '../widgets/privacy_sensor_badge.dart';

class IntentRouterScreen extends ConsumerWidget {
  const IntentRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final orderedTiles = IslandTimeHelper.getWeightedIntentTiles();

    return Scaffold(
      appBar: const KioskAppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 40.0 : 20.0,
            vertical: isLandscape ? 24.0 : 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How can we assist you today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select an option below to get started or connect with our team',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 24),

              // 4 High-Contrast Intent Tiles
              Expanded(
                child: isLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: orderedTiles.map((tileType) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: _buildTile(context, tileType, isLandscape: true),
                            ),
                          );
                        }).toList(),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: orderedTiles.map((tileType) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: _buildTile(context, tileType, isLandscape: false),
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 16),
              const Center(child: PrivacySensorBadge()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, IntentTileType type, {required bool isLandscape}) {
    switch (type) {
      case IntentTileType.roomTonight:
        return _buildCard(
          context: context,
          title: 'Room Tonight',
          subtitle: 'Available rooms, rack rates & instant remote booking',
          badgeText: 'WALK-IN',
          icon: Icons.hotel,
          accentColor: const Color(0xFF00F0FF),
          gradientColors: [const Color(0xFF0A3A60), const Color(0xFF061A30)],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalkInFlowScreen()),
            );
          },
          isLandscape: isLandscape,
        );

      case IntentTileType.dayActivities:
        return _buildCard(
          context: context,
          title: 'Surf, Spa & Day Trips',
          subtitle: 'Coaching, rentals, sandbanks & resort day pass',
          badgeText: 'DAY-USE',
          icon: Icons.surfing,
          accentColor: const Color(0xFFFFB703),
          gradientColors: [const Color(0xFF5A3E08), const Color(0xFF2E1F03)],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DayUseCatalogScreen()),
            );
          },
          isLandscape: isLandscape,
        );

      case IntentTileType.justLooking:
        return _buildCard(
          context: context,
          title: 'Just Looking',
          subtitle: 'Property photos, island guide & WhatsApp info pack',
          badgeText: 'EXPLORE',
          icon: Icons.photo_library,
          accentColor: const Color(0xFF06D6A0),
          gradientColors: [const Color(0xFF054535), const Color(0xFF03261D)],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JustLookingScreen()),
            );
          },
          isLandscape: isLandscape,
        );

      case IntentTileType.alreadyStaying:
        return _buildCard(
          context: context,
          title: "I'm Staying Here",
          subtitle: 'WhatsApp desk, room service, lockouts & local guide',
          badgeText: 'IN-HOUSE',
          icon: Icons.vpn_key,
          accentColor: const Color(0xFFEF476F),
          gradientColors: [const Color(0xFF5A1528), const Color(0xFF2E0913)],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InHouseMenuScreen()),
            );
          },
          isLandscape: isLandscape,
        );
    }
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isLandscape,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 2),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: isLandscape
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentColor.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(icon, size: 48, color: accentColor),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                        const Spacer(),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(icon, size: 32, color: accentColor),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70, size: 28),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
