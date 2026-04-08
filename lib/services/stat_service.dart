import 'dart:convert';
import 'package:http/http.dart' as http;

class StatService {
  static const String _baseUrl = 'https://api.sleeper.app/v1';

  /// Fetches real NFL stats for a specific year and week.
  static Future<Map<String, dynamic>> getWeeklyStats(int year, int week) async {
    final response = await http.get(Uri.parse('$_baseUrl/stats/nfl/regular/$year/$week'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch individual player stats');
  }

  /// Standard Fantasy Scoring Calculation
  /// This maps real stats (pass_yd, rush_td, etc.) to fantasy points.
  static double calculateFantasyPoints(Map<String, dynamic> stats) {
    double points = 0.0;

    // Passing
    points += (stats['pass_yd'] ?? 0) * 0.04;
    points += (stats['pass_td'] ?? 0) * 4.0;
    points -= (stats['pass_int'] ?? 0) * 2.0;

    // Rushing
    points += (stats['rush_yd'] ?? 0) * 0.1;
    points += (stats['rush_td'] ?? 0) * 6.0;

    // Receiving
    points += (stats['rec_yd'] ?? 0) * 0.1;
    points += (stats['rec_td'] ?? 0) * 6.0;
    points += (stats['rec'] ?? 0) * 1.0; // Full PPR

    // Fumbles
    points -= (stats['fum_lost'] ?? 0) * 2.0;

    return double.parse(points.toStringAsFixed(2));
  }
}
