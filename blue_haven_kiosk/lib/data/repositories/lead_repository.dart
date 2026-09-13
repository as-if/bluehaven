import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/kiosk_config.dart';
import '../../core/utils/offline_queue_manager.dart';
import '../models/lead_model.dart';

class LeadRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Captures lead immediately and persists to Firestore / offline queue
  /// "Write the lead to Firestore immediately, before the next screen renders.
  /// If the person abandons here, the operator still has a lead."
  Future<String> captureLead({
    required String name,
    required String phone,
    required String intent,
    int? nights,
    int? guests,
  }) async {
    final leadId = _uuid.v4();
    final lead = LeadModel(
      id: leadId,
      name: name.trim(),
      phone: phone.trim(),
      intent: intent,
      nights: nights,
      guests: guests,
      status: 'new',
      source: 'kiosk',
      deviceId: KioskConfig.deviceId,
      capturedAt: DateTime.now(),
    );

    try {
      // Immediate Firestore write
      await _firestore.collection('leads').doc(leadId).set(lead.toJson()).timeout(
        const Duration(seconds: 3),
      );
      debugPrint('Lead successfully captured in Firestore: $leadId');
    } catch (e) {
      debugPrint('Firestore direct write failed (offline). Queueing locally: $e');
      // Queue offline
      await OfflineQueueManager.queueLead({
        'id': leadId,
        ...lead.toJson(),
      });
    }

    return leadId;
  }
}
