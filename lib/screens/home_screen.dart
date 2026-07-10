import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_filex/open_filex.dart';

import '../core/colors.dart';
import 'profile_screen.dart';
import 'donate_screen.dart';
import 'request_blood_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'donation_history_screen.dart';
import 'hospital_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseDatabase.instance.ref();

  Map userData = {};
  bool profileComplete = false;

  Map? activeAppointment;
  String? activeAppointmentKey;
  Duration remainingTime = Duration.zero;
  Timer? countdownTimer;

  List<Map<String, dynamic>> bloodRequests = [];

  List<Map<String, dynamic>> recentDonations = [];

  int _currentIndex = 0;
  int donationCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchActiveAppointment();
    fetchBloodRequests();
    fetchDonationCount();
    fetchRecentDonations();
  }
  /// ================= DISPOSE =================
  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  String generateHeroId() {
    if (user == null) return "BH-0000";

    // Take first 6 characters of UID
    String uidPart = user!.uid.substring(0, 6).toUpperCase();

    return "BH-$uidPart";
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return "${hours}h ${minutes}m ${seconds}s";
  }

  Future<void> saveHeroIdToDatabase() async {
    if (user == null) return;

    String heroId = generateHeroId();

    await db.child("users/${user!.uid}").update({
      "heroId": heroId,
    });
  }

  /// ================= CANCEL APPOINTMENT =================
  Future<void> cancelAppointment() async {
    if (activeAppointmentKey == null) return;

    await db.child("donations/$activeAppointmentKey").update({
      "status": "Cancelled"
    });

    countdownTimer?.cancel();

    setState(() {
      activeAppointment = null;
      activeAppointmentKey = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Appointment Cancelled Successfully"),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget getMedal() {
    if (donationCount >= 40) {
      return Column(
        children: const [
          Icon(Icons.emoji_events, color: Colors.amber, size: 40),
          Text("Gold Hero 🥇"),
        ],
      );
    } else if (donationCount >= 30) {
      return Column(
        children: const [
          Icon(Icons.emoji_events, color: Colors.grey, size: 40),
          Text("Silver Hero 🥈"),
        ],
      );
    } else if (donationCount >= 10) {
      return Column(
        children: const [
          Icon(Icons.emoji_events, color: Colors.brown, size: 40),
          Text("Bronze Hero 🥉"),
        ],
      );
    } else {
      return Column(
        children: const [
          Icon(Icons.star_border, size: 40),
          Text("Keep Donating ❤️"),
        ],
      );
    }
  }

  ///recent people donation
  void fetchRecentDonations() async {
    final snapshot = await db.child("donations").get();

    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    List<Map<String, dynamic>> tempList = [];

    for (var entry in data.entries) {
      final donation = Map<String, dynamic>.from(entry.value);

      // Only show donations from OTHER users (exclude current user)
      if (donation["status"] == "Completed" && donation["uid"] != user!.uid) {

        final userSnapshot =
        await db.child("users/${donation["uid"]}").get();

        if (userSnapshot.exists) {
          final userInfo =
          Map<String, dynamic>.from(userSnapshot.value as Map);

          tempList.add({
            "name": userInfo["name"] ?? "Unknown",
            "bloodGroup": userInfo["bloodGroup"] ?? "",
            "hospital": donation["hospital"] ?? "",
            "city": donation["city"] ?? "",
            "state": donation["state"] ?? "",
            "date": donation["appointmentDate"] ?? "",
          });
        }
      }
    }

    // Sort by latest first
    tempList.sort((a, b) =>
        b["date"].compareTo(a["date"]));

    setState(() {
      recentDonations = tempList.take(5).toList(); // show only 5 latest
    });
  }

  /// ================= FETCH USER =================
  /// ================= FETCH USER =================
  Future<void> fetchUserData() async {
    if (user == null) return;

    final snapshot = await db.child("users/${user!.uid}").get();

    if (!snapshot.exists) return;

    userData = Map<String, dynamic>.from(snapshot.value as Map);

    print(userData); // Debug to check Firebase data

    setState(() {
      profileComplete =
          (userData["name"] ?? "").toString().trim().isNotEmpty &&
              (userData["bloodGroup"] ?? "").toString().trim().isNotEmpty &&
              (userData["city"] ?? "").toString().trim().isNotEmpty &&
              (userData["state"] ?? "").toString().trim().isNotEmpty;
    });

    if (profileComplete) {
      await saveHeroIdToDatabase();
    }
  }

  Future<void> acceptRequest(String key, Map<String, dynamic> requestData) async {
    if (!profileComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete your profile first to accept blood requests"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to hospital selection screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalSelectionScreen(
          bloodRequestKey: key,
          requestData: requestData,
          userCity: userData["city"] ?? "",
          userState: userData["state"] ?? "",
        ),
      ),
    );
  }

  ///fetch blood request
  void fetchBloodRequests() {
    db.child("blood_requests").onValue.listen((event) {

      if (!event.snapshot.exists) return;

      final data =
      Map<String, dynamic>.from(event.snapshot.value as Map);

      List<Map<String, dynamic>> tempList = [];

      data.forEach((key, value) {
        final request =
        Map<String, dynamic>.from(value);

        if (request["status"] == "Active" &&
            request["uid"] != user!.uid) {

          request["key"] = key;
          tempList.add(request);
        }
      });

      setState(() {
        bloodRequests = tempList;
      });
    });
  }

  /// ================= FETCH APPOINTMENT =================
  void fetchActiveAppointment() async {
    final snapshot = await db.child("donations").get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in data.entries) {
        final donation = Map<String, dynamic>.from(entry.value);

        if (donation["uid"] == user!.uid &&
            donation["status"] == "Booked") {

          DateTime appointmentDate =
          DateTime.parse(donation["appointmentDate"]);

          // Check if appointment is today or in the future
          if (appointmentDate.isAfter(DateTime.now())) {
            setState(() {
              activeAppointment = donation;
              activeAppointmentKey = entry.key;
            });
            startCountdown(appointmentDate);
            break;
          }
        }
      }
    }
  }

  void startCountdown(DateTime appointmentDate) {
    countdownTimer?.cancel();

    countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {

          // Parse the appointment date and combine it with the time
          final appointmentDateTime = appointmentDate;
          final now = DateTime.now();
          
          final difference = appointmentDateTime.difference(now);

          setState(() {
            remainingTime = difference.isNegative ? Duration.zero : difference;
          });

          // If countdown reaches zero, stop the timer and refresh appointment
          if (difference.isNegative) {
            timer.cancel();
            fetchActiveAppointment(); // Refresh to remove expired appointment
          }
        });
  }

  /// ================= SIGN OUT =================
  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  ///donation history count
  Future<void> fetchDonationCount() async {
    final snapshot = await db.child("donations").get();

    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    int count = 0;

    data.forEach((key, value) {
      final donation = Map<String, dynamic>.from(value);

      if (donation["uid"] == user!.uid &&
          donation["status"] == "Completed") {
        count++;
      }
    });

    setState(() {
      donationCount = count;
    });
  }

  /// ================= PDF =================
  Future<void> generateIdCard() async {
    final pdf = pw.Document();

    final imagePath = userData["imagePath"];
    pw.MemoryImage? profileImage;

    if (imagePath != null && File(imagePath).existsSync()) {
      final imageBytes = File(imagePath).readAsBytesSync();
      profileImage = pw.MemoryImage(imageBytes);
    }

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Container(
              width: 380,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(15),
                border: pw.Border.all(color: PdfColors.red, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [

                  /// HEADER
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        "🩸 BLOOD HERO ID CARD",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  /// IMAGE
                  if (profileImage != null)
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(
                            color: PdfColors.red, width: 2),
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(
                          profileImage,
                          width: 110,
                          height: 110,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),

                  pw.SizedBox(height: 15),

                  pw.Text(
                    userData["name"] ?? "",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 10),

                  /// DETAILS
                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Hero ID"),
                      pw.Text(generateHeroId(),
                          style: pw.TextStyle(
                              fontWeight:
                              pw.FontWeight.bold)),
                    ],
                  ),

                  pw.SizedBox(height: 5),

                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Blood Group"),
                      pw.Text(
                          userData["bloodGroup"] ?? "",
                          style: pw.TextStyle(
                              fontWeight:
                              pw.FontWeight.bold)),
                    ],
                  ),

                  pw.SizedBox(height: 5),

                  pw.Row(
                    mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Age"),
                      pw.Text(
                          userData["ageDisplay"] ?? ""),
                    ],
                  ),

                  pw.SizedBox(height: 10),

                  pw.Text(
                    "${userData["areaAddress"] ?? ""}, "
                        "${userData["city"] ?? ""}, "
                        "${userData["state"] ?? ""}",
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 15),
                  pw.Divider(),

                  pw.Text(
                    "Valid Blood Donor • Save Lives ❤️",
                    style: pw.TextStyle(
                      color: PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file =
    File("${directory.path}/blood_hero_id.pdf");

    await file.writeAsBytes(await pdf.save());
    OpenFilex.open(file.path);
  }

  /// ================= BODY UI =================
  Widget buildHomeBody() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        /// Active Appointment
        if (activeAppointment != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      "Your Appointment",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Appointment Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_hospital, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activeAppointment!["hospital"] ?? "Hospital",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "${activeAppointment!["city"] ?? ""}, ${activeAppointment!["state"] ?? ""}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            activeAppointment!["appointmentDate"] != null 
                                ? "${DateTime.parse(activeAppointment!["appointmentDate"]).day}-${DateTime.parse(activeAppointment!["appointmentDate"]).month}-${DateTime.parse(activeAppointment!["appointmentDate"]).year}"
                                : "Date",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Icon(Icons.access_time, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            activeAppointment!["time"] ?? "Time",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Countdown Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_bottom, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Time remaining:",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatDuration(remainingTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                /// Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: cancelAppointment,
                    child: const Text("Cancel Appointment"),
                  ),
                )
              ],
            ),
          ),

        const SizedBox(height: 20),



        /// ID Card Section
        if (true)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [

                /// HEADER BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Blood Hero ID Card",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: generateIdCard,
                        icon: const Icon(Icons.download, color: Colors.white),
                      )
                    ],
                  ),
                ),

                /// BODY
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [

                      /// LEFT SIDE PHOTO
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: AppColors.border,
                        backgroundImage: userData["imagePath"] != null &&
                            userData["imagePath"].toString().isNotEmpty &&
                            File(userData["imagePath"]).existsSync()
                            ? FileImage(File(userData["imagePath"]))
                            : null,
                        child: userData["imagePath"] == null ||
                                userData["imagePath"].toString().isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),

                      const SizedBox(width: 20),

                      /// RIGHT SIDE DETAILS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData["name"] ?? "",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            Text("Hero ID: ${generateHeroId()}"),
                            Text("Blood Group: ${userData["bloodGroup"] ?? ""}"),
                            Text("Age: ${userData["ageDisplay"] ?? ""}"),
                            Text(
                                "${userData["areaAddress"] ?? ""}, ${userData["city"] ?? ""}, ${userData["state"] ?? ""}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          const Text("Complete your profile to unlock ID Card"),

        const SizedBox(height: 25),

        /// ⭐ Hero Achievement Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            children: [
              const Text(
                "Your Donation Achievements",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              getMedal(),
              const SizedBox(height: 10),
              Text("Total Donations: $donationCount"),
            ],
          ),
        ),

        /// ================= RECENT DONORS =================
        const SizedBox(height: 25),

        /// ================= RECENT BLOOD HERO BOX =================
        if (recentDonations.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "🌟 Recent Blood Heroes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "See others who donated blood recently — you can be one of them ❤️",
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 15),

                ...recentDonations.map((donor) {

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Icon(
                          Icons.volunteer_activism,
                          color: Colors.red,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "${donor["name"]} • ${donor["bloodGroup"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                "Hospital: ${donor["hospital"]}",
                                style: const TextStyle(fontSize: 13),
                              ),

                              Text(
                                "Location: ${donor["city"]}, ${donor["state"]}",
                                style: const TextStyle(fontSize: 13),
                              ),

                              Text(
                                "Donated on: ${donor["date"]}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

        const SizedBox(height: 30),

        if (bloodRequests.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "🚨 Blood Requests",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              ...bloodRequests.map((request) {

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bloodtype, color: Colors.red, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            "Blood Group: ${request["bloodGroup"]}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 5),
                          Text("Patient: ${request["patientName"]} (${request["patientAge"]} years)"),
                        ],
                      ),

                      const SizedBox(height: 5),
                      
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 5),
                          Text("Requested By: ${request["requesterName"]}"),
                        ],
                      ),

                      const SizedBox(height: 5),
                      
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              request["fullAddress"]?.isNotEmpty == true 
                                  ? request["fullAddress"]
                                  : "${request["city"]}, ${request["state"]}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),
                      
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 5),
                          Text("Contact: ${request["phone"]}"),
                          if (request["alternatePhone"]?.isNotEmpty == true) ...[
                            const Text(" / "),
                            Text("${request["alternatePhone"]}"),
                          ],
                        ],
                      ),

                      if (request["timestamp"] != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 5),
                            Text(
                              "Requested: ${request["timestamp"]}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              acceptRequest(request["key"], request),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            "Accept & Donate",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }).toList()
            ],
          ),

        const SizedBox(height: 30),
      ],
    );
  }

  /// ================= MAIN BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// WHITE BACKGROUND
      backgroundColor: Colors.white,

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: Text(
          userData["name"] == null
              ? "Blood Hero"
              : "Hi, ${userData["name"]}",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [

          /// ⭐ Badge Icon
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DonationHistoryScreen(),
                ),
              ).then((_) {
                fetchDonationCount(); // refresh stars when returning
              });
            },
            icon: const Icon(Icons.star, color: Colors.white),
          ),

          /// 🚪 Logout Icon
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      /// ================= BODY =================
      body: buildHomeBody(),

      /// ================= FOOTER NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.red,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DonateScreen()))
                .then((_) {
              fetchActiveAppointment();
            });
          } else if (index == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                    const RequestBloodScreen()));
          } else if (index == 3) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                    const SettingsScreen()));
          } else if (index == 0) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                    const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile"),
          BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: "Donate"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bloodtype),
              label: "Request"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings"),
        ],
      ),
    );
  }
}