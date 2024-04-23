import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroupsScreen extends StatefulWidget {
  final String leagueId;

  GroupsScreen({required this.leagueId});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<dynamic> standingsData = [];

  @override
  void initState() {
    super.initState();
    fetchStandingsData();
  }

  Future<void> fetchStandingsData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.football-data.org/v4/competitions/${widget.leagueId}/standings'),
        headers: {
          'X-Auth-Token':
              '2d0d42784c754f4a9c8f9d91515a4c27', // Replace with your API key
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          standingsData = data['standings'];
        });
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
        title: Text('Groups'),
      ),
      body: standingsData.isNotEmpty
          ? ListView.builder(
              itemCount: standingsData.length,
              itemBuilder: (context, index) {
                final groupData = standingsData[index];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Standings for ${groupData['group']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      DataTable(
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
                        rows: groupData['table'].map<DataRow>((teamData) {
                          return DataRow(
                            cells: <DataCell>[
                              DataCell(
                                Text(
                                  teamData['position'].toString(),
                                ),
                              ),
                              DataCell(
                                Text(
                                  teamData['team']['name'],
                                ),
                              ),
                              DataCell(
                                Text(
                                  teamData['points'].toString(),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
