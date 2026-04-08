import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class SleeperService {
  static const String _baseUrl = 'https://api.sleeper.app/v1';

  /// Fetches all NFL players and filters for active offensive players.
  static Future<List<Map<String, dynamic>>> fetchAllNflPlayers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/players/nfl'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<Map<String, dynamic>> filteredPlayers = [];
        final allowedPos = {'QB', 'RB', 'WR', 'TE', 'K'};
        final random = Random();

        data.forEach((id, player) {
          final pos = player['position'];
          final status = player['status'];
          final team = player['team'];

          // Filter for active offensive players with a valid team
          if (allowedPos.contains(pos) && status == 'Active' && team != null) {
            final double spsValue = 75.0 + random.nextDouble() * 20.0;
            String grade = 'C';
            if (spsValue >= 93) grade = 'A+';
            else if (spsValue >= 90) grade = 'A';
            else if (spsValue >= 87) grade = 'A-';
            else if (spsValue >= 84) grade = 'B+';
            else if (spsValue >= 80) grade = 'B';
            else if (spsValue >= 77) grade = 'B-';

            filteredPlayers.add({
              'player_id': id,
              'name': (player['full_name'] ?? "${player['first_name']} ${player['last_name']}").toUpperCase(),
              'team': team.toString().toUpperCase(),
              'pos': pos,
              'age': player['age'] ?? 21 + random.nextInt(12),
              'exp': player['years_exp'] ?? 0,
              'sps': spsValue.toStringAsFixed(1), 
              'grade': grade,
              'trend': random.nextInt(2000) - 1000, // Mock trend amount (-1000 to +1000)
              'isDrafted': false,
              'isReal': true,
              'imageUrl': 'https://sleepercdn.com/content/nfl/players/thumb/$id.jpg',
            });
          }
        });

        // Sort by SPS descending (Best Players First)
        filteredPlayers.sort((a, b) {
          double spsA = double.tryParse(a['sps'].toString()) ?? 0.0;
          double spsB = double.tryParse(b['sps'].toString()) ?? 0.0;
          return spsB.compareTo(spsA);
        });
        return filteredPlayers;
      } else {
        throw Exception('Sleeper API returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Sleeper players: $e');
    }
  }
}
