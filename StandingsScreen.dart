import 'dart:convert';
import 'package:flutter/material.dart';
import 'LeagueOptionsScreen.dart';

import 'package:http/http.dart' as http;

class StandingsScreen extends StatefulWidget {
  @override
  _StandingsScreenState createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late List<Map<String, String>> leagues;

  @override
  void initState() {
    super.initState();
    leagues = [
      {'id': 'BL1', 'name': 'Bundesliga'},
      {'id': 'DED', 'name': 'Eredivisie'},
      {'id': 'BSA', 'name': 'Campeonato Brasileiro Série A'},
      {'id': 'PD', 'name': 'La Liga'},
      {'id': 'FL1', 'name': 'Ligue 1'},
      {'id': 'ELC', 'name': 'Championship'},
      {'id': 'PPL', 'name': ' Liga Portgal'},
      {'id': 'EC', 'name': 'European Championship'},
      {'id': 'SA', 'name': 'Serie A'},
      {'id': 'PL', 'name': 'Premier League'},
      {'id': 'CLI', 'name': 'Copa Libertadores'},
      {'id': 'CL', 'name': 'Uefa Champions League'},
    ];
  }

  Future<void> fetchStandingsData(String leagueId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.football-data.org/v4/competitions/$leagueId/standings'),
        headers: {
          'X-Auth-Token':
              '2d0d42784c754f4a9c8f9d91515a4c27', // Replace with your API key
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> standings = data['standings'];
        // Check if there are multiple standings (groups)
        if (standings.length > 1) {
          // If there are multiple standings, navigate to a screen to choose a group or knockout
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeagueOptionsScreen(
                leagueName: data['competition']['name'],
                leagueId: leagueId,
              ),
            ),
          );
        } else {
          // If there's only one standings, navigate to the standings display screen
          final List<dynamic> standingsData = standings[0]['table'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StandingsDisplayScreen(
                leagueName: data['competition']['name'],
                standingsData: standingsData,
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to fetch standings data');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select a League'),
      ),
      body: ListView.builder(
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          final league = leagues[index];
          return Card(
            child: ListTile(
              title: Text(league['name'] ?? ''),
              onTap: () {
                fetchStandingsData(league['id'] ?? '');
              },
            ),
          );
        },
      ),
    );
  }
}

class StandingsDisplayScreen extends StatelessWidget {
  final String leagueName;
  final List<dynamic> standingsData;

  StandingsDisplayScreen({
    required this.leagueName,
    required this.standingsData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Standings for $leagueName'),
      ),
      body: SingleChildScrollView(
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(
              label: Text(
                'Position',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Team',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Points',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: standingsData
              .map<DataRow>(
                (teamData) => DataRow(
                  cells: <DataCell>[
                    DataCell(
                      Text(
                        teamData['position'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        teamData['team']['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(
                      Text(
                        teamData['points'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
