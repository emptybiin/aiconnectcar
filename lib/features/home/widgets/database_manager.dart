import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseManager {
  final DatabaseReference _database;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  DatabaseManager(String databaseURL) : _database = FirebaseDatabase(databaseURL: databaseURL).reference() {
    _user = _auth.currentUser;
  }

  Future<String?> getVehicleNumber() async {
    if (_user == null) return null;
    DatabaseEvent generalEvent = await _database.child('general').orderByChild('email').equalTo(_user!.email).once();
    DatabaseEvent emergencyEvent = await _database.child('emergency').orderByChild('email').equalTo(_user!.email).once();

    if (generalEvent.snapshot.value != null) {
      Map<dynamic, dynamic> generalData = generalEvent.snapshot.value as Map<dynamic, dynamic>;
      return generalData.keys.first;
    } else if (emergencyEvent.snapshot.value != null) {
      Map<dynamic, dynamic> emergencyData = emergencyEvent.snapshot.value as Map<dynamic, dynamic>;
      return emergencyData.keys.first;
    }
    return null;
  }

  DatabaseReference getDatabaseRef() {
    return _database;
  }
}
