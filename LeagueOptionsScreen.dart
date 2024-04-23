import 'dart:convert';
import 'package:flutter/material.dart';
import 'GroupsScreen.dart';
import 'KnockoutScreen.dart';
class LeagueOptionsScreen extends StatelessWidget {
  final String leagueName;
  final String leagueId;

  LeagueOptionsScreen({
    required this.leagueName,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(leagueName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              // Navigate to the Groups screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupsScreen(leagueId: leagueId),
                ),
                
              );
            },
            child: Text('Groups'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to the Groups screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KnockoutScreen(leagueId: leagueId),
                ),
                
              );
            },
            child: Text('Knockout'),
          ),
          
        ],
      ),
    );
  }
}