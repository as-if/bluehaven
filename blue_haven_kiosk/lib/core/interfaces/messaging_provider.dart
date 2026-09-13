abstract class MessagingProvider {
  /// Send 6-digit OTP code for lockout recovery or phone verification
  Future<bool> sendVerificationCode({
    required String phoneNumber,
    required String code,
    required String guestName,
  });

  /// Send Day-Use / Booking confirmation details directly to WhatsApp
  Future<bool> sendWhatsAppConfirmation({
    required String phoneNumber,
    required String details,
  });
}

class MockMessagingProvider implements MessagingProvider {
  @override
  Future<bool> sendVerificationCode({
    required String phoneNumber,
    required String code,
    required String guestName,
  }) async {
    // In production, this dispatches via Cloud Functions to Twilio / WhatsApp Cloud API
    return true;
  }

  @override
  Future<bool> sendWhatsAppConfirmation({
    required String phoneNumber,
    required String details,
  }) async {
    return true;
  }
}
