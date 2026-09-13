class KioskConfig {
  static const String propertyName = 'Blue Haven';
  static const String propertyLocation = 'Thulusdhoo Island, Maldives';
  static const String deviceId = 'kiosk_reception_tab_01';
  
  // Contacts & Remote Desk
  static const String onCallNumber = '+960 779 1234';
  static const String whatsappNumber = '9607791234';
  static const String whatsappMessage = 'Hello Blue Haven team, I am at the reception kiosk on Thulusdhoo and need assistance.';
  static String get whatsappUrl => 'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(whatsappMessage)}';
  
  static const String localHealthCenterPhone = '102';
  static const String policeStationPhone = '119';
  static const String ferryOperatorPhone = '+960 778 5544';

  // Staffed hours (Maldives Time: UTC+5)
  static const int staffedHourStart = 7; // 07:00
  static const int staffedHourEnd = 23;  // 23:00

  // Session Timeouts
  static const int lostPresenceTimeoutSeconds = 20; // 20s lost presence wipes session
  static const int idleInactivityTimeoutSeconds = 90; // 90s idle wipes session
  static const int videoCallRingTimeoutSeconds = 20; // 20s ring fallback
  static const int operatorAnswerTimeoutSeconds = 30; // 30s walk-in wait fallback
  static const int humanChatEscalationSeconds = 90; // 90s chat ladder fallback

  // Rack Rates (Published official rates, no discount parity breach)
  static const Map<String, double> rackRates = {
    'deluxe_ocean_view': 160.0,
    'superior_king': 130.0,
    'standard_double': 100.0,
  };

  static const List<Map<String, dynamic>> roomTypes = [
    {
      'id': 'deluxe_ocean_view',
      'name': 'Deluxe Ocean View',
      'pricePerNight': 160.0,
      'capacity': 2,
      'description': 'Panoramic balcony overlooking the turquoise lagoon & surf break.',
      'amenities': ['Balcony', 'King Bed', 'AC', 'Hot Water', 'Breakfast Included', 'Fast Wi-Fi'],
      'images': [
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80',
        'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=800&q=80',
      ],
    },
    {
      'id': 'superior_king',
      'name': 'Superior King Room',
      'pricePerNight': 130.0,
      'capacity': 2,
      'description': 'Spacious room with plush king bedding, tropical garden view.',
      'amenities': ['King Bed', 'AC', 'En-suite Bath', 'Breakfast Included', 'Espresso Machine'],
      'images': [
        'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
      ],
    },
    {
      'id': 'standard_double',
      'name': 'Standard Double Room',
      'pricePerNight': 100.0,
      'capacity': 2,
      'description': 'Comfortable island accommodation steps away from Cokes surf spot.',
      'amenities': ['Queen Bed', 'AC', 'En-suite Bath', 'Breakfast Included', 'Wi-Fi'],
      'images': [
        'https://images.unsplash.com/photo-1618773928121-c32242e63f39?auto=format&fit=crop&w=800&q=80',
      ],
    },
  ];

  // Day-Use Activities
  static const List<Map<String, dynamic>> dayUseActivities = [
    {
      'id': 'surf_lesson',
      'name': 'Surf Coaching & Board',
      'price': 65.0,
      'duration': '2 hours',
      'description': 'Beginner & intermediate surf coaching with local ISA certified guide.',
      'icon': 'surfing',
    },
    {
      'id': 'board_rental',
      'name': 'Surfboard Daily Rental',
      'price': 25.0,
      'duration': 'Full day',
      'description': 'Choice of performance shortboards, fish, or soft-tops.',
      'icon': 'sports',
    },
    {
      'id': 'sandbank_trip',
      'name': 'Sandbank & Snorkel Excursion',
      'price': 45.0,
      'duration': '3 hours',
      'description': 'Speedboat ride to pristine sandbank with reef shark and turtle snorkeling.',
      'icon': 'sailing',
    },
    {
      'id': 'spa_massage',
      'name': 'Balinese Spa Massage',
      'price': 50.0,
      'duration': '60 mins',
      'description': 'Relaxing deep tissue or aromatherapy massage in our quiet cabana.',
      'icon': 'spa',
    },
    {
      'id': 'haven_lunch',
      'name': 'Rooftop Grill Lunch Set',
      'price': 20.0,
      'duration': 'Dining',
      'description': 'Fresh reef fish, tropical salad, fresh coconut & dessert.',
      'icon': 'restaurant',
    },
    {
      'id': 'day_pass',
      'name': 'Full Day Resort Pass',
      'price': 35.0,
      'duration': 'Until 18:00',
      'description': 'Rooftop pool access, towel service, high-speed Wi-Fi, and welcome drink.',
      'icon': 'pool',
    },
  ];

  // Ferry schedules from Thulusdhoo to Malé / Airport
  static const List<String> ferriesToMale = [
    '07:30 (Speedboat - 30 min)',
    '10:30 (Speedboat - 30 min)',
    '14:30 (Public MTCC Ferry - 90 min)',
    '16:30 (Speedboat - 30 min)',
    '19:30 (Last Speedboat to Malé)',
  ];

  static const String lastFerryTime = '19:30';

  // Island Etiquette & Expectations
  static const String islandModestyNotice = 
      'Thulusdhoo is an inhabited Maldivian local island.\n\n'
      '• Modest dress code is respected within the village (shoulders and knees covered).\n'
      '• Bikini and swimwear are strictly allowed at the designated Bikini Beach.\n'
      '• Alcohol is strictly prohibited by Maldivian law on local inhabited islands.';
}
