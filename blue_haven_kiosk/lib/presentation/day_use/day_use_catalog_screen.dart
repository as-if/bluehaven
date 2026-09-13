import 'package:flutter/material.dart';
import '../../core/config/kiosk_config.dart';
import '../../core/interfaces/payment_provider.dart';
import '../../data/repositories/lead_repository.dart';
import '../widgets/kiosk_app_bar.dart';

class DayUseCatalogScreen extends StatefulWidget {
  const DayUseCatalogScreen({super.key});

  @override
  State<DayUseCatalogScreen> createState() => _DayUseCatalogScreenState();
}

class _DayUseCatalogScreenState extends State<DayUseCatalogScreen> {
  Map<String, dynamic>? _selectedActivity;
  String _selectedSlot = '10:00 AM';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;
  bool _isBooked = false;

  final LeadRepository _leadRepository = LeadRepository();
  final PaymentProvider _paymentProvider = MockKioskPaymentProvider();

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:30 AM',
    '01:00 PM',
    '03:00 PM',
    '05:00 PM (Sunset)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleBookingSubmission() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and WhatsApp number.'),
          backgroundColor: Color(0xFFEF476F),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // 1. Immediately capture lead
    await _leadRepository.captureLead(
      name: name,
      phone: phone,
      intent: 'day_use_${_selectedActivity!['id']}',
    );

    // 2. Create Payment Session
    await _paymentProvider.createDayUsePayment(
      activityId: _selectedActivity!['id'],
      guestName: name,
      phone: phone,
      amountUSD: _selectedActivity!['price'],
      timeSlot: _selectedSlot,
    );

    setState(() {
      _isProcessing = false;
      _isBooked = true;
    });
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
              // Bounded Time Notice: Last Ferry to Malé
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB703), width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Color(0xFFFFB703), size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Day-Tripper Note: Last Speedboat back to Malé departs at 19:30 (7:30 PM). All activities finish with ample time for your ferry.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFB703)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: _isBooked
                    ? _buildConfirmationView()
                    : _selectedActivity != null
                        ? _buildBookingForm()
                        : _buildCatalogGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Surf, Spa & Day Experiences',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select an experience to book your slot. Confirmation & digital receipt sent straight to WhatsApp.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 1.25,
            ),
            itemCount: KioskConfig.dayUseActivities.length,
            itemBuilder: (context, index) {
              final act = KioskConfig.dayUseActivities[index];
              return _buildActivityCard(act);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> act) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E2238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3A5F), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedActivity = act),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB703).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Last Ferry: ${KioskConfig.lastFerryTime}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB703)),
                      ),
                    ),
                    Text(
                      '\$${(act['price'] as double).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF00F0FF)),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  act['name'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  act['duration'],
                  style: const TextStyle(fontSize: 14, color: Color(0xFF06D6A0), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  act['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedActivity = act),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Select Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForm() {
    final act = _selectedActivity!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Summary
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2238),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _selectedActivity = null),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
                  label: const Text('Change Experience', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 16)),
                ),
                const SizedBox(height: 12),
                Text(act['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(act['duration'], style: const TextStyle(fontSize: 16, color: Color(0xFF06D6A0), fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text(act['description'], style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.4)),
                const Spacer(),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 20, color: Colors.white70)),
                    Text('\$${(act['price'] as double).toStringAsFixed(0)} USD',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF00F0FF))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 32),

        // Right Slot Selection & Contact Details
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Choose Time Slot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _timeSlots.map((slot) {
                    final isSelected = _selectedSlot == slot;
                    return InkWell(
                      onTap: () => setState(() => _selectedSlot = slot),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF0E2238),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? const Color(0xFF00F0FF) : Colors.white24),
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Guest Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  decoration: const InputDecoration(hintText: 'e.g. Liam Smith'),
                ),
                const SizedBox(height: 16),
                const Text('WhatsApp Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '+Country code & number',
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF25D366)),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleBookingSubmission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Confirm & Pay \$${(act['price'] as double).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: const Color(0xFF0E2238),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF06D6A0), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF06D6A0), size: 80),
            const SizedBox(height: 20),
            const Text(
              'Activity Booked!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '${_selectedActivity!['name']} is confirmed for $_selectedSlot for ${_nameController.text}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'The team has been notified in the ops system. Your voucher has been sent to your WhatsApp.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Back to Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
