class KBEntry {
  final String id;
  final String title;
  final String answer;
  final List<String> keywords;
  final String category;

  const KBEntry({
    required this.id,
    required this.title,
    required this.answer,
    required this.keywords,
    required this.category,
  });
}

class IslandKnowledgeBase {
  static const List<KBEntry> entries = [
    KBEntry(
      id: 'wifi',
      title: 'Wi-Fi Network & Password',
      answer: '📶 Wi-Fi Network: "BlueHaven_Guest"\n🔑 Password: "escape2paradise" (case-sensitive).\nHigh-speed fiber internet is available throughout the property and in all rooms.',
      keywords: ['wifi', 'wi-fi', 'internet', 'password', 'connect', 'network', 'online'],
      category: 'amenities',
    ),
    KBEntry(
      id: 'breakfast',
      title: 'Breakfast Hours & Location',
      answer: '🍳 Breakfast is served daily from 07:00 to 10:00 at The Haven Garden Bistro (Ground Floor).\nChoose between our Fresh Continental set or Authentic Maldivian Mashuni with freshly baked Roshi.',
      keywords: ['breakfast', 'morning', 'food', 'eat', 'mashuni', 'dining', 'coffee'],
      category: 'dining',
    ),
    KBEntry(
      id: 'checkout',
      title: 'Check-out & Luggage Storage',
      answer: '🔑 Standard Check-out is at 11:00 AM.\n🧳 Complimentary luggage storage is available at the reception counter if your ferry leaves later in the day. Late checkout can be arranged with remote staff subject to availability.',
      keywords: ['checkout', 'check-out', 'check out', 'leave', 'luggage', 'bags', 'store', 'storage'],
      category: 'reception',
    ),
    KBEntry(
      id: 'checkin',
      title: 'Check-in Time',
      answer: '🛎️ Standard Check-in is at 14:00 (2:00 PM).\nIf you arrived early on the morning ferry, we will safely store your bags while our team readies your room.',
      keywords: ['checkin', 'check-in', 'check in', 'arrive', 'early', 'room ready'],
      category: 'reception',
    ),
    KBEntry(
      id: 'ferry',
      title: 'Ferry to Malé & Airport',
      answer: '🚤 Daily Speedboat to Malé / Airport: 07:30, 10:30, 16:30, 19:30 (30 mins, \$25/pax).\n⛴️ MTCC Public Ferry: 14:30 (90 mins, \$2/pax).\n⚠️ The LAST ferry leaves Thulusdhoo at 19:30.',
      keywords: ['ferry', 'boat', 'speedboat', 'male', 'airport', 'schedule', 'timetable', 'mtcc', 'ticket'],
      category: 'transport',
    ),
    KBEntry(
      id: 'plugs',
      title: 'Power Plugs & Voltage',
      answer: '🔌 Maldives operates on 230V / 50Hz. All rooms feature universal international power sockets with built-in USB ports. UK Type G, EU Type C, and US plugs fit directly without adapters.',
      keywords: ['plug', 'power', 'socket', 'voltage', 'adapter', 'charge', 'usb', 'electricity'],
      category: 'amenities',
    ),
    KBEntry(
      id: 'tap_water',
      title: 'Tap Water & Drinking Water',
      answer: '💧 Tap water comes from the local desalinated Coca-Cola water plant and is safe for showering and brushing teeth. Complimentary sealed glass bottles of purified drinking water are provided in your room and refilled daily.',
      keywords: ['water', 'tap water', 'drink', 'drinking', 'bottle', 'hydrate'],
      category: 'amenities',
    ),
    KBEntry(
      id: 'laundry',
      title: 'Laundry Service',
      answer: '🧺 Same-day wash and fold laundry service is available for \$10 per load. Place your laundry bag outside your room door and tap "Service Requests" on this kiosk.',
      keywords: ['laundry', 'wash', 'clothes', 'iron', 'dry', 'cleaning'],
      category: 'services',
    ),
    KBEntry(
      id: 'modesty_bikini',
      title: 'Bikini Beach & Island Dress Code',
      answer: '👙 Bikini Beach is located on the north-west tip of the island (3 min walk), where swimwear and bikinis are welcome!\n👕 In the local village streets and harbor, please respect Maldivian cultural guidelines by covering shoulders and knees.',
      keywords: ['bikini', 'beach', 'dress code', 'modest', 'clothes', 'swim', 'swimwear', 'culture', 'rules'],
      category: 'island',
    ),
    KBEntry(
      id: 'alcohol',
      title: 'Alcohol Policy',
      answer: '🚫 In accordance with Maldivian national law, alcohol is strictly prohibited on local inhabited islands.\nFloating bar safaris anchored off the lagoon offer beverage excursions — message our remote host to arrange a transfer boat.',
      keywords: ['alcohol', 'beer', 'wine', 'drink', 'bar', 'cocktail', 'liquor'],
      category: 'island',
    ),
    KBEntry(
      id: 'surf_spots',
      title: 'Cokes & Chickens Surf Breaks',
      answer: '🏄 Cokes (Right-hander) is situated directly off our eastern reef (paddle out from the beach).\n🏄 Chickens (Left-hander) is across the channel; surf transfers depart from the jetty (\$10 round trip).',
      keywords: ['surf', 'surfing', 'cokes', 'chickens', 'waves', 'swell', 'tide', 'board'],
      category: 'activities',
    ),
    KBEntry(
      id: 'atm_money',
      title: 'ATM & Currency Exchange',
      answer: '🏧 Bank of Maldives (BML) ATM is located next to the island council office (5 min walk) and accepts Visa/MasterCard. US Dollars and Maldivian Rufiyaa (MVR) are widely accepted everywhere.',
      keywords: ['atm', 'cash', 'money', 'card', 'currency', 'bml', 'rufiyaa', 'dollar', 'exchange'],
      category: 'island',
    ),
  ];

  /// Tier 1 On-Device Matcher: Response in <100ms, completely offline
  static KBEntry? searchLocalKB(String query) {
    if (query.trim().isEmpty) return null;
    final clean = query.toLowerCase();

    // 1. Direct exact keyword match
    for (final entry in entries) {
      for (final keyword in entry.keywords) {
        if (clean.contains(keyword)) {
          return entry;
        }
      }
    }

    // 2. Title partial match
    for (final entry in entries) {
      if (entry.title.toLowerCase().split(' ').any((word) => word.length > 3 && clean.contains(word))) {
        return entry;
      }
    }

    return null;
  }

  static String get fullKnowledgeBaseSummary {
    final buffer = StringBuffer();
    for (final e in entries) {
      buffer.writeln('${e.title}:\n${e.answer}\n');
    }
    return buffer.toString();
  }
}
