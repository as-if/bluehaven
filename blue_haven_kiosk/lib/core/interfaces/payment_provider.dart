class PaymentSessionResult {
  final bool success;
  final String? transactionId;
  final String? paymentUrl;
  final String? qrPayload;
  final String? errorMessage;

  const PaymentSessionResult({
    required this.success,
    this.transactionId,
    this.paymentUrl,
    this.qrPayload,
    this.errorMessage,
  });
}

abstract class PaymentProvider {
  String get name;

  Future<PaymentSessionResult> createDayUsePayment({
    required String activityId,
    required String guestName,
    required String phone,
    required double amountUSD,
    required String timeSlot,
  });

  Future<bool> verifyPaymentStatus(String transactionId);
}

class MockKioskPaymentProvider implements PaymentProvider {
  @override
  String get name => 'Kiosk Card / WhatsApp Link Gateway';

  @override
  Future<PaymentSessionResult> createDayUsePayment({
    required String activityId,
    required String guestName,
    required String phone,
    required double amountUSD,
    required String timeSlot,
  }) async {
    final txnId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentSessionResult(
      success: true,
      transactionId: txnId,
      paymentUrl: 'https://pay.bluehaven.mv/$txnId',
      qrPayload: 'https://pay.bluehaven.mv/$txnId',
    );
  }

  @override
  Future<bool> verifyPaymentStatus(String transactionId) async {
    return true;
  }
}
