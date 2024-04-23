import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class KnockoutScreen extends StatefulWidget {
  final String leagueId;

  KnockoutScreen({required this.leagueId});

  @override
  _KnockoutScreenState createState() => _KnockoutScreenState();
}

class _KnockoutScreenState extends State<KnockoutScreen> {
  late List<Map<String, dynamic>> knockoutMatches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKnockoutMatches();
  }

  Future<void> fetchKnockoutMatches() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.football-data.org/v2/competitions/${widget.leagueId}/matches'),
        headers: {
          'X-Auth-Token':
              '2d0d42784c754f4a9c8f9d91515a4c27', // Replace with your API key
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> matches = json.decode(response.body)['matches'];
        final List<Map<String, dynamic>> updatedMatches = [];
        matches.forEach((match) {
          final stage = match['stage'];
          if (stage != null && !stage.toString().contains('GROUP_STAGE')) {
            final homeTeamName = match['homeTeam']['name'];
            final awayTeamName = match['awayTeam']['name'];
            final matchDate = DateTime.parse(match['utcDate']).toLocal();
            final status = match['status'];
            final formattedMatch = {
              'homeTeam': homeTeamName,
              'awayTeam': awayTeamName,
              'matchDate': matchDate,
              'status': status,
              'score': status == 'FINISHED'
                  ? '${match['score']['fullTime']['homeTeam']} - ${match['score']['fullTime']['awayTeam']}'
                  : null,
            };
            updatedMatches.add(formattedMatch);
          }
        });
        setState(() {
          knockoutMatches = updatedMatches;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch knockout matches');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Knockout Matches'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: knockoutMatches.length,
              itemBuilder: (context, index) {
                final match = knockoutMatches[index];
                final homeTeam = match['homeTeam'];
                final awayTeam = match['awayTeam'];
                final status = match['status'];
                final score = match['score'];
                final matchDate = match['matchDate'];
                return Card(
                  child: ListTile(
                    title: Text(
                      '${homeTeam != null ? homeTeam : "Not Yet"} vs ${awayTeam != null ? awayTeam : "Not Yet"}',
                    ),
                    subtitle: Text(
                      status == 'FINISHED'
                          ? 'Score: ${score}'
                          : 'Match Date: ${matchDate.toString().substring(0, 16)}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
