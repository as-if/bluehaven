import 'package:cloud_firestore/cloud_firestore.dart';

class LeadModel {
  final String id;
  final String name;
  final String phone;
  final String intent; // 'room_tonight' | 'day_use' | 'just_looking' | 'in_house'
  final int? nights;
  final int? guests;
  final String status; // 'new' | 'contacted' | 'converted' | 'lost'
  final String source; // 'kiosk'
  final String deviceId;
  final DateTime capturedAt;

  const LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.intent,
    this.nights,
    this.guests,
    this.status = 'new',
    this.source = 'kiosk',
    required this.deviceId,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'intent': intent,
    if (nights != null) 'nights': nights,
    if (guests != null) 'guests': guests,
    'status': status,
    'source': source,
    'deviceId': deviceId,
    'capturedAt': Timestamp.fromDate(capturedAt),
  };

  factory LeadModel.fromJson(String id, Map<String, dynamic> json) {
    return LeadModel(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      intent: json['intent'] ?? 'walk_in',
      nights: json['nights'],
      guests: json['guests'],
      status: json['status'] ?? 'new',
      source: json['source'] ?? 'kiosk',
      deviceId: json['deviceId'] ?? '',
      capturedAt: (json['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
