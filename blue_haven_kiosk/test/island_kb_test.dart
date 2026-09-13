import 'package:flutter_test/flutter_test.dart';
import 'package:blue_haven_kiosk/data/local/island_knowledge_base.dart';

void main() {
  group('Tier 1 Local Knowledge Base Retrieval Tests', () {
    test('Wi-Fi search returns correct credentials offline', () {
      final match = IslandKnowledgeBase.searchLocalKB('What is the wifi password?');
      expect(match, isNotNull);
      expect(match!.id, equals('wifi'));
      expect(match.answer, contains('escape2paradise'));
    });

    test('Breakfast hours search matches instantly', () {
      final match = IslandKnowledgeBase.searchLocalKB('When is breakfast served?');
      expect(match, isNotNull);
      expect(match!.id, equals('breakfast'));
      expect(match.answer, contains('07:00 to 10:00'));
    });

    test('Ferry schedule matches speedboat and MTCC departures', () {
      final match = IslandKnowledgeBase.searchLocalKB('What time is the ferry to Male?');
      expect(match, isNotNull);
      expect(match!.id, equals('ferry'));
      expect(match.answer, contains('19:30'));
    });

    test('Plugs and voltage queries return international universal socket information', () {
      final match = IslandKnowledgeBase.searchLocalKB('Do I need an adapter for power plugs?');
      expect(match, isNotNull);
      expect(match!.id, equals('plugs'));
      expect(match.answer, contains('230V'));
    });

    test('Modesty and bikini beach search returns island cultural rules', () {
      final match = IslandKnowledgeBase.searchLocalKB('Can I wear bikini on the beach?');
      expect(match, isNotNull);
      expect(match!.id, equals('modesty_bikini'));
      expect(match.answer, contains('Bikini Beach'));
    });

    test('Unmatched query returns null so it can be escalated to Tier 2 / Tier 3', () {
      final match = IslandKnowledgeBase.searchLocalKB('Can I borrow a submarine?');
      expect(match, isNull);
    });
  });
}
