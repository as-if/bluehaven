import 'package:flutter/material.dart';
import '../../data/repositories/lead_repository.dart';
import '../widgets/kiosk_app_bar.dart';
import '../widgets/whatsapp_qr_dialog.dart';

class JustLookingScreen extends StatefulWidget {
  const JustLookingScreen({super.key});

  @override
  State<JustLookingScreen> createState() => _JustLookingScreenState();
}

class _JustLookingScreenState extends State<JustLookingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSent = false;
  final LeadRepository _leadRepository = LeadRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleBrochureRequest() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your WhatsApp number.'), backgroundColor: Color(0xFFEF476F)),
      );
      return;
    }

    await _leadRepository.captureLead(
      name: name.isEmpty ? 'Explorer' : name,
      phone: phone,
      intent: 'just_looking',
    );

    setState(() => _isSent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KioskAppBar(showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Property Highlights & Rack Rates
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Blue Haven Retreat',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Boutique guesthouse in Thulusdhoo • Seconds to Cokes Surf Break',
                      style: TextStyle(fontSize: 18, color: Color(0xFF00F0FF)),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildFeatureCard(
                            title: 'Deluxe Ocean View (\$160/night)',
                            desc: 'Balcony with direct view of the surf and turquoise lagoon. King bed, AC, hot shower, breakfast.',
                            icon: Icons.hotel,
                          ),
                          const SizedBox(height: 14),
                          _buildFeatureCard(
                            title: 'Superior King Room (\$130/night)',
                            desc: 'Tropical garden view, luxury king mattress, espresso machine, private en-suite.',
                            icon: Icons.king_bed,
                          ),
                          const SizedBox(height: 14),
                          _buildFeatureCard(
                            title: 'Activities & Excursions',
                            desc: 'Daily surf coaching, surfboard rentals, sandbank snorkeling tours, dolphin cruises, and rooftop grill.',
                            icon: Icons.surfing,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 36),

              // Right: WhatsApp Capture Form
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2238),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF06D6A0).withValues(alpha: 0.4), width: 2),
                  ),
                  child: _isSent
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF06D6A0), size: 72),
                            const SizedBox(height: 20),
                            const Text(
                              'Brochure Sent!',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'We have dispatched our rates, photos, and ferry schedules to your WhatsApp.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, color: Colors.white70),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0077B6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                              child: const Text('Back to Home', style: TextStyle(fontSize: 18)),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.send_to_mobile, color: Color(0xFF06D6A0), size: 32),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Get Island Guide & Rates',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We will send high-res photos, rate card & ferry timetable straight to your WhatsApp.',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Your Name',
                                prefixIcon: Icon(Icons.person, color: Colors.white54),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'WhatsApp Number (+Country Code)',
                                prefixIcon: Icon(Icons.phone, color: Color(0xFF25D366)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _handleBrochureRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06D6A0),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Send to My Phone', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => WhatsAppQRDialog.show(context),
                                child: const Text('Or Scan WhatsApp QR', style: TextStyle(fontSize: 16, color: Color(0xFF00F0FF))),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required String title, required String desc, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2238),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF00F0FF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
