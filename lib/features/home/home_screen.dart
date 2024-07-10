import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../settings/settings_screen.dart';
import 'widgets/call_manager.dart';
import 'widgets/database_manager.dart';
import 'widgets/location_service.dart';
import 'widgets/navigation_manager.dart';
import 'widgets/tts_manager.dart';
import 'widgets/voice_animation.dart';
import 'widgets/state_to_image.dart';
import 'widgets/speech_recognition_manager.dart';

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
  final LocationService _locationService = LocationService();

  User? _user;
  String? _vehicleNumber;
  bool _isVoiceGuideEnabled = true;
  String? _displayedImage;
  String _ttsText = '';
  Timer? _locationTimer;
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String? _userType;
  double _currentBearing = 0.0;
  StreamSubscription? _compassSubscription;
  late SpeechRecognitionManager _speechRecognitionManager;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    _user = _auth.currentUser;
    if (_user != null) {
      await _getVehicleNumberAndListenForUpdates();
      _startLocationUpdates();
      _listenToCompass();
      _ttsManager.setStartHandler(_onTtsStart);
      _ttsManager.setCompletionHandler(_onTtsComplete);
      await _loadSettings();
    } else {
      print("User is not logged in");
    }
  }

  Future<void> _requestPermissions() async {
    final locationPermissionStatus = await Permission.locationWhenInUse.request();
    if (locationPermissionStatus.isGranted) {
      await Permission.activityRecognition.request();
    } else {
      // 권한이 거부되었을 때 처리
      print("Location permission not granted");
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_userType != null && _vehicleNumber != null) {
        await _locationService.updateLocation(_userType!, _vehicleNumber!);
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
          });
          _moveCameraToCurrentPosition();
        }
      }
    });
  }

  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events!.listen((event) {
      if (mounted) {
        setState(() {
          _currentBearing = event.heading ?? 0.0;
        });
        _moveCameraToCurrentPosition();
      }
    });
  }

  void _moveCameraToCurrentPosition() {
    if (_currentPosition != null && _mapController != null) {
      final LatLng targetPosition = _currentPosition!;
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: targetPosition,
          zoom: 19.0,
          tilt: 30.0,
          bearing: _currentBearing,
        ),
      ));
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getVehicleNumberAndListenForUpdates() async {
    print("Getting vehicle number...");
    _vehicleNumber = await _databaseManager.getVehicleNumber();
    if (_vehicleNumber != null) {
      _userType = await _databaseManager.getUserType(_vehicleNumber!);
      print("Listening for updates...");
      _listenForStateUpdates(_userType!, _vehicleNumber!);
      _listenForCallUpdates(_userType!, _vehicleNumber!);
      _listenForNavigationUpdates(_userType!, _vehicleNumber!);
      await _initializeSpeechRecognition(_userType!, _vehicleNumber!);
    } else {
      print("User type: not found in database");
    }
  }

  Future<void> _initializeSpeechRecognition(String userType, String vehicleNumber) async {
    DatabaseReference userRequestRef = _databaseManager.getDatabaseRef().child(userType).child(vehicleNumber).child('userRequest');
    _speechRecognitionManager = SpeechRecognitionManager(userRequestRef);
    await _speechRecognitionManager.initialize();
  }

  void _listenForStateUpdates(String userType, String vehicleNumber) {
    print("Listening for state updates...");

    _databaseManager.listenForTextUpdates(vehicleNumber, userType, _isVoiceGuideEnabled, (text) {
      _updateTtsText(text);
    });

    _databaseManager.getDatabaseRef()
        .child(userType)
        .child(vehicleNumber)
        .child('problem')
        .onValue
        .listen((event) {
      DataSnapshot dataSnapshot = event.snapshot;
      print("DataSnapshot: ${dataSnapshot.value}");
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;

        String combinedText = '';
        if (_isVoiceGuideEnabled) {
          if (userType == 'general') {
            if (values['myText'] != null && values['myText'].toString().trim().isNotEmpty) {
              combinedText += '${values['myText']} ';
            }
            if (values['rxText'] != null && values['rxText'].toString().trim().isNotEmpty) {
              combinedText += '${values['rxText']} ';
            }
            if (values['txText'] != null && values['txText'].toString().trim().isNotEmpty) {
              combinedText += '${values['txText']} ';
            }
            if (values['nmText'] != null && values['nmText'].toString().trim().isNotEmpty) {
              combinedText += '${values['nmText']} ';
            }
          } else if (userType == 'emergency') {
            if (values['egText'] != null && values['egText'].toString().trim().isNotEmpty) {
              combinedText += '${values['egText']} ';
            }
          }
          if (combinedText.trim().isNotEmpty) {
            _updateTtsText(combinedText.trim());
          }
        }

        _displayStateImage(values['rxState']);
        _displayStateImage(values['txState']);
        _displayStateImage(values['myState']);
      } else {
        print("No data in snapshot");
      }
    });
  }

  void _updateTtsText(String? text) {
    if (text != null && text.trim().isNotEmpty) {
      setState(() {
        _ttsText = text;
        _displayedImage = stateToImage[_ttsText];
      });
      _ttsManager.speak(text).then((_) {
        if (mounted) {
          setState(() {
            _displayedImage = null;
          });
        }
      });
    } else {
      setState(() {
        _ttsText = '듣고 있습니다';
      });
    }
  }

  void _listenForCallUpdates(String userType, String vehicleNumber) {
    print("Listening for call updates...");

    _databaseManager.getDatabaseRef()
        .child(userType)
        .child(vehicleNumber)
        .child('report')
        .onValue
        .listen((event) {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;
        if (values['112'] == 1) _callManager.makePhoneCall('112');
        if (values['119'] == 1) _callManager.makePhoneCall('119');
        if (values['0800482000'] == 1) _callManager.makePhoneCall('0800482000');
      } else {
        print("No data in snapshot");
      }
    });
  }

  void _listenForNavigationUpdates(String userType, String vehicleNumber) {
    print("Listening for navigation updates...");

    _databaseManager.getDatabaseRef()
        .child(userType)
        .child(vehicleNumber)
        .child('Service')
        .onValue
        .listen((event) async {
      DataSnapshot dataSnapshot = event.snapshot;
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic> values = dataSnapshot.value as Map<dynamic, dynamic>;
        await _handleServiceUpdate(values, 'chargeStation');
        await _handleServiceUpdate(values, 'gasStation');
        await _handleServiceUpdate(values, 'restArea');
      } else {
        print("No data in snapshot");
      }
    });
  }

  Future<void> _handleServiceUpdate(Map<dynamic, dynamic> values, String serviceType) async {
    var service = values[serviceType];
    if (service != null && service['location'] != null) {
      double lat = _convertToDouble(service['location']['lat']);
      double long = _convertToDouble(service['location']['long']);
      String name = service['name'];
      if (lat != 0.0 && long != 0.0) {
        print('Navigating to $serviceType: $name, lat: $lat, long: $long');
        try {
          await _navigationManager.navigateToDestination(name, lat, long);
        } catch (e) {
          print('Error launching navigation: $e');
        }
      } else {
        print('Invalid $serviceType coordinates.');
      }
    }
  }

  double _convertToDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isVoiceGuideEnabled = prefs.getBool('isVoiceGuideEnabled') ?? true;
    });
    _ttsManager.enableVoiceGuide(_isVoiceGuideEnabled);
  }

  void _displayStateImage(String? state) {
    if (state != null && stateToImage.containsKey(state)) {
      setState(() {
        _displayedImage = stateToImage[state];
      });
    }
  }

  void _onTtsStart() {
    setState(() {
      _ttsManager.isSpeaking = true;
    });
  }

  void _onTtsComplete() {
    setState(() {
      _ttsManager.isSpeaking = false;
      _displayedImage = null;
    });
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/aiconnectcar_logo.png',
                width: 30,
                height: 30,
              ),
              SizedBox(width: 5),
              Text('AIConnectCar'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(ttsManager: _ttsManager),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition ?? LatLng(0, 0),
                        zoom: 19.0,
                        tilt: 30.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      padding: EdgeInsets.only(top: 300),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        if (_currentPosition != null) {
                          _moveCameraToCurrentPosition();
                        }
                      },
                    ),
                    if (_displayedImage != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Image.asset(
                            _displayedImage!,
                            width: 100,
                            height: 100,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    VoiceAnimation(isSpeaking: _ttsManager.isSpeaking),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 6.0,
                            ),
                          ],
                        ),
                        child: Text(
                          _ttsText.isNotEmpty ? _ttsText : '듣고 있습니다',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
