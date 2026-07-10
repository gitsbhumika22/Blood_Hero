import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {

  final db = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;

  DateTime? lastDonationDate;
  bool isEligible = false;
  DateTime? nextEligibleDate;
  String? selectedBloodGroup;

  bool alreadyBooked = false;   // NEW

  String selectedState = "";
  String selectedCity = "";
  String selectedHospital = "";
  String selectedTime = "";
  DateTime? selectedAppointmentDate;

  final TextEditingController heroIdController = TextEditingController();
  String? savedHeroId;

  @override
  void initState() {
    super.initState();
    fetchHeroId();
    checkExistingAppointment();   // ✅ NEW
  }

  /// ================= CHECK IF ALREADY BOOKED =================
  void checkExistingAppointment() async {
    final snapshot = await db.child("donations").get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in data.entries) {
        final donation = Map<String, dynamic>.from(entry.value);

        if (donation["uid"] == user!.uid &&
            donation["status"] == "Booked") {

          setState(() {
            alreadyBooked = true;
          });
          break;
        }
      }
    }
  }

  /// ================= FETCH HERO ID =================
  void fetchHeroId() async {
    final snapshot = await db.child("users/${user!.uid}/heroId").get();

    if (snapshot.exists) {
      setState(() {
        savedHeroId = snapshot.value.toString();
      });
    }
  }

  final List<String> states = [
    "Maharashtra","Gujarat","Rajasthan","Tamil Nadu"
  ];

  final Map<String, List<String>> cities = {
    "Maharashtra": ["Mumbai","Pune","Nagpur"],
    "Gujarat": ["Ahmedabad","Surat"],
    "Rajasthan": ["Jaipur","Udaipur"],
    "Tamil Nadu": ["Chennai","Madurai"],
  };

  final List<String> hospitals = [
    "AIIMS Hospital",
    "City Blood Bank",
    "Red Cross Blood Center",
    "Apollo Hospital"
  ];

  final List<String> timeSlots = [
    "9:00 AM - 11:00 AM",
    "11:00 AM - 1:00 PM",
    "2:00 PM - 4:00 PM"
  ];

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];

  void checkEligibility(DateTime pickedDate) {
    final difference = DateTime.now().difference(pickedDate).inDays;

    setState(() {
      lastDonationDate = pickedDate;
      isEligible = difference >= 50;
      if (!isEligible) {
        nextEligibleDate = pickedDate.add(const Duration(days: 50));
      } else {
        nextEligibleDate = null;
      }
    });
  }

  /// ================= SAVE APPOINTMENT =================
  void saveDonation() async {

    if (alreadyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already have an active appointment."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedBloodGroup == null ||
        selectedState.isEmpty ||
        selectedCity.isEmpty ||
        selectedHospital.isEmpty ||
        selectedTime.isEmpty ||
        selectedAppointmentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String actualHeroId =
        "BH-${user!.uid.substring(0, 6).toUpperCase()}";

    if (heroIdController.text.trim() != actualHeroId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Blood Hero ID"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await db.child("donations").push().set({
        "uid": user!.uid,
        "heroId": heroIdController.text.trim(),
        "bloodGroup": selectedBloodGroup,
        "state": selectedState,
        "city": selectedCity,
        "hospital": selectedHospital,
        "appointmentDate": selectedAppointmentDate!.toIso8601String(),
        "time": selectedTime,
        "lastDonationDate": lastDonationDate.toString(),
        "status": "Booked"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment Booked Successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error booking appointment: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text("Donate Blood"),
        centerTitle: true,
      ),

      body: alreadyBooked
          ? const Center(
        child: Text(
          "You already have a booked appointment.\nPlease cancel it first from Home Screen.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "You are about to save lives ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Select your last blood donation date:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  checkEligibility(picked);
                }
              },
              child: const Text("Choose Date"),
            ),

            const SizedBox(height: 20),

            if (lastDonationDate != null) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEligible ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEligible
                          ? " You are eligible to donate blood!"
                          : " You can donate blood after",
                      style: TextStyle(
                        color: isEligible ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!isEligible) ...[
                      const SizedBox(height: 5),
                      Text(
                        "${nextEligibleDate!.day}-${nextEligibleDate!.month}-${nextEligibleDate!.year}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Be healthy and stay hydrated! ",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            if (isEligible) ...[

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Blood Group to Donate"),
                items: bloodGroups.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBloodGroup = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select State"),
                items: states.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedState = value!;
                    selectedCity = "";
                  });
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select City"),
                items: (cities[selectedState] ?? [])
                    .map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Hospital"),
                items: hospitals.map((hospital) {
                  return DropdownMenuItem(
                    value: hospital,
                    child: Text(hospital),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedHospital = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (picked != null) {
                    setState(() {
                      selectedAppointmentDate = picked;
                    });
                  }
                },
                child: Text(
                  selectedAppointmentDate == null
                      ? "Choose Appointment Date"
                      : "${selectedAppointmentDate!.day}-${selectedAppointmentDate!.month}-${selectedAppointmentDate!.year}",
                ),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Time Slot"),
                items: timeSlots.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTime = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: heroIdController,
                decoration: const InputDecoration(
                  labelText: "Enter Blood Hero ID",
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: saveDonation,
                  child: const Text("Book Appointment"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}