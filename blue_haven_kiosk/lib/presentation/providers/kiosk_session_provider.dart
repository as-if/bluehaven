import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/offline_queue_manager.dart';
import '../../data/models/kiosk_session_model.dart';

class KioskSessionNotifier extends Notifier<KioskSessionModel?> {
  final Uuid _uuid = const Uuid();

  @override
  KioskSessionModel? build() {
    return null;
  }

  Future<String> startSession({String? bookingId}) async {
    final sessionId = _uuid.v4();
    final now = DateTime.now();
    final newSession = KioskSessionModel(
      id: sessionId,
      createdAt: now,
      lastActivityAt: now,
      bookingId: bookingId,
      status: 'ai',
      channel: 'kiosk',
    );

    state = newSession;

    // Trigger offline queue synchronization in background
    OfflineQueueManager.syncAllQueues();

    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .set(newSession.toJson())
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Offline fallback
    }

    return sessionId;
  }

  void updateActivity() {
    if (state != null) {
      state = KioskSessionModel(
        id: state!.id,
        createdAt: state!.createdAt,
        lastActivityAt: DateTime.now(),
        bookingId: state!.bookingId,
        status: state!.status,
        assignedTo: state!.assignedTo,
        escalatedAt: state!.escalatedAt,
        language: state!.language,
        summary: state!.summary,
      );
    }
  }

  void setLanguage(String lang) {
    if (state != null) {
      state = KioskSessionModel(
        id: state!.id,
        createdAt: state!.createdAt,
        lastActivityAt: DateTime.now(),
        bookingId: state!.bookingId,
        status: state!.status,
        assignedTo: state!.assignedTo,
        escalatedAt: state!.escalatedAt,
        language: lang,
        summary: state!.summary,
      );
    }
  }

  Future<void> endSession() async {
    final currentSession = state;
    if (currentSession != null) {
      state = null;
      try {
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(currentSession.id)
            .update({
          'status': 'closed',
          'closedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }
}

final kioskSessionNotifierProvider =
    NotifierProvider<KioskSessionNotifier, KioskSessionModel?>(() {
  return KioskSessionNotifier();
});
