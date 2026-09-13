import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/offline_queue_manager.dart';

class ServiceRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Create a guest service request (towels, water, housekeeping, maintenance)
  Future<String> createRequest({
    required String roomId,
    required String type, // 'towels' | 'water' | 'housekeeping' | 'maintenance'
    required String note,
    String? bookingId,
  }) async {
    final reqId = _uuid.v4();
    final data = {
      'roomId': roomId,
      'type': type,
      'note': note,
      'status': 'pending',
      'bookingId': ?bookingId,
      'source': 'kiosk',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('serviceRequests').doc(reqId).set(data).timeout(
        const Duration(seconds: 3),
      );
      debugPrint('Service request logged: $reqId');
    } catch (e) {
      debugPrint('Service request saved to offline queue: $e');
      await OfflineQueueManager.queueServiceRequest({
        'id': reqId,
        ...data,
      });
    }

    return reqId;
  }
}
