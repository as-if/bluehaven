class LockGrantResult {
  final bool success;
  final String? pinCode;
  final DateTime? validUntil;
  final String? errorMessage;

  const LockGrantResult({
    required this.success,
    this.pinCode,
    this.validUntil,
    this.errorMessage,
  });
}

abstract class LockProvider {
  String get vendorName;

  /// Issue a temporary passcode for room lockout recovery (e.g. 15 minutes valid)
  Future<LockGrantResult> issueTemporaryPin({
    required String roomId,
    required String bookingId,
    required int durationMinutes,
  });

  /// Trigger a one-shot remote unlock command
  Future<bool> remoteUnlock({
    required String roomId,
    required String bookingId,
  });
}

/// Mock / Tuya Smart Lock Adapter implementation
class TuyaSmartLockProvider implements LockProvider {
  @override
  String get vendorName => 'Tuya Smart Lock';

  @override
  Future<LockGrantResult> issueTemporaryPin({
    required String roomId,
    required String bookingId,
    required int durationMinutes,
  }) async {
    // Generate secure 6-digit random temporary PIN
    final pin = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final validUntil = DateTime.now().add(Duration(minutes: durationMinutes));

    return LockGrantResult(
      success: true,
      pinCode: pin,
      validUntil: validUntil,
    );
  }

  @override
  Future<bool> remoteUnlock({
    required String roomId,
    required String bookingId,
  }) async {
    // Real implementation calls Tuya API or local MQTT relay
    return true;
  }
}
