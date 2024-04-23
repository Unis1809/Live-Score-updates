import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/StandingsScreen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Add this line
  // Initialize the FlutterLocalNotificationsPlugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Configure the initialization settings for Android and iOS
  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  // Initialize the plugin with the initialization settings
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(PremierLeagueApp());
}

class PremierLeagueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Remove FirebaseMessaging.onMessage.listen
    // Remove _showNotification method

    return MaterialApp(
      title: 'UniScore',
      theme: ThemeData.dark(),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Loading...',
          style: TextStyle(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.width * 0.05,
          ),
        ),
      ),
    );
  }
}

void munot() async {
  const androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'Unis',
    'mine',
    channelDescription: 'mine',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  // Calculate the time for the first notification (e.g., after 8 hours from now)
  final now = DateTime.now();
  final scheduledTime = now.add(Duration(hours: 8));

  // Define the notification details

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Show the notification
  await flutterLocalNotificationsPlugin.periodicallyShow(
    0, // Notification ID
    'Alert', // Notification title
    'Donot forget !! it is FREE PALESTINE', // Notification body
    RepeatInterval.daily, // Repeat interval
    platformChannelSpecifics,

    payload: 'scheduled_notification',
    // Payload for handling notification
    // Specify the scheduled time for the first notification
    // (Optional: If omitted, the first notification will appear immediately)
  );
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UniScore'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MatchListScreen()),
                );
              },
              child: Text('View Matches'),
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.05), // Add some spacing
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StandingsScreen()),
                );
              },
              child: Text('View Standings'),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchListScreen extends StatefulWidget {
  @override
  _MatchListScreenState createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> {
  List<Map<String, dynamic>> _matches = [];
  late DateTime _selectedDate;
  late Timer _timer;
  late Timer _timer2;
  late String _selectedLeague = 'All';
  late Map<String, dynamic> _previousScores = {};
  Set<int> _matchStartedNotificationShown = {};
  late AudioPlayer _audioCache;

  // Define a set to keep track of match IDs for which "Match Ended" notification has been shown
  Set<int> _matchEndNotificationShown = {};

  @override
  void initState() {
    super.initState();
    // Initialize flutter_local_notifications// Initialize flutterLocalNotificationsPlugin
    _audioCache = AudioPlayer();
    _selectedDate = DateTime.now();
    fetchMatchesData(_selectedDate);

    // Start the timer to refresh data every 1 minute (adjust interval as needed)
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      fetchMatchesData(_selectedDate);
    });
    _timer2 = Timer.periodic(const Duration(hours: 5), (timer) {
      munot();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel(); // Cancel the timer to avoid memory leaks
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2028, 12, 31), // Set last date to December 31, 2028
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _matches.clear(); // Clear the existing matches
      });

      // Fetch matches
      await fetchMatchesData(_selectedDate);
    }
  }

  Future<void> playNotificationSound() async {
    try {
      // Create a UrlSource object with the URL
      final source = UrlSource(
          'https://audio-previews.elements.envatousercontent.com/files/249683200/preview.mp3?response-content-disposition=attachment%3B+filename%3D%22VTLFBS5-goal-celebration.mp3%22');
      // Load and play the audio file from the URL
      await _audioCache.play(source, volume: 100);
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> playwSound() async {
    try {
      // Create a UrlSource object with the URL
      final source =
          UrlSource('https://www.soundjay.com/misc/sounds/whistle-flute-1.mp3');
      // Load and play the audio file from the URL
      await _audioCache.play(source, volume: 100);
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> fetchMatchesData(DateTime date) async {
    try {
      final formattedDate =
          '${date.year}-${_padNumber(date.month)}-${_padNumber(date.day)}';
      final response = await http.get(
        Uri.parse(
            'https://api.football-data.org/v2/matches?dateFrom=$formattedDate&dateTo=$formattedDate'),
        headers: {
          'X-Auth-Token': '2d0d42784c754f4a9c8f9d91515a4c27',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> matches = json.decode(response.body)['matches'];
        final List<Map<String, dynamic>> updatedMatches = [];
        print('Matches Data: $matches');
        matches.forEach((match) {
          final matchId = match['id'];
          final matchDate = DateTime.parse(match['utcDate']).toLocal();
          final status = match['status'];
          final leagueName = match['competition']['name'];
          if (_isSameDay(matchDate, date) &&
              (_selectedLeague == 'All' || leagueName == _selectedLeague)) {
            if (status == 'SCHEDULED') {
              final leagueId = match['competition']['id'];
              final egyptianTime = matchDate.add(Duration(hours: 0));
              final formattedMatch = {
                'league': leagueName,
                'homeTeam': match['homeTeam']['name'],
                'awayTeam': match['awayTeam']['name'],
                'timer':
                    '${egyptianTime.hour}:${_padNumber(egyptianTime.minute)}',
                'status': 'Scheduled',
                'leagueId': leagueId,
              };
              updatedMatches.add(formattedMatch);
            } else if (status == 'FINISHED') {
              if (!_matchEndNotificationShown.contains(matchId)) {
                // Show "Match Ended" notification if it hasn't been shown before for this match
                final homeTeamName = match['homeTeam']['name'];
                final awayTeamName = match['awayTeam']['name'];
                showMatchEventNotification(
                    homeTeamName, awayTeamName, 'Match Ended');
                // Add the match ID to the set to indicate that the notification has been shown
                _matchEndNotificationShown.add(matchId);
              }
              final homeTeamName = match['homeTeam']['name'];
              final awayTeamName = match['awayTeam']['name'];
              final fullTime = match['score']['fullTime'];
              final homeTeamGoals = fullTime['homeTeam'];
              final awayTeamGoals = fullTime['awayTeam'];
              final formattedMatch = {
                'league': leagueName,
                'homeTeam': homeTeamName,
                'awayTeam': awayTeamName,
                'score': '$homeTeamGoals - $awayTeamGoals',
                'status': 'Finished',
              };
              updatedMatches.add(formattedMatch);
            } else if (status == 'IN_PLAY') {
              if (!_matchStartedNotificationShown.contains(matchId)) {
                // Show "Match Started" notification if it hasn't been shown before for this match
                final homeTeamName = match['homeTeam']['name'];
                final awayTeamName = match['awayTeam']['name'];
                showMatchEventNotification(
                    homeTeamName, awayTeamName, 'Match Started');
                // Add the match ID to the set to indicate that the notification has been shown
                _matchStartedNotificationShown.add(matchId);
              }
              final homeTeamName = match['homeTeam']['name'];
              final awayTeamName = match['awayTeam']['name'];
              final score = match['score']['fullTime'];

              final homeTeamGoals = score['homeTeam'];
              final awayTeamGoals = score['awayTeam'];
              final currentScores = {
                'home': homeTeamGoals,
                'away': awayTeamGoals
              };
              final scoreText = (homeTeamGoals == null || awayTeamGoals == null)
                  ? '0-0'
                  : '$homeTeamGoals - $awayTeamGoals';
              final previousScores = _previousScores['${match['id']}'];
              if (previousScores != null &&
                  (previousScores['home'] != currentScores['home'] ||
                      previousScores['away'] != currentScores['away'])) {
                // Determine the scoring team based on previous and current scores
                String scoringTeam;
                if (currentScores['home'] > previousScores['home']) {
                  scoringTeam = homeTeamName;
                } else if (currentScores['away'] > previousScores['away']) {
                  scoringTeam = awayTeamName;
                } else {
                  // No team scored (this may not be necessary depending on your logic)
                  scoringTeam =
                      'Cancelled'; // You can change this to something appropriate
                }
                // Call the showNotification method with the scoring team
                showNotification(
                    homeTeamName, awayTeamName, currentScores, scoringTeam);
              }
              // Update the previous scores for the next iteration
              _previousScores['${match['id']}'] = currentScores;
              final formattedMatch = {
                'league': leagueName,
                'homeTeam': homeTeamName,
                'awayTeam': awayTeamName,
                'score': scoreText,
                'status': 'Live',
                'timer': 'Live',
              };
              updatedMatches.add(formattedMatch);
            } else if (status == 'PAUSED') {
              // Handle matches in halftime
              final homeTeamName = match['homeTeam'] != null
                  ? match['homeTeam']['name']
                  : 'Unknown';
              final awayTeamName = match['awayTeam'] != null
                  ? match['awayTeam']['name']
                  : 'Unknown';
              final score = match['score'] != null
                  ? match['score']['fulltime']
                  : null; // Get halftime score
              final homeTeamGoals = score != null ? score['homeTeam'] : null;
              final awayTeamGoals = score != null ? score['awayTeam'] : null;
              showMatchEventNotification(homeTeamName, awayTeamName, "Paused");
              final scoreText = (homeTeamGoals == null || awayTeamGoals == null)
                  ? '0-0'
                  : '$homeTeamGoals - $awayTeamGoals';

              final formattedMatch = {
                'league': leagueName,
                'homeTeam': homeTeamName,
                'awayTeam': awayTeamName,
                'status': 'Paused',
              };
              updatedMatches.add(formattedMatch);
            } else if (status == 'POSTPONED') {
              // Handle postponed matches
              final formattedMatch = {
                'league': leagueName,
                'homeTeam': match['homeTeam']['name'],
                'awayTeam': match['awayTeam']['name'],
                'status': 'Postponed',
              };
              updatedMatches.add(formattedMatch);
            } else if (status == 'CANCELLED') {
              // Handle cancelled matches
              final formattedMatch = {
                'league': leagueName,
                'homeTeam': match['homeTeam']['name'],
                'awayTeam': match['awayTeam']['name'],
                'status': 'Cancelled',
              };
              updatedMatches.add(formattedMatch);
            }
          }
        });
        setState(() {
          _matches = updatedMatches;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> showGoalNotification(String homeTeamName, String awayTeamName,
      int homeGoals, int awayGoals) async {
    // Prepare notification content
    String title = 'Goal Scored';
    String body = '$homeTeamName $homeGoals - $awayGoals $awayTeamName scored!';
    await playNotificationSound();
    // Define the Android notification details
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'Unis',
      'Score',
      channelDescription: 'GOAAAL!!!',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('not'),
      playSound: true,
      showWhen: false,
    );

    // Define the iOS notification details
    const iOSPlatformChannelSpecifics = DarwinInitializationSettings();

    // Define the notification details
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics, // Notification details
      payload: 'goal_scored', // Payload
    );
  }

  Future<void> showNotification(String homeTeamName, String awayTeamName,
      Map<String, dynamic> scores, String scoringTeam) async {
    // Prepare notification content
    String title = 'Goal Scored';
    String body =
        '$scoringTeam scored!\n$homeTeamName ${scores['home']} - ${scores['away']} $awayTeamName';
    await playNotificationSound();
    // Define the Android notification details
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'Unis',
      'Score',
      channelDescription: 'GOAAAL!!!',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('not'),
      playSound: true,
      showWhen: false,
    );

    // Define the iOS notification details
    const iOSPlatformChannelSpecifics = DarwinInitializationSettings();

    // Define the notification details
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics, // Notification details
      payload: 'goal_scored', // Payload
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _padNumber(int number) {
    return number.toString().padLeft(2, '0');
  }

  Future<void> showMatchEventNotification(
      String homeTeamName, String awayTeamName, String event) async {
    // Customize title based on the event type
    String title;
    if (event == 'Match Started') {
      title = 'Match Started';
    } else if (event == 'Match Ended') {
      title = 'Match Ended';
    } else if (event == 'Halftime') {
      title = 'Halftime';
    } else {
      title = 'Match Event'; // Default title for other events
    }

    // Prepare notification body
    String body = '$homeTeamName vs $awayTeamName: $event';
    await playwSound();
    // Define notification details...
    // Define the Android notification details
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'Unis',
      'Score',
      channelDescription: 'Match Events',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('w'),
      playSound: true,
      showWhen: false,
    );

    // Define the iOS notification details
    const iOSPlatformChannelSpecifics = DarwinInitializationSettings();

    // Define the notification details
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title, // Notification title
      body, // Notification body
      platformChannelSpecifics, // Notification details
      payload: 'match_event', // Payload
    );
  }

  Future<void> onSelectNotification(String? payload) async {
    print("Notification clicked with payload: $payload");
    // Navigate to the match list screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MatchListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(
          'Match',
          minFontSize: 16, // Minimum font size
          maxLines: 1, // Limit to a single line
          overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
        ),
        actions: [
          IconButton(
            onPressed: () => _selectDate(context),
            icon: Icon(Icons.calendar_today),
          ),
          DropdownButton<String>(
            value: _selectedLeague,
            onChanged: (String? newValue) {
              setState(() {
                _selectedLeague = newValue!;
                // Call fetchMatchesData with the selected league
                _matches.clear(); // Clear existing matches
                fetchMatchesData(
                    _selectedDate); // Fetch matches for the selected league
              });
            },
            items: <String>[
              'All',
              'Premier League',
              'Primera Division',
              'Bundesliga',
              'Serie A',
              'UEFA Champions League'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final match = _matches[index];
          final isFinished = match.containsKey('score');
          final isLive = match.containsKey('timer');
          final isScheduled = match['status'] == 'SCHEDULED';
          final isPostponed = match['status'] == 'Postponed';
          final isSuspended = match['status'] == 'Suspended';
          final isCancelled = match['status'] == 'Cancelled';

          String scoreText = isFinished ? match['score'] : '';
          String timerText = isLive ? 'Time: ${match['timer']}' : '';

          // If the match is scheduled and not live, display the scheduled time
          if (isScheduled && !isLive) {
            timerText = 'Scheduled: ${match['time']}';
          }
// If the match is finished, display the score

// If the match is in halftime
          else if (match['status'] == 'Paused') {
            timerText =
                'Waiting to be resumed'; // Display "Paused" for matches with the status "PAUSED"
          } else if (isPostponed || isSuspended || isCancelled) {
            timerText = 'Status: ${match['status']}';
          }

          return GestureDetector(
            onTap: () {
              // Handle onTap
            },
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                title: Text(
                  '${match['homeTeam']} vs ${match['awayTeam']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isFinished ? Colors.green : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'League: ${match['league'] ?? 'Unknown League'}',
                      style: TextStyle(fontSize: 14.0),
                    ),
                    Text(
                      scoreText,
                      style: TextStyle(fontSize: 14.0),
                    ),
                    if (match['status'] == 'Paused') // Display halftime status
                      Text(
                        'Status:Paused',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    if (isPostponed ||
                        isSuspended ||
                        isCancelled) // Display status for postponed, suspended, or cancelled matches
                      Text(
                        timerText,
                        style: TextStyle(fontSize: 14.0),
                      ),
                    if (isLive) // Display remaining time only for live matches
                      Text(
                        timerText,
                        style: TextStyle(fontSize: 14.0),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
