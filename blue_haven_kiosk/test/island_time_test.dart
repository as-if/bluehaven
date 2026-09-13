import 'package:flutter_test/flutter_test.dart';
import 'package:blue_haven_kiosk/core/utils/island_time_helper.dart';

void main() {
  group('Island Time Dynamic Tile Order Tests', () {
    test('Morning (08:00) prioritizes day activities when ferry arrives', () {
      final morningTime = DateTime(2026, 8, 29, 8, 30);
      final tiles = IslandTimeHelper.getWeightedIntentTiles(morningTime);

      expect(tiles.first, equals(IntentTileType.dayActivities));
      expect(IslandTimeHelper.getTimeAwareGreeting(morningTime), equals('Good Morning'));
    });

    test('Afternoon (14:00) balances excursions and check-in', () {
      final afternoonTime = DateTime(2026, 8, 29, 14, 0);
      final tiles = IslandTimeHelper.getWeightedIntentTiles(afternoonTime);

      expect(tiles.first, equals(IntentTileType.dayActivities));
      expect(tiles[1], equals(IntentTileType.roomTonight));
      expect(IslandTimeHelper.getTimeAwareGreeting(afternoonTime), equals('Good Afternoon'));
    });

    test('Evening (19:30) prioritizes room tonight for late walk-ins', () {
      final eveningTime = DateTime(2026, 8, 29, 19, 30);
      final tiles = IslandTimeHelper.getWeightedIntentTiles(eveningTime);

      expect(tiles.first, equals(IntentTileType.roomTonight));
      expect(tiles[1], equals(IntentTileType.alreadyStaying));
      expect(IslandTimeHelper.getTimeAwareGreeting(eveningTime), equals('Good Evening'));
    });
  });
}
