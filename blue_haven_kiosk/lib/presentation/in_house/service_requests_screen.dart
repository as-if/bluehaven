import 'package:flutter/material.dart';
import '../../data/repositories/service_request_repository.dart';
import '../widgets/kiosk_app_bar.dart';

class ServiceRequestsScreen extends StatefulWidget {
  final String? initialRoomId;
  const ServiceRequestsScreen({super.key, this.initialRoomId});

  @override
  State<ServiceRequestsScreen> createState() => _ServiceRequestsScreenState();
}

class _ServiceRequestsScreenState extends State<ServiceRequestsScreen> {
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ServiceRequestRepository _repo = ServiceRequestRepository();

  String _selectedType = 'towels';
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final List<Map<String, dynamic>> _quickRequestTypes = [
    {
      'id': 'towels',
      'title': 'Fresh Towels',
      'desc': 'Clean bath and beach towels delivered to room',
      'icon': Icons.dry_cleaning,
      'color': Color(0xFF00F0FF),
    },
    {
      'id': 'water',
      'title': 'Drinking Water',
      'desc': 'Complimentary sealed glass bottles of purified water',
      'icon': Icons.water_drop,
      'color': Color(0xFF06D6A0),
    },
    {
      'id': 'housekeeping',
      'title': 'Room Cleaning',
      'desc': 'Tidy room, change bed linen & empty trash',
      'icon': Icons.cleaning_services,
      'color': Color(0xFFFFB703),
    },
    {
      'id': 'maintenance',
      'title': 'Maintenance & AC',
      'desc': 'Air conditioning, hot water, light or plug check',
      'icon': Icons.build,
      'color': Color(0xFFEF476F),
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomId != null) {
      _roomController.text = widget.initialRoomId!;
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final room = _roomController.text.trim();
    if (room.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Room Number.'),
          backgroundColor: Color(0xFFEF476F),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await _repo.createRequest(
      roomId: room,
      type: _selectedType,
      note: _noteController.text.trim().isEmpty ? 'Standard $_selectedType request' : _noteController.text.trim(),
    );

    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KioskAppBar(showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: _isSubmitted ? _buildSuccessView() : _buildRequestForm(),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Guest Service Requests',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'One tap to dispatch housekeeping or maintenance straight to the staff queue.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 24),

        // Quick Request Type Selection
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4 Quick Options
              Expanded(
                flex: 6,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _quickRequestTypes.length,
                  itemBuilder: (context, index) {
                    final item = _quickRequestTypes[index];
                    final isSelected = _selectedType == item['id'];
                    final color = item['color'] as Color;

                    return InkWell(
                      onTap: () => setState(() => _selectedType = item['id']),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E2238),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : Colors.white12,
                            width: isSelected ? 3 : 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'], color: color, size: 36),
                            const SizedBox(height: 12),
                            Text(
                              item['title'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['desc'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),

              // Room Input & Submit
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2238),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Your Room Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _roomController,
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 102 or Ocean-1',
                          prefixIcon: Icon(Icons.door_front_door, color: Color(0xFF00F0FF)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Special Notes (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Please leave outside door, or extra large towels',
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Dispatch Request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: const Color(0xFF0E2238),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF06D6A0), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF06D6A0), size: 80),
            const SizedBox(height: 16),
            const Text('Request Dispatched!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Your request for Room ${_roomController.text} has been placed directly in our staff task queue.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
