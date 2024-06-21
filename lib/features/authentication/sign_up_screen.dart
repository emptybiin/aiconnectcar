import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _carNumberController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase(
    databaseURL: 'https://ai-connectcar-default-rtdb.asia-southeast1.firebasedatabase.app/',
  ).reference();
  String _errorMessage = '';
  List<bool> _selectedCarType = [true, false]; // Initial selection: Regular

  void _signUp() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;

      if (user != null) {
        String carType = _selectedCarType[0] ? 'general' : 'emergency';
        String vehicleNumber = _carNumberController.text;

        if (carType == 'general') {
          await _database.child(carType).child(vehicleNumber).set({
            'email': _emailController.text,
            'location': {
              'lat': 0,
              'long': 0,
            },
            'trigger': '',
            'problem': {
              'rxState': '',
              'txState': '',
              'myState': '',
              'txText': '',
              'rxText': '',
              'myText': '',
            },
            'Service': {
              'gasStation': {
                'name': '',
                'location': {
                  'lat': 0,
                  'long': 0,
                },
              },
              'chargeStation': {
                'name': '',
                'location': {
                  'lat': 0,
                  'long': 0,
                },
              },
            },
            'report': {
              '112': 0,
              '119': 0,
              '0800482000': 0,
            },
          });
        } else {
          await _database.child(carType).child(vehicleNumber).set({
            'email': _emailController.text,
            'location': {
              'lat': 0,
              'long': 0,
            },
            'trigger': '',
            'problem': {
              'egState': '',
              'egText': '',
            },
            'intersectionGPS': {
              'lat': 0,
              'long': 0,
            },
          });
        }

        _showSuccessDialog(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An unknown error occurred';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unknown error occurred';
      });
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You have successfully signed up!'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacementNamed(context, '/home'); // Navigate to home screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _carNumberController,
              decoration: InputDecoration(labelText: 'Car Number'),
            ),
            SizedBox(height: 20),
            Text('Select Car Type:'),
            ToggleButtons(
              isSelected: _selectedCarType,
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < _selectedCarType.length; i++) {
                    _selectedCarType[i] = i == index;
                  }
                });
              },
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Regular'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Emergency'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
