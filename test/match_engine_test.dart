import 'package:flutter_test/flutter_test.dart';
import 'package:daily_dynasty/services/match_engine.dart';

void main() {
  group('MatchEngine Tests', () {
    test('Higher SPS team should have a higher average score', () {
      final strongRoster = List.generate(10, (i) => {'sps': '80.0'});
      final weakRoster = List.generate(10, (i) => {'sps': '40.0'});

      double strongTotal = 0;
      double weakTotal = 0;
      int iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final result = MatchEngine.simulateMatch(
          team1Roster: strongRoster,
          team2Roster: weakRoster,
        );
        strongTotal += result['score1']!;
        weakTotal += result['score2']!;
      }

      final avgStrong = strongTotal / iterations;
      final avgWeak = weakTotal / iterations;

      print('Avg Strong Score: $avgStrong');
      print('Avg Weak Score: $avgWeak');

      expect(avgStrong > avgWeak, isTrue);
    });

    test('Scores should have some variance', () {
      final roster = List.generate(10, (i) => {'sps': '50.0'});
      final scores = <double>{};

      for (int i = 0; i < 20; i++) {
        final result = MatchEngine.simulateMatch(
          team1Roster: roster,
          team2Roster: roster,
        );
        scores.add(result['score1']!);
      }

      // With 15% variance, we should definitely see more than 1 unique score
      expect(scores.length > 1, isTrue);
    });
  });
}
