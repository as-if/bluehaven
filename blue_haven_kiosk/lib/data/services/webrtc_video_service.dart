import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/config/turn_config.dart';

enum VideoCallState {
  idle,
  initiating,
  ringing,
  connected,
  ended,
  unansweredTimeout,
  error,
}

class WebRTCVideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;

  final StreamController<VideoCallState> _stateController = StreamController<VideoCallState>.broadcast();
  Stream<VideoCallState> get callStateStream => _stateController.stream;
  VideoCallState currentState = VideoCallState.idle;

  Function(MediaStream)? onRemoteStreamAdded;
  Timer? _ringTimeoutTimer;

  void _setState(VideoCallState state) {
    currentState = state;
    _stateController.add(state);
  }

  /// Start two-way video call to remote operator
  Future<String?> startVideoCall({required bool enableCamera}) async {
    try {
      _setState(VideoCallState.initiating);

      // 1. Create Peer Connection with STUN + TURN
      peerConnection = await createPeerConnection(TurnConfig.iceServersConfiguration);

      // 2. Obtain Local Media (Mic + Optional Video)
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': enableCamera
            ? {
                'facingMode': 'user',
                'width': {'ideal': 640},
                'height': {'ideal': 480},
                'frameRate': {'ideal': 24},
              }
            : false,
      });

      // 3. Add tracks to peer connection
      for (final track in localStream!.getTracks()) {
        await peerConnection?.addTrack(track, localStream!);
      }

      // 4. Handle incoming remote stream from remote operator
      peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams.first;
          onRemoteStreamAdded?.call(remoteStream!);
        }
      };

      // 5. Create Firestore room
      final DocumentReference roomRef = _firestore.collection('kiosk_calls').doc();
      roomId = roomRef.id;

      // 6. Handle local ICE candidates
      peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        roomRef.collection('callerCandidates').add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      // 7. Create SDP Offer
      final RTCSessionDescription offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      // 8. Write offer with 'ringing' status
      await roomRef.set({
        'offer': {'type': offer.type, 'sdp': offer.sdp},
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
        'hasVideo': enableCamera,
        'source': 'kiosk_reception',
      });

      _setState(VideoCallState.ringing);

      // 9. Start 20-second ring timeout fallback
      _ringTimeoutTimer?.cancel();
      _ringTimeoutTimer = Timer(const Duration(seconds: 20), () {
        if (currentState == VideoCallState.ringing) {
          debugPrint('Video call unanswered after 20s. Triggering fallback.');
          _setState(VideoCallState.unansweredTimeout);
          endCall();
        }
      });

      // 10. Listen for Answer SDP from Ops app
      roomRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists) return;
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data == null) return;

        final status = data['status'];
        if (status == 'connected' || (data['answer'] != null && currentState == VideoCallState.ringing)) {
          _ringTimeoutTimer?.cancel();
          if (data['answer'] != null && peerConnection?.getRemoteDescription() == null) {
            final answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );
            await peerConnection?.setRemoteDescription(answer);
          }
          _setState(VideoCallState.connected);
        } else if (status == 'declined' || status == 'ended') {
          _ringTimeoutTimer?.cancel();
          _setState(VideoCallState.ended);
        }
      });

      // 11. Listen for remote ICE candidates
      roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            peerConnection?.addCandidate(
              RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              ),
            );
          }
        }
      });

      return roomId;
    } catch (e) {
      debugPrint('Error starting video call: $e');
      _setState(VideoCallState.error);
      return null;
    }
  }

  Future<void> endCall() async {
    _ringTimeoutTimer?.cancel();

    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        track.stop();
      }
      await localStream!.dispose();
      localStream = null;
    }

    if (peerConnection != null) {
      await peerConnection!.close();
      peerConnection = null;
    }

    if (roomId != null) {
      try {
        await _firestore.collection('kiosk_calls').doc(roomId).update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      roomId = null;
    }

    if (currentState != VideoCallState.unansweredTimeout) {
      _setState(VideoCallState.ended);
    }
  }

  void dispose() {
    endCall();
    _stateController.close();
  }
}
