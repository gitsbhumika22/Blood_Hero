import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController fullAddressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  DateTime? selectedDOB;
  String ageDisplay = "";
  String? selectedState;
  String? selectedBloodGroup;

  bool isLoading = false;
  bool useCurrentLocation = false;

  final FirebaseDatabase database = FirebaseDatabase.instance;

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-"
  ];

  final List<String> indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Delhi"
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    aadharController.dispose();
    areaController.dispose();
    cityController.dispose();
    fullAddressController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> pickDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDOB = picked;
        calculateAge();
      });
    }
  }

  void calculateAge() {
    if (selectedDOB == null) return;

    DateTime today = DateTime.now();

    int years = today.year - selectedDOB!.year;
    int months = today.month - selectedDOB!.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    ageDisplay = "$years Years $months Months";
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location services are disabled. Please enable them."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location permissions are denied"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions are permanently denied"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get the address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
        
        setState(() {
          fullAddressController.text = address;
          areaController.text = place.street ?? "";
          cityController.text = place.locality ?? "";
          
          // Set pincode if available
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            pincodeController.text = place.postalCode!;
          }
          
          // Set state to Maharashtra as requested
          selectedState = "Maharashtra";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location fetched successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> saveProfile() async {
    try {
      setState(() => isLoading = true);

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      String uid = user.uid;

      DatabaseReference ref = database.ref("users/$uid");

      Map<String, dynamic> data = {
        "uid": uid,
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "dob": selectedDOB?.toIso8601String() ?? "",
        "ageDisplay": ageDisplay,
        "aadhar": aadharController.text.trim(),
        "bloodGroup": selectedBloodGroup ?? "",
        "areaAddress": areaController.text.trim(),
        "city": cityController.text.trim(),
        "state": selectedState ?? "",
        "fullAddress": fullAddressController.text.trim(),
        "pincode": pincodeController.text.trim(),
        "imagePath": _image?.path ?? "",
        "updatedAt": DateTime.now().toString(),
      };

      await ref.set(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile Saved Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Save Error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Save Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loadProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      String uid = user.uid;

      DatabaseReference ref = database.ref("users/$uid");

      DatabaseEvent event = await ref.once();

      if (event.snapshot.value != null) {
        Map data =
        event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          nameController.text = data["name"] ?? "";
          emailController.text = data["email"] ?? "";
          aadharController.text = data["aadhar"] ?? "";
          areaController.text = data["areaAddress"] ?? "";
          cityController.text = data["city"] ?? "";
          selectedState = data["state"];
          selectedBloodGroup = data["bloodGroup"];
          fullAddressController.text = data["fullAddress"] ?? "";
          pincodeController.text = data["pincode"] ?? "";
          ageDisplay = data["ageDisplay"] ?? "";

          if (data["dob"] != null &&
              data["dob"].toString().isNotEmpty) {
            selectedDOB = DateTime.parse(data["dob"]);
          }

          if (data["imagePath"] != null &&
              data["imagePath"].toString().isNotEmpty) {
            _image = File(data["imagePath"]);
          }
        });
      }
    } catch (e) {
      debugPrint("Load Error: $e");
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget gap() => const SizedBox(height: 15);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.red,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.red.shade100,
                  backgroundImage:
                  _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(
                    Icons.camera_alt,
                    size: 35,
                    color: Colors.red,
                  )
                      : null,
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: nameController,
                decoration: inputDecoration("Full Name"),
              ),

              gap(),

              TextField(
                controller: emailController,
                decoration: inputDecoration("Email"),
              ),

              gap(),

              GestureDetector(
                onTap: pickDOB,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border:
                    Border.all(color: Colors.grey),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedDOB == null
                        ? "Select Date of Birth"
                        : "${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}\n$ageDisplay",
                  ),
                ),
              ),

              gap(),

              TextField(
                controller: aadharController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: "Aadhar Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  counterText: "12 digits required",
                  hintText: "Enter 12-digit Aadhar number",
                ),
                onChanged: (value) {
                  // Only allow numbers and limit to 12 digits
                  if (value.length > 12) {
                    aadharController.text = value.substring(0, 12);
                    aadharController.selection = TextSelection.fromPosition(
                      TextPosition(offset: aadharController.text.length),
                    );
                  }
                },
              ),

              gap(),

              DropdownButtonFormField<String>(
                value: selectedBloodGroup,
                decoration:
                inputDecoration("Blood Group"),
                items: bloodGroups.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBloodGroup = value;
                  });
                },
              ),

              gap(),

              // Address Section with Geolocator
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: useCurrentLocation,
                          onChanged: (value) {
                            setState(() {
                              useCurrentLocation = value ?? false;
                              if (useCurrentLocation) {
                                _getCurrentLocation();
                              }
                            });
                          },
                          activeColor: Colors.red,
                        ),
                        const Text(
                          "Use Current Location",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.location_on, color: Colors.red),
                          tooltip: "Get Current Location",
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fullAddressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Full Address",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        hintText: "Enter your full address or use location",
                      ),
                    ),
                  ],
                ),
              ),

              gap(),

              TextField(
                controller: areaController,
                decoration:
                inputDecoration("Area Address"),
              ),

              gap(),

              TextField(
                controller: cityController,
                decoration: inputDecoration("City"),
              ),

              gap(),

              TextField(
                controller: pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: "Pincode",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  counterText: "6 digits",
                  hintText: "Enter 6-digit pincode",
                ),
                onChanged: (value) {
                  // Only allow numbers and limit to 6 digits
                  if (value.length > 6) {
                    pincodeController.text = value.substring(0, 6);
                    pincodeController.selection = TextSelection.fromPosition(
                      TextPosition(offset: pincodeController.text.length),
                    );
                  }
                },
              ),

              gap(),

              DropdownButtonFormField<String>(
                value: selectedState,
                decoration: inputDecoration("State"),
                items: indianStates.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedState = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                  isLoading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    "Save Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
