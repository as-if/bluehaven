import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config/kiosk_config.dart';
import '../../data/services/webrtc_video_service.dart';
import '../widgets/whatsapp_qr_dialog.dart';

class KioskVideoCallScreen extends StatefulWidget {
  const KioskVideoCallScreen({super.key});

  @override
  State<KioskVideoCallScreen> createState() => _KioskVideoCallScreenState();
}

class _KioskVideoCallScreenState extends State<KioskVideoCallScreen> {
  final WebRTCVideoService _videoService = WebRTCVideoService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isCameraEnabled = true;
  bool _isMuted = false;
  int _secondsElapsed = 0;
  Timer? _callDurationTimer;
  StreamSubscription<VideoCallState>? _callStateSub;

  VideoCallState _state = VideoCallState.initiating;

  @override
  void initState() {
    super.initState();
    _initRenderersAndStart();
  }

  Future<void> _initRenderersAndStart() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Check staff hours (07:00 - 23:00 Maldives time)
    final currentHour = DateTime.now().hour;
    final isWithinStaffedHours = currentHour >= KioskConfig.staffedHourStart && currentHour < KioskConfig.staffedHourEnd;

    _callStateSub = _videoService.callStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);

      if (state == VideoCallState.connected) {
        _startDurationTimer();
      } else if (state == VideoCallState.unansweredTimeout) {
        _handleUnansweredTimeout();
      } else if (state == VideoCallState.ended) {
        Navigator.of(context).pop();
      }
    });

    _videoService.onRemoteStreamAdded = (stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    };

    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    if (!isWithinStaffedHours) {
      // Outside staffed hours warning
      setState(() => _state = VideoCallState.unansweredTimeout);
      return;
    }

    await _videoService.startVideoCall(enableCamera: _isCameraEnabled);

    if (_videoService.localStream != null) {
      setState(() {
        _localRenderer.srcObject = _videoService.localStream;
      });
    }
  }

  void _startDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _handleUnansweredTimeout() {
    _callDurationTimer?.cancel();
  }

  void _endCall() async {
    _callDurationTimer?.cancel();
    await _videoService.endCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _callDurationTimer?.cancel();
    _callStateSub?.cancel();
    _videoService.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Remote Video Stream (Full Screen)
          if (_state == VideoCallState.connected && _remoteRenderer.srcObject != null)
            RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            _buildStatePlaceholder(),

          // Local Self-View PiP (Top Right)
          if (_isCameraEnabled && _localRenderer.srcObject != null)
            Positioned(
              top: 36,
              right: 36,
              width: 180,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                clipBehavior: Clip.antiAlias,
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // Unmistakable On-Screen Camera Active Indicator
          Positioned(
            top: 36,
            left: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF06D6A0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Color(0xFF06D6A0), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text('CAMERA ACTIVE (LIVE)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Call Controls (Bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCallButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.orange : Colors.white24,
                  onTap: () {
                    setState(() => _isMuted = !_isMuted);
                    _videoService.localStream?.getAudioTracks().forEach((track) {
                      track.enabled = !_isMuted;
                    });
                  },
                ),
                const SizedBox(width: 32),
                _buildCallButton(
                  icon: Icons.call_end,
                  color: const Color(0xFFEF476F),
                  size: 40,
                  padding: 24,
                  onTap: _endCall,
                ),
                const SizedBox(width: 32),
                _buildCallButton(
                  icon: _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                  color: _isCameraEnabled ? Colors.white24 : Colors.orange,
                  onTap: () {
                    setState(() => _isCameraEnabled = !_isCameraEnabled);
                    _videoService.localStream?.getVideoTracks().forEach((track) {
                      track.enabled = _isCameraEnabled;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatePlaceholder() {
    if (_state == VideoCallState.unansweredTimeout) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 580),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: const Color(0xFF0E2238),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00F0FF), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, color: Color(0xFF00F0FF), size: 72),
              const SizedBox(height: 16),
              const Text(
                'Host is Assisting Other Guests',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your lead is captured. Our on-call manager has received an urgent notification and will message your WhatsApp in a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Text(
                '24/7 On-Call Number: ${KioskConfig.onCallNumber}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFB703)),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => WhatsAppQRDialog.show(context),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Open WhatsApp QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Return to Home', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_in_talk, color: Color(0xFF00F0FF), size: 90),
          const SizedBox(height: 24),
          Text(
            _state == VideoCallState.ringing
                ? 'Ringing Remote Desk in Malé...'
                : _state == VideoCallState.initiating
                    ? 'Setting up Secure Video Channel...'
                    : 'Call Connected (${_formatDuration(_secondsElapsed)})',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'A remote host will appear on screen momentarily.',
            style: TextStyle(fontSize: 18, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 30,
    double padding = 18,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
