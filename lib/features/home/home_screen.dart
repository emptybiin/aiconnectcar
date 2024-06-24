import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'widgets/call_manager.dart';
import 'widgets/database_manager.dart';
import 'widgets/navigation_manager.dart';
import 'widgets/tts_manager.dart';
import 'widgets/voice_animation.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseManager _databaseManager = DatabaseManager('https://ai-connectcar-default-rtdb.asia-southeast1.firebasedatabase.app/');
  final TtsManager _ttsManager = TtsManager();
  final CallManager _callManager = CallManager();
  final NavigationManager _navigationManager = NavigationManager();
  User? _user;
  String? _vehicleNumber;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _getVehicleNumberAndListenForUpdates();
    } else {
      print("User is not logged in");
    }
    _ttsManager.setStartHandler(() {
      setState(() {
        _ttsManager.isSpeaking = true;
      });
    });

    _ttsManager.setCompletionHandler(() {
      setState(() {
        _ttsManager.isSpeaking = false;
      });
    });
  }

  void _getVehicleNumberAndListenForUpdates() async {
    print("Getting vehicle number...");
    _vehicleNumber = await _databaseManager.getVehicleNumber();
    if (_vehicleNumber != null) {
      print("Listening for updates...");
      _listenForTextUpdates('general', _vehicleNumber!);
      _listenForCallUpdates('general', _vehicleNumber!);
      _listenForNavigationUpdates('general', _vehicleNumber!);
    } else {
      print("User type: not found in database");
    }
  }

  void _listenForTextUpdates(String userType, String vehicleNumber) {
    print("Listening for text updates...");

    _databaseManager.getDatabaseRef().child(userType).child(vehicleNumber).child('problem').onValue.listen((event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;
        _ttsManager.speak(values['myText'] ?? '');
        _ttsManager.speak(values['rxText'] ?? '');
        _ttsManager.speak(values['txText'] ?? '');
      } else {
        print("No data in snapshot");
      }
    });
  }

  void _listenForCallUpdates(String userType, String vehicleNumber) {
    print("Listening for call updates...");

    _databaseManager.getDatabaseRef().child(userType).child(vehicleNumber).child('report').onValue.listen((event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;
        if (values['112'] == 1) {
          _callManager.makePhoneCall('112');
        }
        if (values['119'] == 1) {
          _callManager.makePhoneCall('119');
        }
        if (values['0800482000'] == 1) {
          _callManager.makePhoneCall('0800482000');
        }
      } else {
        print("No data in snapshot");
      }
    });
  }

  void _listenForNavigationUpdates(String userType, String vehicleNumber) {
    print("Listening for navigation updates...");

    _databaseManager.getDatabaseRef().child(userType).child(vehicleNumber).child('Service').onValue.listen((event) async {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;
        if (values['chargeStation'] != null) {
          var chargeStation = values['chargeStation'];
          if (chargeStation['location']['lat'] != null && chargeStation['location']['long'] != null) {
            double lat = chargeStation['location']['lat'].toDouble();
            double long = chargeStation['location']['long'].toDouble();
            String name = chargeStation['name'];
            if (lat != 0.0 && long != 0.0) {
              print('Navigating to charge station: $name, lat: $lat, long: $long');
              try {
                await _navigationManager.navigateToDestination(name, lat, long);
              } catch (e) {
                print('Error launching navigation: $e');
              }
            } else {
              print('Invalid charge station coordinates.');
            }
          }
        }
        if (values['gasStation'] != null) {
          var gasStation = values['gasStation'];
          if (gasStation['location']['lat'] != null && gasStation['location']['long'] != null) {
            double lat = gasStation['location']['lat'].toDouble();
            double long = gasStation['location']['long'].toDouble();
            String name = gasStation['name'];
            if (lat != 0.0 && long != 0.0) {
              print('Navigating to gas station: $name, lat: $lat, long: $long');
              try {
                await _navigationManager.navigateToDestination(name, lat, long);
              } catch (e) {
                print('Error launching navigation: $e');
              }
            } else {
              print('Invalid gas station coordinates.');
            }
          }
        }
      } else {
        print("No data in snapshot");
      }
    });
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VoiceAnimation(isSpeaking: _ttsManager.isSpeaking),
            SizedBox(height: 20),
            Text(
              'Welcome to AIConnectCar!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
