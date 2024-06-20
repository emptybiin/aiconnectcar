import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Firebase 초기화 코드
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return AuthScreen();
        }
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();

  Future<void> _register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await FirebaseDatabase.instance.reference().child('vehicles/${_vehicleNumberController.text}').set({
        'location': 'Unknown',
        'text': 'No data yet',
      });
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login/Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
              controller: _vehicleNumberController,
              decoration: InputDecoration(labelText: 'Vehicle Number'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _login, child: Text('Login')),
                ElevatedButton(onPressed: _register, child: Text('Register')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> _saveData(String vehicleNumber, String text) async {
    await _dbRef.child('vehicles/$vehicleNumber').update({
      'text': text,
    });
  }

  Future<void> _readData(String vehicleNumber) async {
    DatabaseEvent event = await _dbRef.child('vehicles/$vehicleNumber').once();
    DataSnapshot snapshot = event.snapshot;
    Map<String, dynamic>? data = snapshot.value as Map<String, dynamic>?;
    if (data != null) {
      String text = data['text'] ?? 'No text found';
      await _speak(text);
    } else {
      await _speak('No data found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final vehicleNumber = 'your_vehicle_number'; // Replace this with actual vehicle number logic

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Enter text'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveData(vehicleNumber, _textController.text);
              },
              child: Text('Save Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _readData(vehicleNumber);
              },
              child: Text('Read Data'),
            ),
          ],
        ),
      ),
    );
  }
}
