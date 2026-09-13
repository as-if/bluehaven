import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/kiosk_config.dart';
import '../../data/repositories/lead_repository.dart';
import '../call/kiosk_video_call_screen.dart';
import '../widgets/kiosk_app_bar.dart';
import '../widgets/whatsapp_qr_dialog.dart';

class WalkInFlowScreen extends ConsumerStatefulWidget {
  const WalkInFlowScreen({super.key});

  @override
  ConsumerState<WalkInFlowScreen> createState() => _WalkInFlowScreenState();
}

class _WalkInFlowScreenState extends ConsumerState<WalkInFlowScreen> {
  int _currentStep = 0; // 0: Nights/Guests, 1: Contact, 2: Room selection & Gallery, 3: Island Expectations, 4: Connect with Host

  int _selectedNights = 1;
  int _selectedGuests = 2;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedRoomId = 'deluxe_ocean_view';
  bool _isSavingLead = false;

  final LeadRepository _leadRepository = LeadRepository();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLeadSubmissionAndAdvance() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and WhatsApp number.', style: TextStyle(fontSize: 18)),
          backgroundColor: Color(0xFFEF476F),
        ),
      );
      return;
    }

    setState(() => _isSavingLead = true);

    // CRITICAL REQUIREMENT: Write the lead to Firestore immediately BEFORE the next screen renders.
    // If the person abandons after this point, the operator still has the captured lead.
    await _leadRepository.captureLead(
      name: name,
      phone: phone,
      intent: 'room_tonight',
      nights: _selectedNights,
      guests: _selectedGuests,
    );

    setState(() {
      _isSavingLead = false;
      _currentStep = 2; // Advance to Room Availability & Gallery
    });
  }

  void _nextStep() {
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: KioskAppBar(
        showBackButton: true,
        onBack: _prevStep,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildNightsAndGuestsStep();
      case 1:
        return _buildContactCaptureStep();
      case 2:
        return _buildRoomsAndGalleryStep();
      case 3:
        return _buildIslandExpectationsStep();
      case 4:
      default:
        return _buildConnectHostStep();
    }
  }

  // ── Step 0: Nights & Guests ───────────────────────────────────────────────
  Widget _buildNightsAndGuestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Stay Duration & Guests',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'How many nights and guests for your stay tonight?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.white70),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: Row(
            children: [
              // Nights Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2238),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.nightlight_round, color: Color(0xFF00F0FF), size: 48),
                      const SizedBox(height: 16),
                      const Text('NIGHTS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (_selectedNights > 1) setState(() => _selectedNights--);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28.0),
                            child: Text('$_selectedNights', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          _buildStepperButton(
                            icon: Icons.add,
                            onTap: () => setState(() => _selectedNights++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Guests Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2238),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group, color: Color(0xFFFFB703), size: 48),
                      const SizedBox(height: 16),
                      const Text('GUESTS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFB703))),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove,
                            onTap: () {
                              if (_selectedGuests > 1) setState(() => _selectedGuests--);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28.0),
                            child: Text('$_selectedGuests', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          _buildStepperButton(
                            icon: Icons.add,
                            onTap: () => setState(() => _selectedGuests++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue to Availability', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward, size: 28),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  // ── Step 1: Immediate Contact Capture ────────────────────────────────────
  Widget _buildContactCaptureStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Where should we send your room details?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'We will send the room options & digital key directly to your WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: Color(0xFF00F0FF)),
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2238),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Sarah Jenkins',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF00F0FF), size: 28),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('WhatsApp Number (with country code)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. +44 7911 123456 or +960 771 2345',
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF25D366), size: 28),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: _isSavingLead ? null : _handleLeadSubmissionAndAdvance,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: _isSavingLead
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(width: 16),
                      Text('Saving Details...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View Available Rooms & Rates', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 28),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Available Rooms & Rack Rates (No discount parity breach) ─────
  Widget _buildRoomsAndGalleryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tonight\'s Available Rooms',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        const Text(
          'Official Rack Rates • Includes Island Breakfast & All Taxes',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF06D6A0)),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: KioskConfig.roomTypes.length,
            itemBuilder: (context, index) {
              final room = KioskConfig.roomTypes[index];
              final isSelected = _selectedRoomId == room['id'];

              return Container(
                width: 340,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2238),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF1E3A5F),
                    width: isSelected ? 3 : 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1E33),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        image: DecorationImage(
                          image: NetworkImage((room['images'] as List<String>).first),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  room['name'],
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              Text(
                                '\$${(room['pricePerNight'] as double).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF00F0FF)),
                              ),
                            ],
                          ),
                          const Text('per night / rack rate', style: TextStyle(fontSize: 12, color: Colors.white54)),
                          const SizedBox(height: 10),
                          Text(
                            room['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (room['amenities'] as List<String>).take(3).map((a) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(a, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedRoomId = room['id']);
                          _nextStep();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF0077B6),
                          foregroundColor: isSelected ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(isSelected ? 'Selected • Next' : 'Select Room', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 3: Island Expectations Screen ───────────────────────────────────
  // Thulusdhoo is an inhabited local island: no alcohol, modest dress outside designated beach.
  // Show this before the sale, not after. It prevents refund requests.
  Widget _buildIslandExpectationsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFFB703), size: 36),
            SizedBox(width: 12),
            Text(
              'Local Island Guidelines',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Important information about staying on an inhabited Maldivian island',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2238),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFB703).withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildExpectationRow(
                  icon: Icons.checkroom,
                  color: const Color(0xFF00F0FF),
                  title: 'Modest Dress in Local Village',
                  desc: 'Please keep shoulders and knees covered when walking through the island village and harbor.',
                ),
                const Divider(color: Colors.white12),
                _buildExpectationRow(
                  icon: Icons.beach_access,
                  color: const Color(0xFF06D6A0),
                  title: 'Bikini Beach (3 min walk)',
                  desc: 'Bikinis and swimwear are fully allowed and welcomed at the designated tourist Bikini Beach.',
                ),
                const Divider(color: Colors.white12),
                _buildExpectationRow(
                  icon: Icons.no_drinks,
                  color: const Color(0xFFEF476F),
                  title: 'No Alcohol on Inhabited Islands',
                  desc: 'Maldivian law strictly prohibits alcohol on local islands. Floating safari bar excursions are available.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('I Understand • Speak to Our Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              Icon(Icons.video_call, size: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpectationRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 4: Video Call to Remote Operator (with 30s fallback) ────────────
  Widget _buildConnectHostStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Connect with Our Remote Team',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Your lead has been captured for ${_nameController.text}. Tap below to start a live video call with the remote host who will finalize your room PIN & payment.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const SizedBox(height: 48),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KioskVideoCallScreen()),
              );
            },
            icon: const Icon(Icons.video_camera_front, size: 36),
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
              child: Text('Start Live Video Call', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 6,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton.icon(
            onPressed: () => WhatsAppQRDialog.show(context),
            icon: const Icon(Icons.qr_code_2, color: Color(0xFF25D366), size: 28),
            label: const Text(
              'Prefer WhatsApp? Scan QR Code',
              style: TextStyle(fontSize: 20, color: Color(0xFF25D366), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
