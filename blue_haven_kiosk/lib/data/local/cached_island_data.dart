class CachedIslandData {
  static const String currentTide = 'High Tide at 16:45 (1.1m)';
  static const String nextLowTide = 'Low Tide at 22:30 (0.3m)';
  static const String surfReport = 'Cokes: 4-6ft Clean • Offshore wind';
  static const String waterTemp = '29°C Lagoon / 84°F';
  static const String tonightAvailability = '2 Rooms Available Tonight';
  
  static String getNextFerryStatus([DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    if (totalMinutes < 7 * 60 + 30) {
      return 'Next Ferry to Malé: 07:30 (Speedboat)';
    } else if (totalMinutes < 10 * 60 + 30) {
      return 'Next Ferry to Malé: 10:30 (Speedboat)';
    } else if (totalMinutes < 14 * 60 + 30) {
      return 'Next Ferry to Malé: 14:30 (MTCC Public Ferry)';
    } else if (totalMinutes < 16 * 60 + 30) {
      return 'Next Ferry to Malé: 16:30 (Speedboat)';
    } else if (totalMinutes < 19 * 60 + 30) {
      return '⚠️ Last Ferry to Malé: 19:30 (Speedboat)';
    } else {
      return 'No more ferries today • Tomorrow: 07:30';
    }
  }
}
