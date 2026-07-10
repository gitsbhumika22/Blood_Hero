import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HospitalSelectionScreen extends StatefulWidget {
  final String bloodRequestKey;
  final Map<String, dynamic> requestData;
  final String userCity;
  final String userState;

  const HospitalSelectionScreen({
    super.key,
    required this.bloodRequestKey,
    required this.requestData,
    required this.userCity,
    required this.userState,
  });

  @override
  State<HospitalSelectionScreen> createState() => _HospitalSelectionScreenState();
}

class _HospitalSelectionScreenState extends State<HospitalSelectionScreen> {
  final db = FirebaseDatabase.instance.ref();
  
  List<Map<String, dynamic>> hospitals = [];
  List<Map<String, dynamic>> filteredHospitals = [];
  bool isLoading = true;
  
  String selectedCity = '';
  String selectedState = '';
  TextEditingController searchController = TextEditingController();

  // List of states for filtering (unique values only)
  final List<String> states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'West Bengal', 'Delhi', 'Jammu & Kashmir'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with empty values to avoid dropdown errors
    selectedCity = '';
    selectedState = '';
    fetchHospitals();
    searchController.addListener(filterHospitals);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchHospitals() async {
    setState(() => isLoading = true);
    
    // Sample hospital data - in real app, this would come from database
    final sampleHospitals = [
      {
        'name': 'Apollo Hospitals',
        'address': 'Jubilee Hills, Hyderabad',
        'city': 'Hyderabad',
        'state': 'Telangana',
        'phone': '+91-40-23607777',
        'bloodBankAvailable': true,
        'rating': 4.5,
      },
      {
        'name': 'AIIMS',
        'address': 'Ansari Nagar, New Delhi',
        'city': 'New Delhi',
        'state': 'Delhi',
        'phone': '+91-11-26588500',
        'bloodBankAvailable': true,
        'rating': 4.8,
      },
      {
        'name': 'Lilavati Hospital',
        'address': 'Bandra West, Mumbai',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'phone': '+91-22-26455000',
        'bloodBankAvailable': true,
        'rating': 4.6,
      },
      {
        'name': 'Fortis Hospital',
        'address': 'Cunningham Road, Bangalore',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'phone': '+91-80-66214444',
        'bloodBankAvailable': true,
        'rating': 4.4,
      },
      {
        'name': 'Christian Medical College',
        'address': 'Vellore',
        'city': 'Vellore',
        'state': 'Tamil Nadu',
        'phone': '+91-416-2281000',
        'bloodBankAvailable': true,
        'rating': 4.7,
      },
      {
        'name': 'SGPGI',
        'address': 'Lucknow',
        'city': 'Lucknow',
        'state': 'Uttar Pradesh',
        'phone': '+91-522-2494000',
        'bloodBankAvailable': true,
        'rating': 4.5,
      },
      {
        'name': 'PGIMER',
        'address': 'Chandigarh',
        'city': 'Chandigarh',
        'state': 'Chandigarh',
        'phone': '+91-172-2747585',
        'bloodBankAvailable': true,
        'rating': 4.6,
      },
      {
        'name': 'Tata Memorial Hospital',
        'address': 'Parel, Mumbai',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'phone': '+91-22-24177000',
        'bloodBankAvailable': true,
        'rating': 4.7,
      },
      {
        'name': 'Sir Ganga Ram Hospital',
        'address': 'Old Rajendra Nagar, New Delhi',
        'city': 'New Delhi',
        'state': 'Delhi',
        'phone': '+91-11-25861000',
        'bloodBankAvailable': true,
        'rating': 4.4,
      },
      {
        'name': 'Medanta - The Medicity',
        'address': 'Gurgaon',
        'city': 'Gurgaon',
        'state': 'Haryana',
        'phone': '+91-124-4855222',
        'bloodBankAvailable': true,
        'rating': 4.5,
      },
    ];

    setState(() {
      hospitals = sampleHospitals;
      filteredHospitals = sampleHospitals;
      isLoading = false;
    });
    
    filterHospitals();
  }

  void filterHospitals() {
    setState(() {
      filteredHospitals = hospitals.where((hospital) {
        bool matchesCity = selectedCity.isEmpty || hospital['city'].toString().toLowerCase().contains(selectedCity.toLowerCase());
        bool matchesState = selectedState.isEmpty || hospital['state'].toString().toLowerCase().contains(selectedState.toLowerCase());
        bool matchesSearch = searchController.text.isEmpty || 
            hospital['name'].toString().toLowerCase().contains(searchController.text.toLowerCase()) ||
            hospital['address'].toString().toLowerCase().contains(searchController.text.toLowerCase());
        
        return matchesCity && matchesState && matchesSearch;
      }).toList();
    });
  }

  void onHospitalSelected(Map<String, dynamic> hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlotSelectionScreen(
          bloodRequestKey: widget.bloodRequestKey,
          requestData: widget.requestData,
          selectedHospital: hospital,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          "Select Hospital",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search hospitals...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // City and State Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCity.isEmpty ? null : selectedCity,
                        decoration: InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [''].followedBy(hospitals.map((h) => h['city'].toString()).toSet().toList()).map((city) {
                          return DropdownMenuItem(
                            value: city.isEmpty ? '' : city,
                            child: Text(city.isEmpty ? 'All Cities' : city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCity = value ?? '';
                          });
                          filterHospitals();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedState.isEmpty ? null : selectedState,
                        decoration: InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [''].followedBy(states).map((state) {
                          return DropdownMenuItem(
                            value: state.isEmpty ? '' : state,
                            child: Text(state.isEmpty ? 'All States' : state),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedState = value ?? '';
                          });
                          filterHospitals();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Hospitals List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHospitals.isEmpty
                    ? const Center(
                        child: Text(
                          'No hospitals found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHospitals.length,
                        itemBuilder: (context, index) {
                          final hospital = filteredHospitals[index];
                          return HospitalCard(
                            hospital: hospital,
                            onTap: () => onHospitalSelected(hospital),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final VoidCallback onTap;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_hospital, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hospital['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hospital['bloodBankAvailable'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Blood Bank',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hospital['address'],
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${hospital['city']}, ${hospital['state']}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.grey.shade600, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    hospital['phone'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        hospital['rating'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Slot Selection Screen
class SlotSelectionScreen extends StatefulWidget {
  final String bloodRequestKey;
  final Map<String, dynamic> requestData;
  final Map<String, dynamic> selectedHospital;

  const SlotSelectionScreen({
    super.key,
    required this.bloodRequestKey,
    required this.requestData,
    required this.selectedHospital,
  });

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  final db = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;
  
  List<Map<String, dynamic>> availableSlots = [];
  bool isLoading = true;
  String? selectedSlot;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchAvailableSlots();
  }

  Future<void> fetchAvailableSlots() async {
    // Generate sample time slots for the next 7 days
    final List<Map<String, dynamic>> slots = [];
    final now = DateTime.now();
    
    for (int day = 0; day < 7; day++) {
      final date = now.add(Duration(days: day));
      
      // Generate time slots from 9 AM to 6 PM
      for (int hour = 9; hour <= 18; hour++) {
        // Skip lunch break (1-2 PM)
        if (hour == 13) continue;
        
        final timeSlot = '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00';
        
        slots.add({
          'date': date,
          'timeSlot': timeSlot,
          'dateTime': DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            0,
          ),
          'available': true, // In real app, check actual availability
        });
      }
    }

    setState(() {
      availableSlots = slots;
      isLoading = false;
    });
  }

  void confirmDonation() async {
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a donation slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedSlotData = availableSlots.firstWhere(
      (slot) => slot['timeSlot'] == selectedSlot,
    );

    // Get current user's details
    final userSnapshot = await db.child("users/${user!.uid}").get();
    String donorName = "";
    String donorBloodGroup = "";
    String donorPhone = "";

    if (userSnapshot.exists) {
      final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      donorName = userData["name"] ?? "";
      donorBloodGroup = userData["bloodGroup"] ?? "";
      donorPhone = userData["phone"] ?? "";
    }

    // Update the blood request with hospital, slot, and donor information
    await db.child("blood_requests/${widget.bloodRequestKey}").update({
      "status": "Accepted",
      "acceptedBy": user!.uid,
      "acceptedByName": donorName,
      "acceptedByBloodGroup": donorBloodGroup,
      "acceptedByPhone": donorPhone,
      "acceptedAt": DateTime.now().toString(),
      "donationHospital": widget.selectedHospital['name'],
      "donationHospitalAddress": widget.selectedHospital['address'],
      "donationHospitalCity": widget.selectedHospital['city'],
      "donationHospitalState": widget.selectedHospital['state'],
      "donationHospitalPhone": widget.selectedHospital['phone'],
      "donationDate": selectedSlotData['dateTime'].toString(),
      "donationTimeSlot": selectedSlotData['timeSlot'],
      "donationConfirmed": true,
      "donationConfirmedAt": DateTime.now().toString(),
    });

    // Show success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Donation slot confirmed! The requester will be notified."),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          "Select Donation Slot",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Hospital Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Hospital',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.selectedHospital['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.selectedHospital['address'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${widget.selectedHospital['city']}, ${widget.selectedHospital['state']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Date Selection
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = selectedDate.day == date.day && 
                                       selectedDate.month == date.month && 
                                       selectedDate.year == date.year;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = date;
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.red : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Time Slots
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Time Slots',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = availableSlots[index];
                              final slotDate = slot['date'] as DateTime;
                              final isSelected = selectedSlot == slot['timeSlot'] &&
                                             selectedDate.day == slotDate.day &&
                                             selectedDate.month == slotDate.month &&
                                             selectedDate.year == slotDate.year;
                              
                              // Only show slots for selected date
                              if (selectedDate.day != slotDate.day ||
                                  selectedDate.month != slotDate.month ||
                                  selectedDate.year != slotDate.year) {
                                return const SizedBox.shrink();
                              }
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedSlot = slot['timeSlot'];
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.red : Colors.white,
                                    border: Border.all(
                                      color: isSelected ? Colors.red : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slot['timeSlot'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Confirm Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: confirmDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Confirm Donation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
