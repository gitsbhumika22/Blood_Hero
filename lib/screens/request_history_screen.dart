import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RequestHistoryScreen extends StatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  State<RequestHistoryScreen> createState() =>
      _RequestHistoryScreenState();
}

class _RequestHistoryScreenState
    extends State<RequestHistoryScreen> {

  final db = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> requestHistory = [];

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  void fetchHistory() async {
    final snapshot =
    await db.child("blood_requests").get();

    if (!snapshot.exists) return;

    final data =
    Map<String, dynamic>.from(snapshot.value as Map);

    List<Map<String, dynamic>> temp = [];

    data.forEach((key, value) {
      final request =
      Map<String, dynamic>.from(value);

      if (request["uid"] == user!.uid) {
        request["key"] = key; // Add the key for reference
        temp.add(request);
      }
    });

    setState(() {
      requestHistory = temp.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // same as request screen

      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          "My Blood Requests",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: requestHistory.isEmpty
            ? const Center(
          child: Text(
            "No Requests Found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        )
            : ListView.builder(
          itemCount: requestHistory.length,
          itemBuilder: (context, index) {
            final request =
            requestHistory[index];

            return Container(
              margin:
              const EdgeInsets.only(bottom: 15),
              padding:
              const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(15),
                border: Border.all(
                    color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  const Icon(
                    Icons.bloodtype,
                    color: Colors.red,
                    size: 35,
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Blood Group: ${request["bloodGroup"]}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "Patient: ${request["patientName"]} (${request["patientAge"]} years)",
                        ),

                        Text(
                          "Location: ${request["fullAddress"]?.isNotEmpty == true ? request["fullAddress"] : "${request["city"]}, ${request["state"]}"}",
                        ),

                        const SizedBox(height: 5),

                        /// Status Badge
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5),
                          decoration: BoxDecoration(
                            color: request["status"] ==
                                "Active"
                                ? Colors.green
                                .shade100
                                : request["status"] == "Accepted"
                                ? Colors.blue.shade100
                                : Colors.grey.shade300,
                            borderRadius:
                            BorderRadius.circular(
                                20),
                          ),
                          child: Text(
                            request["status"],
                            style: TextStyle(
                              color: request["status"] ==
                                  "Active"
                                  ? Colors.green
                                  : request["status"] == "Accepted"
                                  ? Colors.blue
                                  : Colors.black54,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),

                        /// Show Donor Information if Accepted
                        if (request["status"] == "Accepted" && request["acceptedByName"] != null) ...[
                          const SizedBox(height: 10),
                          
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 5),
                                    const Text(
                                      "Donor Found!",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text("Donor: ${request["acceptedByName"]} (${request["acceptedByBloodGroup"]})"),
                                Text("Contact: ${request["acceptedByPhone"]}"),
                                if (request["acceptedAt"] != null)
                                  Text(
                                    "Accepted on: ${request["acceptedAt"]}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                
                                // Show donation hospital and slot if available
                                if (request["donationHospital"] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.local_hospital, color: Colors.blue, size: 16),
                                            const SizedBox(width: 5),
                                            const Text(
                                              "Donation Details",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text("Hospital: ${request["donationHospital"]}"),
                                        if (request["donationHospitalAddress"] != null)
                                          Text(
                                            "Address: ${request["donationHospitalAddress"]}",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        if (request["donationHospitalCity"] != null && request["donationHospitalState"] != null)
                                          Text(
                                            "Location: ${request["donationHospitalCity"]}, ${request["donationHospitalState"]}",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        if (request["donationDate"] != null)
                                          Text(
                                            "Date: ${request["donationDate"]}",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        if (request["donationTimeSlot"] != null)
                                          Text(
                                            "Time: ${request["donationTimeSlot"]}",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        if (request["donationHospitalPhone"] != null)
                                          Text(
                                            "Hospital Phone: ${request["donationHospitalPhone"]}",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 5),
                                Text(
                                  request["donationConfirmed"] == true 
                                    ? "Donation confirmed! Please visit the hospital at the scheduled time."
                                    : "The donor will contact you soon to arrange the blood donation.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}