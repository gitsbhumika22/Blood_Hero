import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> saveUserData({
    required String name,
    required String phone,
    required String bloodGroup,
    required String city,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await _db.child("users").child(user.uid).set({
        "name": name,
        "phone": phone,
        "bloodGroup": bloodGroup,
        "city": city,
        "email": user.email,
      });
    }
  }
}
