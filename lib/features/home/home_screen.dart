import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase(
    databaseURL: 'https://ai-connectcar-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).reference();
  final FlutterTts _flutterTts = FlutterTts();
  User? _user;
  String? _vehicleNumber;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _initializeTts();
      _getVehicleNumberAndListenForTextUpdates();
    } else {
      print("User is not logged in");
    }
  }

  void _initializeTts() {
    _flutterTts.setStartHandler(() {
      print("TTS playing");
    });
    _flutterTts.setCompletionHandler(() {
      print("TTS complete");
    });
    _flutterTts.setErrorHandler((msg) {
      print("TTS error: $msg");
    });
  }

  void _getVehicleNumberAndListenForTextUpdates() async {
    print("Getting vehicle number...");
    DatabaseEvent generalEvent = await _database.child('general').orderByChild('email').equalTo(_user!.email).once();
    DatabaseEvent emergencyEvent = await _database.child('emergency').orderByChild('email').equalTo(_user!.email).once();

    bool isGeneralUser = generalEvent.snapshot.value != null;
    bool isEmergencyUser = emergencyEvent.snapshot.value != null;

    if (isGeneralUser) {
      print("User type: general");
      Map<dynamic, dynamic> generalData = generalEvent.snapshot.value as Map<dynamic, dynamic>;
      _vehicleNumber = generalData.keys.first;
      _listenForTextUpdates('general', _vehicleNumber!);
    } else if (isEmergencyUser) {
      print("User type: emergency");
      Map<dynamic, dynamic> emergencyData = emergencyEvent.snapshot.value as Map<dynamic, dynamic>;
      _vehicleNumber = emergencyData.keys.first;
      _listenForTextUpdates('emergency', _vehicleNumber!);
    } else {
      print("User type: not found in database");
    }
  }

  void _listenForTextUpdates(String userType, String vehicleNumber) {
    print("Listening for text updates...");

    _database.child(userType).child(vehicleNumber).child('problem').onValue.listen((event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;
        if (userType == 'general') {
          _readTextIfNotEmpty(values['myText'], 'myText');
          _readTextIfNotEmpty(values['rxText'], 'rxText');
          _readTextIfNotEmpty(values['txText'], 'txText');
        } else {
          _readTextIfNotEmpty(values['egText'], 'egText');
        }
      } else {
        print("No data in snapshot");
      }
    });
  }

  void _readTextIfNotEmpty(String? text, String fieldName) {
    if (text != null && text.isNotEmpty) {
      print("$fieldName text: $text");
      _flutterTts.speak(text);
    } else {
      print("$fieldName is empty or null");
    }
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
        ],
      ),
      body: Center(
        child: Text('Welcome to AIConnectCar!'),
      ),
    );
  }
}
