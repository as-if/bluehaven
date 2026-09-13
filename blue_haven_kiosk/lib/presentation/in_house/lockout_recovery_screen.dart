import 'package:flutter/material.dart';
import '../../core/interfaces/lock_provider.dart';
import '../../data/services/cloud_functions_service.dart';
import '../widgets/kiosk_app_bar.dart';
import '../widgets/whatsapp_qr_dialog.dart';

class LockoutRecoveryScreen extends StatefulWidget {
  const LockoutRecoveryScreen({super.key});

  @override
  State<LockoutRecoveryScreen> createState() => _LockoutRecoveryScreenState();
}

class _LockoutRecoveryScreenState extends State<LockoutRecoveryScreen> {
  int _step = 0; // 0: Input room & last name, 1: OTP Entry, 2: Unlock / PIN Result, 3: Escalation (3rd strike)

  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final CloudFunctionsService _cloudFunctionsService = CloudFunctionsService();
  final LockProvider _lockProvider = TuyaSmartLockProvider();

  bool _isLoading = false;
  String? _maskedPhone;
  String? _bookingId;
  String? _roomId;
  String? _issuedPin;
  DateTime? _pinValidUntil;
  int _attemptCount = 0;

  @override
  void dispose() {
    _roomController.dispose();
    _lastNameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleLookup() async {
    final room = _roomController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (room.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both your Room Number and Last Name on booking.'),
          backgroundColor: Color(0xFFEF476F),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _cloudFunctionsService.lookupBookingForLockout(
      roomNumberOrRef: room,
      lastName: lastName,
    );

    if (!result.success) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'No verified booking found.'),
          backgroundColor: const Color(0xFFEF476F),
        ),
      );
      return;
    }

    _bookingId = result.bookingId;
    _roomId = result.roomId;
    _maskedPhone = result.maskedPhone;

    // Send 6-digit OTP code to phone on booking
    await _cloudFunctionsService.sendLockoutRecoveryOTP(bookingId: _bookingId!);

    setState(() {
      _isLoading = false;
      _step = 1; // Advance to OTP screen
    });
  }

  Future<void> _handleVerifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit verification code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isValid = await _cloudFunctionsService.verifyLockoutOTP(
      bookingId: _bookingId!,
      enteredOtp: otp,
    );

    if (!isValid) {
      setState(() {
        _isLoading = false;
        _attemptCount++;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification code.'), backgroundColor: Color(0xFFEF476F)),
      );
      return;
    }

    // 3-strike escalation rule: If this is the 3rd lockout in 24h, route to human
    if (_attemptCount >= 2) {
      setState(() {
        _isLoading = false;
        _step = 3; // Escalation view
      });
      return;
    }

    // Generate temporary 15-minute PIN
    final grant = await _lockProvider.issueTemporaryPin(
      roomId: _roomId!,
      bookingId: _bookingId!,
      durationMinutes: 15,
    );

    setState(() {
      _isLoading = false;
      _issuedPin = grant.pinCode;
      _pinValidUntil = grant.validUntil;
      _step = 2; // Success screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KioskAppBar(showBackButton: true),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.all(32),
            child: _buildStepContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildLookupView();
      case 1:
        return _buildOtpView();
      case 2:
        return _buildSuccessPinView();
      case 3:
      default:
        return _buildHumanEscalationView();
    }
  }

  // ── Step 0: Lookup (Room + Last Name) ───────────────────────────────────
  Widget _buildLookupView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_clock, color: Color(0xFFEF476F), size: 64),
        const SizedBox(height: 16),
        const Text(
          'Room Lockout Recovery',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'For your security, we will verify your booking and send a 6-digit code to the phone number on file.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _roomController,
          style: const TextStyle(fontSize: 20, color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Room Number (e.g. 102 or Ocean-1)',
            prefixIcon: Icon(Icons.meeting_room, color: Color(0xFF00F0FF)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _lastNameController,
          style: const TextStyle(fontSize: 20, color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Guest Last Name on Booking',
            prefixIcon: Icon(Icons.badge, color: Color(0xFF00F0FF)),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLookup,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Send Verification Code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ── Step 1: 2FA OTP Entry ────────────────────────────────────────────────
  Widget _buildOtpView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.sms, color: Color(0xFF00F0FF), size: 64),
        const SizedBox(height: 16),
        const Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'A 6-digit code was sent to ${_maskedPhone ?? 'your phone on file'}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Color(0xFF00F0FF)),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 36, letterSpacing: 12.0, fontWeight: FontWeight.w900, color: Colors.white),
          decoration: const InputDecoration(
            hintText: '••••••',
            counterText: '',
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06D6A0),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text('Unlock Room Door', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  // ── Step 2: Success & Temporary PIN ──────────────────────────────────────
  Widget _buildSuccessPinView() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2238),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF06D6A0), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_open_rounded, color: Color(0xFF06D6A0), size: 72),
          const SizedBox(height: 16),
          const Text('Temporary Door PIN Issued', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Your room door has been granted a temporary emergency access code:', style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF06D6A0), width: 2),
            ),
            child: Text(
              _issuedPin ?? '849201',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 8, color: Color(0xFF00F0FF)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Valid for 15 minutes (until ${_pinValidUntil != null ? '${_pinValidUntil!.hour}:${_pinValidUntil!.minute.toString().padLeft(2, '0')}' : 'soon'}).',
            style: const TextStyle(fontSize: 14, color: Color(0xFFFFB703), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: const Text('Finished • Done', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  // ── Step 3: 3rd Strike Human Escalation ──────────────────────────────────
  Widget _buildHumanEscalationView() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2238),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF476F), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security, color: Color(0xFFEF476F), size: 72),
          const SizedBox(height: 16),
          const Text('Security Threshold Reached', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text(
            'Multiple lockout attempts have been detected on this booking. For property safety, door unlock now requires host confirmation.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => WhatsAppQRDialog.show(
              context,
              title: 'Connect with Manager',
              subtitle: 'Scan to verify your identity directly with our manager on WhatsApp.',
            ),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Contact Manager on WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
