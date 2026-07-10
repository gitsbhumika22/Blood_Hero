import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() =>
      _DonationHistoryScreenState();
}

class _DonationHistoryScreenState
    extends State<DonationHistoryScreen> {

  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> donationHistory = [];

  DateTime? selectedDate;
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();

  File? proofImage;
  File? certificateImage;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> pickImage(bool isProof) async {
    final picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        if (isProof) {
          proofImage = File(picked.path);
        } else {
          certificateImage = File(picked.path);
        }
      });
    }
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> addDonation() async {
    if (selectedDate == null ||
        hospitalController.text.isEmpty ||
        cityController.text.isEmpty ||
        stateController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await db.child("donations").push().set({
      "uid": user!.uid,
      "hospital": hospitalController.text.trim(),
      "city": cityController.text.trim(),
      "state": stateController.text.trim(),
      "appointmentDate": selectedDate.toString(),
      "proofImage": proofImage?.path,
      "certificateImage": certificateImage?.path,
      "status": "Completed",
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Donation Added Successfully ⭐"),
        backgroundColor: Colors.green,
      ),
    );

    hospitalController.clear();
    cityController.clear();
    stateController.clear();
    selectedDate = null;
    proofImage = null;
    certificateImage = null;

    fetchHistory();
  }

  void fetchHistory() async {
    final snapshot = await db.child("donations").get();

    if (!snapshot.exists) return;

    final data =
    Map<String, dynamic>.from(snapshot.value as Map);

    List<Map<String, dynamic>> temp = [];

    data.forEach((key, value) {
      final donation =
      Map<String, dynamic>.from(value);

      if (donation["uid"] == user!.uid &&
          donation["status"] == "Completed") {
        temp.add(donation);
      }
    });

    setState(() {
      donationHistory = temp.reversed.toList();
    });
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Donation History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            /// ADD DONATION BOX
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border:
                Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [

                  const Text(
                    "Add Donated Blood Record",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade300),
                      ),
                      child: Text(
                        selectedDate == null
                            ? "Select Donation Date"
                            : selectedDate.toString(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: hospitalController,
                    decoration:
                    inputDecoration("Hospital / Blood Bank"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: cityController,
                    decoration:
                    inputDecoration("City"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: stateController,
                    decoration:
                    inputDecoration("State"),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () => pickImage(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      "Upload Donation Proof Image",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () => pickImage(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      "Upload Certificate",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: addDonation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15),
                      ),
                      child: const Text(
                        "Add Donation ⭐",
                        style: TextStyle(
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Your Donation History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            ...donationHistory.map((donation) {
              return Container(
                margin:
                const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation["hospital"],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    Text(donation["city"]),
                    Text(donation["appointmentDate"]),
                  ],
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }
}