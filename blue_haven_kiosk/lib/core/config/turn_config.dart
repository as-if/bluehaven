class TurnConfig {
  /// WebRTC ICE Configuration
  /// A TURN server is mandatory in Maldives due to carrier symmetric NAT on Dhiraagu & Ooredoo.
  static Map<String, dynamic> get iceServersConfiguration => {
    'iceServers': [
      // STUN Fallbacks
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      // Configurable TURN server (Metered / Twilio / Self-hosted coturn)
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp'
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };
}
