import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final user = FirebaseAuth.instance.currentUser;
  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref().child("users");

  bool notificationsEnabled = true;

  String profileImage = "";
  String heroId = "";

  final TextEditingController oldPasswordController =
  TextEditingController();
  final TextEditingController newPasswordController =
  TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  final TextEditingController supportQueryController =
  TextEditingController();
  final TextEditingController supportPhoneController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  /// ================= FETCH USER DATA =================
  void fetchUserData() async {
    if (user != null) {
      final snapshot = await dbRef.child(user!.uid).get();
      if (snapshot.exists) {
        setState(() {
          profileImage = snapshot.child("profileImage").value?.toString() ?? "";
          heroId = snapshot.child("heroId").value?.toString() ?? "";
          notificationsEnabled = snapshot.child("notifications").value as bool? ?? true;
        });
      }
    }
  }

  /// ================= SIGN OUT =================
  void signOut() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  /// ================= CHANGE PASSWORD =================
  void showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration:
                  const InputDecoration(labelText: "Enter Old Password"),
                ),

                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration:
                  const InputDecoration(labelText: "Enter New Password"),
                ),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration:
                  const InputDecoration(labelText: "Re-enter New Password"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords do not match")),
                  );
                  return;
                }

                try {

                  AuthCredential credential =
                  EmailAuthProvider.credential(
                    email: user!.email!,
                    password: oldPasswordController.text,
                  );

                  await user!.reauthenticateWithCredential(credential);

                  await user!
                      .updatePassword(newPasswordController.text);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password Updated")),
                  );

                  Navigator.pop(context);

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Old password incorrect")),
                  );
                }
              },
              child: const Text("Update"),
            )
          ],
        );
      },
    );
  }

  /// ================= SUPPORT FORM =================
  void showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Support & Customer Care"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: supportQueryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: "Enter your query"),
                ),
                TextField(
                  controller: supportPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                  const InputDecoration(labelText: "Phone Number"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {

                await FirebaseDatabase.instance
                    .ref()
                    .child("support_requests")
                    .push()
                    .set({
                  "userId": user!.uid,
                  "email": user!.email,
                  "query": supportQueryController.text,
                  "phone": supportPhoneController.text,
                  "timestamp": DateTime.now().toString(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        "Submitted! We will contact you within 12 hours."),
                  ),
                );

                Navigator.pop(context);
              },
              child: const Text("Submit"),
            )
          ],
        );
      },
    );
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Settings",
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          /// ================= PROFILE CARD =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [

                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.red,
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? const Icon(Icons.person,
                      color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(user?.email ?? "",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      Text("Hero ID: $heroId"),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const ProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit,
                      color: Colors.red),
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// ================= NOTIFICATIONS =================
          SwitchListTile(
            activeColor: Colors.red,
            title: const Text("Enable Blood Request Notifications"),
            subtitle: const Text(
                "Receive alerts when someone requests blood"),
            value: notificationsEnabled,
            onChanged: (value) async {
              setState(() {
                notificationsEnabled = value;
              });

              // Save notification preference to Firebase
              await FirebaseDatabase.instance
                  .ref()
                  .child("users")
                  .child(user!.uid)
                  .update({"notifications": value});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value 
                    ? "In-app notifications enabled! You'll see alerts when blood requests are posted."
                    : "In-app notifications disabled. You won't see blood request alerts in the app."),
                  backgroundColor: value ? Colors.green : Colors.orange,
                ),
              );
            },
          ),

          const Divider(),

          /// CHANGE PASSWORD
          ListTile(
            leading:
            const Icon(Icons.lock, color: Colors.red),
            title: const Text("Change Password"),
            onTap: showChangePasswordDialog,
          ),

          const Divider(),

          /// SUPPORT
          ListTile(
            leading: const Icon(Icons.support_agent,
                color: Colors.red),
            title: const Text("Support & Customer Care"),
            onTap: showSupportDialog,
          ),

          const Divider(),

          /// ABOUT
          ListTile(
            leading:
            const Icon(Icons.info, color: Colors.red),
            title: const Text("About App"),
            subtitle: const Text("Blood Hero v1.0"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Blood Hero",
                applicationVersion: "1.0.0",
                applicationLegalese:
                "Made with ❤️ to save lives.",
              );
            },
          ),

          const SizedBox(height: 30),

          /// LOGOUT
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
              const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: signOut,
            child: const Text("Logout",
                style: TextStyle(
                    color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}