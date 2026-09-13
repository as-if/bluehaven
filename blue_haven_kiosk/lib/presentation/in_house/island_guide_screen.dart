import 'package:flutter/material.dart';
import '../../core/config/kiosk_config.dart';
import '../../data/local/cached_island_data.dart';
import '../widgets/kiosk_app_bar.dart';

class IslandGuideScreen extends StatefulWidget {
  final int initialTab;
  const IslandGuideScreen({super.key, this.initialTab = 0});

  @override
  State<IslandGuideScreen> createState() => _IslandGuideScreenState();
}

class _IslandGuideScreenState extends State<IslandGuideScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KioskAppBar(showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2238),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF00F0FF),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF00F0FF),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(icon: Icon(Icons.directions_boat), text: 'Ferry, Tide & Surf'),
                    Tab(icon: Icon(Icons.storefront), text: 'Island Guide & Village'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFerryAndSurfTab(),
                    _buildVillageGuideTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 0: Ferry & Surf Timetable ─────────────────────────────────────────
  Widget _buildFerryAndSurfTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ferries
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2238),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_boat, color: Color(0xFFFFB703), size: 28),
                    SizedBox(width: 10),
                    Text('Ferry Departures to Malé', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: KioskConfig.ferriesToMale.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final item = KioskConfig.ferriesToMale[index];
                      final isLast = item.contains('Last');

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              isLast ? Icons.warning_amber_rounded : Icons.schedule,
                              color: isLast ? const Color(0xFFEF476F) : const Color(0xFF00F0FF),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isLast ? FontWeight.w900 : FontWeight.w600,
                                  color: isLast ? const Color(0xFFEF476F) : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),

        // Surf & Tides
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2238),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.surfing, color: Color(0xFF00F0FF), size: 28),
                    SizedBox(width: 10),
                    Text('Surf & Tide Status', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Cokes Surf Break', CachedIslandData.surfReport, Icons.waves, const Color(0xFF00F0FF)),
                const SizedBox(height: 16),
                _buildInfoRow('Chickens (Across Channel)', '3-5ft Fast wall • Boat transfer at jetty', Icons.kitesurfing, const Color(0xFF06D6A0)),
                const SizedBox(height: 16),
                _buildInfoRow('Tides', '${CachedIslandData.currentTide}\n${CachedIslandData.nextLowTide}', Icons.water, const Color(0xFFFFB703)),
                const SizedBox(height: 16),
                _buildInfoRow('Water Temperature', CachedIslandData.waterTemp, Icons.thermostat, const Color(0xFFEF476F)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Island Village Guide ────────────────────────────────────────────
  Widget _buildVillageGuideTab() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 2.2,
      children: [
        _buildGuideCard(
          title: 'ATM & Cash (BML)',
          desc: 'Bank of Maldives ATM next to Island Council (5 min walk). Visa & MasterCard accepted.',
          icon: Icons.atm,
          color: const Color(0xFF06D6A0),
        ),
        _buildGuideCard(
          title: 'Bikini Beach (3 min walk)',
          desc: 'North-west point of the island. Swimwear & sunbathing fully permitted.',
          icon: Icons.beach_access,
          color: const Color(0xFF00F0FF),
        ),
        _buildGuideCard(
          title: 'Village Shops & Snacks',
          desc: 'Local grocery marts open 08:00 - 22:00 (short closure during prayer times).',
          icon: Icons.store,
          color: const Color(0xFFFFB703),
        ),
        _buildGuideCard(
          title: 'Island Health Clinic',
          desc: 'Thulusdhoo Health Centre. Call 102 for 24/7 medical assistance.',
          icon: Icons.local_hospital,
          color: const Color(0xFFEF476F),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({required String title, required String desc, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
