import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'request_history_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';

class RequestBloodScreen extends StatefulWidget {
  const RequestBloodScreen({super.key});

  @override
  State<RequestBloodScreen> createState() => _RequestBloodScreenState();
}

class _RequestBloodScreenState extends State<RequestBloodScreen> {

  final db = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>();

  String bloodGroup = "";
  String patientName = "";
  String patientAge = "";
  String city = "";
  String state = "";
  String phone = "";
  String alternatePhone = "";
  String fullAddress = "";
  bool useCurrentLocation = false;
  bool isLoadingLocation = false;

  List<String> bloodGroups = [
    "A+","A-","B+","B-","O+","O-","AB+","AB-"
  ];

  /// ================= GET CURRENT LOCATION =================
  Future<void> getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          city = place.locality ?? "";
          state = place.administrativeArea ?? "";
          fullAddress = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}";
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location fetched successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error getting location: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<void> submitRequest() async {
    if (_formKey.currentState!.validate()) {

      final userSnapshot =
      await db.child("users/${user!.uid}").get();

      String requesterName = "";

      if (userSnapshot.exists) {
        final data =
        Map<String, dynamic>.from(userSnapshot.value as Map);
        requesterName = data["name"] ?? "";
      }

      // Create the blood request
      final requestRef = await db.child("blood_requests").push();
      final requestId = requestRef.key;

      await requestRef.set({
        "uid": user!.uid,
        "requesterName": requesterName,
        "bloodGroup": bloodGroup,
        "patientName": patientName,
        "patientAge": patientAge,
        "city": city,
        "state": state,
        "phone": phone,
        "alternatePhone": alternatePhone,
        "fullAddress": fullAddress,
        "useCurrentLocation": useCurrentLocation,
        "timestamp": DateTime.now().toString(),
        "status": "Active"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Blood Request Submitted Successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          "Request Blood",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          /// 🕘 History Icon
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RequestHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Blood Group",
                        border: OutlineInputBorder(),
                      ),
                      items: bloodGroups.map((group) {
                        return DropdownMenuItem(
                          value: group,
                          child: Text(group),
                        );
                      }).toList(),
                      onChanged: (value) => bloodGroup = value!,
                      validator: (value) =>
                      value == null ? "Select blood group" : null,
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Patient Name",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => patientName = value,
                      validator: (value) =>
                      value!.isEmpty ? "Enter patient name" : null,
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Patient Age",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => patientAge = value,
                      validator: (value) =>
                      value!.isEmpty ? "Enter patient age" : null,
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(),
                        hintText: "Enter 10-digit mobile number",
                      ),
                      onChanged: (value) => phone = value,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter phone number";
                        }
                        if (value.length != 10) {
                          return "Phone number must be exactly 10 digits";
                        }
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                          return "Enter valid Indian mobile number";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Alternate Phone Number (Optional)",
                        border: OutlineInputBorder(),
                        hintText: "Enter 10-digit mobile number",
                      ),
                      onChanged: (value) => alternatePhone = value,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 10) {
                            return "Phone number must be exactly 10 digits";
                          }
                          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                            return "Enter valid Indian mobile number";
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    /// ================= LOCATION SELECTION =================
                    const Text(
                      "Location Selection",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// Use Current Location Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: useCurrentLocation,
                          onChanged: (value) {
                            setState(() {
                              useCurrentLocation = value!;
                              if (value) {
                                getCurrentLocation();
                              }
                            });
                          },
                          activeColor: Colors.red,
                        ),
                        const Text("Use Current Location"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// Get Location Button
                    if (useCurrentLocation)
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoadingLocation ? null : getCurrentLocation,
                          icon: isLoadingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.location_on),
                          label: Text(isLoadingLocation ? "Getting Location..." : "Get Current Location"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                    if (useCurrentLocation && fullAddress.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Location Address:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(fullAddress),
                          ],
                        ),
                      ),

                    const SizedBox(height: 15),

                    /// Manual Address Fields (shown when not using current location)
                    if (!useCurrentLocation) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "City",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => city = value,
                        validator: (value) =>
                        value!.isEmpty ? "Enter city" : null,
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "State",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => state = value,
                        validator: (value) =>
                        value!.isEmpty ? "Enter state" : null,
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Full Address (Optional)",
                          border: OutlineInputBorder(),
                          hintText: "Street address, landmark, etc.",
                        ),
                        onChanged: (value) => fullAddress = value,
                        maxLines: 2,
                      ),
                    ],

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          "Submit Blood Request",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}