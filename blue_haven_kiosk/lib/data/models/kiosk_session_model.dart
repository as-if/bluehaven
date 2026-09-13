import 'package:cloud_firestore/cloud_firestore.dart';

class KioskSessionModel {
  final String id;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final String channel; // 'kiosk'
  final String? bookingId;
  final String status; // 'ai' | 'awaiting_human' | 'human' | 'closed'
  final String? assignedTo;
  final DateTime? escalatedAt;
  final String language;
  final String? summary;

  const KioskSessionModel({
    required this.id,
    required this.createdAt,
    required this.lastActivityAt,
    this.channel = 'kiosk',
    this.bookingId,
    this.status = 'ai',
    this.assignedTo,
    this.escalatedAt,
    this.language = 'en',
    this.summary,
  });

  Map<String, dynamic> toJson() => {
    'createdAt': Timestamp.fromDate(createdAt),
    'lastActivityAt': Timestamp.fromDate(lastActivityAt),
    'channel': channel,
    if (bookingId != null) 'bookingId': bookingId,
    'status': status,
    if (assignedTo != null) 'assignedTo': assignedTo,
    if (escalatedAt != null) 'escalatedAt': Timestamp.fromDate(escalatedAt!),
    'language': language,
    if (summary != null) 'summary': summary,
  };
}
