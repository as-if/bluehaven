enum IntentTileType {
  roomTonight,
  dayActivities,
  justLooking,
  alreadyStaying,
}

class IslandTimeHelper {
  /// Returns the sorted tile types weighted dynamically by Maldives island time:
  /// - Morning (06:00 - 12:00): Ferry lands with day-trippers -> Day activities first!
  /// - Afternoon (12:00 - 18:00): Check-ins & excursions
  /// - Evening (18:00 - 06:00): Late walk-ins looking for a room tonight -> Room tonight first!
  static List<IntentTileType> getWeightedIntentTiles([DateTime? customTime]) {
    final now = customTime ?? DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 12) {
      // Morning ferry arrivals
      return [
        IntentTileType.dayActivities,
        IntentTileType.justLooking,
        IntentTileType.roomTonight,
        IntentTileType.alreadyStaying,
      ];
    } else if (hour >= 12 && hour < 18) {
      // Afternoon
      return [
        IntentTileType.dayActivities,
        IntentTileType.roomTonight,
        IntentTileType.alreadyStaying,
        IntentTileType.justLooking,
      ];
    } else {
      // Evening & Night (18:00+)
      return [
        IntentTileType.roomTonight,
        IntentTileType.alreadyStaying,
        IntentTileType.dayActivities,
        IntentTileType.justLooking,
      ];
    }
  }

  static String getTimeAwareGreeting([DateTime? customTime]) {
    final hour = (customTime ?? DateTime.now()).hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }
}
