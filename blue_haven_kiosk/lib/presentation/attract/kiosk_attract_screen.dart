import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/cached_island_data.dart';
import '../home/intent_router_screen.dart';
import '../providers/kiosk_session_provider.dart';
import '../widgets/privacy_sensor_badge.dart';

class KioskAttractScreen extends ConsumerStatefulWidget {
  const KioskAttractScreen({super.key});

  @override
  ConsumerState<KioskAttractScreen> createState() => _KioskAttractScreenState();
}

class _KioskAttractScreenState extends ConsumerState<KioskAttractScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late String _timeString;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timeString = _formatTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _timeString = _formatTime(DateTime.now()));
      }
    });

    // Clear any previous session state when returning to attract loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kioskSessionNotifierProvider.notifier).endSession();
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleWakeUp() async {
    await ref.read(kioskSessionNotifierProvider.notifier).startSession();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const IntentRouterScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return GestureDetector(
      onTap: _handleWakeUp,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient Dimmed Tropical Gradient & Imagery
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF030E1C),
                    Color(0xFF0A2240),
                    Color(0xFF0E3860),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Dimmed overlay texture
            Container(
              color: Colors.black.withValues(alpha: 0.40),
            ),

            // Top Status Bar: Property Branding & Clock
            Positioned(
              top: isLandscape ? 40 : 24,
              left: isLandscape ? 48 : 24,
              right: isLandscape ? 48 : 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BLUE HAVEN',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Thulusdhoo Island • Maldives',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF00F0FF),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      _timeString,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Center Call to Action (Tap to Begin)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0077B6), Color(0xFF0096C7)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                        border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 40),
                          SizedBox(width: 16),
                          Text(
                            'Tap Anywhere to Begin',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Rooms Tonight • Surf Lessons • Island Trips • In-House Services',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Shopfront Overlay: Tonight's Availability, Surf/Tide, Next Ferry to Malé
            Positioned(
              bottom: isLandscape ? 40 : 24,
              left: isLandscape ? 48 : 24,
              right: isLandscape ? 48 : 24,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071322).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusItem(
                          icon: Icons.hotel,
                          title: 'TONIGHT',
                          value: CachedIslandData.tonightAvailability,
                          color: const Color(0xFF06D6A0),
                        ),
                        Container(width: 1.5, height: 40, color: Colors.white12),
                        _buildStatusItem(
                          icon: Icons.surfing,
                          title: 'SURF & TIDE',
                          value: '${CachedIslandData.surfReport} • ${CachedIslandData.currentTide}',
                          color: const Color(0xFF00F0FF),
                        ),
                        Container(width: 1.5, height: 40, color: Colors.white12),
                        _buildStatusItem(
                          icon: Icons.directions_boat,
                          title: 'FERRY TO MALÉ',
                          value: CachedIslandData.getNextFerryStatus(),
                          color: const Color(0xFFFFB703),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const PrivacySensorBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, letterSpacing: 1.0),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
