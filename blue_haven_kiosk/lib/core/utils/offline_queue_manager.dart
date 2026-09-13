import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineQueueManager {
  static const String _leadsQueueKey = 'offline_leads_queue';
  static const String _requestsQueueKey = 'offline_service_requests_queue';

  /// Queue a lead locally when offline
  static Future<void> queueLead(Map<String, dynamic> leadData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentQueue = prefs.getStringList(_leadsQueueKey) ?? [];
      currentQueue.add(jsonEncode(leadData));
      await prefs.setStringList(_leadsQueueKey, currentQueue);
      debugPrint('Lead queued locally: ${leadData['phone']}');
    } catch (e) {
      debugPrint('Error queueing lead: $e');
    }
  }

  /// Queue a service request locally
  static Future<void> queueServiceRequest(Map<String, dynamic> requestData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentQueue = prefs.getStringList(_requestsQueueKey) ?? [];
      currentQueue.add(jsonEncode(requestData));
      await prefs.setStringList(_requestsQueueKey, currentQueue);
    } catch (e) {
      debugPrint('Error queueing request: $e');
    }
  }

  /// Sync all queued records to Firestore when connectivity is available
  static Future<void> syncAllQueues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firestore = FirebaseFirestore.instance;

      // Sync Leads
      final List<String> queuedLeads = prefs.getStringList(_leadsQueueKey) ?? [];
      if (queuedLeads.isNotEmpty) {
        final List<String> remainingLeads = [];
        for (final item in queuedLeads) {
          try {
            final Map<String, dynamic> data = jsonDecode(item);
            final leadId = data['id'] ?? firestore.collection('leads').doc().id;
            data.remove('id');
            data['syncedAt'] = FieldValue.serverTimestamp();
            await firestore.collection('leads').doc(leadId).set(data, SetOptions(merge: true));
          } catch (_) {
            remainingLeads.add(item);
          }
        }
        await prefs.setStringList(_leadsQueueKey, remainingLeads);
      }

      // Sync Service Requests
      final List<String> queuedRequests = prefs.getStringList(_requestsQueueKey) ?? [];
      if (queuedRequests.isNotEmpty) {
        final List<String> remainingRequests = [];
        for (final item in queuedRequests) {
          try {
            final Map<String, dynamic> data = jsonDecode(item);
            final reqId = data['id'] ?? firestore.collection('serviceRequests').doc().id;
            data.remove('id');
            data['createdAt'] = FieldValue.serverTimestamp();
            await firestore.collection('serviceRequests').doc(reqId).set(data);
          } catch (_) {
            remainingRequests.add(item);
          }
        }
        await prefs.setStringList(_requestsQueueKey, remainingRequests);
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }
}
