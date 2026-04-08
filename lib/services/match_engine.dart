import 'dart:math' as math;
import 'stat_service.dart';

class MatchEngine {
  static final math.Random _random = math.Random();

  /// Calculates real-world scores for a match using official NFL stats.
  /// 
  /// [team1Roster] and [team2Roster] are lists of player maps.
  /// [weeklyStats] is the payload from StatService.getWeeklyStats.
  static Map<String, double> calculateRealScore({
    required List<Map<String, dynamic>> team1Roster,
    required List<Map<String, dynamic>> team2Roster,
    required Map<String, dynamic> weeklyStats,
  }) {
    double score1 = 0.0;
    double score2 = 0.0;

    // Filter for starters only (Standard Sleeper logic: BN, IR, TAXI don't score)
    for (var p in team1Roster) {
      final pos = (p['pos'] ?? 'BN').toString().toUpperCase();
      if (!['BN', 'IR', 'TAXI'].contains(pos)) {
        final pid = p['player_id']?.toString();
        if (pid != null && weeklyStats.containsKey(pid)) {
          score1 += StatService.calculateFantasyPoints(weeklyStats[pid]);
        }
      }
    }

    for (var p in team2Roster) {
      final pos = (p['pos'] ?? 'BN').toString().toUpperCase();
      if (!['BN', 'IR', 'TAXI'].contains(pos)) {
        final pid = p['player_id']?.toString();
        if (pid != null && weeklyStats.containsKey(pid)) {
          score2 += StatService.calculateFantasyPoints(weeklyStats[pid]);
        }
      }
    }

    return {
      'score1': double.parse(score1.toStringAsFixed(2)),
      'score2': double.parse(score2.toStringAsFixed(2)),
    };
  }

  /// Original simulation-based engine (maintained as a fallback/draft tool)
  static Map<String, double> simulateMatch({
    required List<Map<String, dynamic>> team1Roster,
    required List<Map<String, dynamic>> team2Roster,
  }) {
    double team1Sps = 0;
    for (var p in team1Roster) {
      final val = p['sps'];
      if (val is num) {
        team1Sps += val.toDouble();
      } else if (val is String) {
        team1Sps += double.tryParse(val) ?? 50.0;
      } else {
        team1Sps += 50.0;
      }
    }

    double team2Sps = 0;
    for (var p in team2Roster) {
      final val = p['sps'];
      if (val is num) {
        team2Sps += val.toDouble();
      } else if (val is String) {
        team2Sps += double.tryParse(val) ?? 50.0;
      } else {
        team2Sps += 50.0;
      }
    }

    double baseScore1 = team1Sps / 20;
    double baseScore2 = team2Sps / 20;

    double variance1 = 0.85 + (_random.nextDouble() * 0.30);
    double variance2 = 0.85 + (_random.nextDouble() * 0.30);

    return {
      'score1': double.parse((baseScore1 * variance1).toStringAsFixed(1)),
      'score2': double.parse((baseScore2 * variance2).toStringAsFixed(1)),
    };
  }
}
