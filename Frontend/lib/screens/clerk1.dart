import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // For shimmer effect
import 'package:flutter_spinkit/flutter_spinkit.dart'; // For loading spinner

class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  _CertificateListScreenState createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  List<Map<String, dynamic>> certificates = [];
  bool isLoading = true;
  String certificateType = 'Income Certificate';
  Map<String, String> certificateStatuses = {};
  final TextEditingController _remarksController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<String> certificateTypes = [
    'Birth Certificate',
    'Death Certificate',
    'Income Certificate',
    'Land Certificate',
  ];

  final Map<String, List<String>> certificateAttributes = {
    "Birth Certificate": [
      "full_name",
      "date_of_birth",
      "place_of_birth",
      "fathers_name",
      "mothers_name"
    ],
    'Death Certificate': [
      'name',
      'date_of_death',
      'place_of_death',
      'cause_of_death',
    ],
    'Income Certificate': [
      'name',
      'annual_income',
      'source_of_income',
      'address'
    ],
    'Land Certificate': [
      'owner_name',
      'property_address',
      'market_value',
      'area_sqft',
      'survey_number'
    ],
  };

  @override
  void initState() {
    super.initState();
    fetchCertificates();
  }

  Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> fetchCertificates() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:5500/fetch/fetch_application_data?certificate_type=$certificateType',
        ),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        print('Raw API Response: $responseBody');

        List<Map<String, dynamic>> parsedCertificates = [];
        if (responseBody is Map && responseBody.containsKey('data')) {
          var data = responseBody['data'];
          if (data is List) {
            parsedCertificates = List<Map<String, dynamic>>.from(data);
          }
        }

        Map<String, String> newStatuses = {};
        for (var cert in parsedCertificates) {
          String id = cert['application_id']?.toString() ?? '';
          print('Found ID: $id for certificate: $cert');
          newStatuses[id] = cert['status']?.toString() ?? 'Pending';
        }

        setState(() {
          certificates = parsedCertificates;
          certificateStatuses = newStatuses;
          isLoading = false;
        });
      } else {
        print('Error Response: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to fetch certificates. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching certificates: $e');
      setState(() {
        certificates = [];
        isLoading = false;
      });
    }
  }

  Future<void> showRemarksDialog(String certificateId) async {
    _remarksController.clear();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Enter Rejection Remarks',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _remarksController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _remarksController.clear();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_remarksController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter remarks')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                await submitRemarks(certificateId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitRemarks(String certificateId) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5500/fetch/update_remarks'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'certificateId': certificateId,
          'remarks': _remarksController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        await updateCertificateStatus(certificateId, 'reject');
        _remarksController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Remarks submitted successfully')),
          );
        }
      } else {
        throw Exception('Failed to submit remarks');
      }
    } catch (e) {
      print('Error submitting remarks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting remarks: $e')),
        );
      }
    }
  }

  Future<void> updateCertificateStatus(
      String certificateId, String action) async {
    if (certificateId.isEmpty) {
      print('Error: Certificate ID is empty.');
      return;
    }

    try {
      final requestBody = {
        'certificateId': certificateId,
        'action': action,
      };

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5500/fetch/update_certificate_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        setState(() {
          certificateStatuses[certificateId] =
              action == 'approve' ? 'Approved' : 'Rejected';
        });
        print('Successfully updated certificate status');
      } else {
        print('Failed to update certificate status: ${response.body}');
      }
    } catch (e) {
      print('Error updating certificate status: $e');
    }
  }

  Widget buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white,
              ),
              title: Container(
                width: double.infinity,
                height: 16.0,
                color: Colors.white,
              ),
              subtitle: Container(
                width: double.infinity,
                height: 12.0,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildLoadingSpinner() {
    return Center(
      child: SpinKitFadingCircle(
        color: Colors.indigo,
        size: 50.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '$certificateType List',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'CustomFont', // Use a custom font if available
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.indigo, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: certificateType,
              icon: const Icon(Icons.arrow_downward, color: Colors.white),
              dropdownColor: Colors.white,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    certificateType = newValue;
                  });
                  fetchCertificates();
                }
              },
              items: certificateTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: isLoading
          ? buildLoadingSpinner()
          : certificates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No certificates found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.indigoAccent,
                        ),
                        columns: [
                          ...certificateAttributes[certificateType]!
                              .map((attribute) => DataColumn(
                                    label: Text(
                                      attribute.replaceAll('_', ' '),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )),
                          const DataColumn(
                            label: Text(
                              'Action',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        rows: certificates.map((certificate) {
                          String certId =
                              certificate['application_id']?.toString() ?? '';
                          Map<String, dynamic> applicationData =
                              certificate['application_data'] ?? {};

                          return DataRow(
                            color: MaterialStateColor.resolveWith((states) {
                              return certificates.indexOf(certificate) % 2 == 0
                                  ? Colors.grey[100]!
                                  : Colors.white;
                            }),
                            cells: [
                              ...certificateAttributes[certificateType]!
                                  .map((attr) => DataCell(
                                        Text(
                                          applicationData[attr]?.toString() ??
                                              'N/A',
                                          style: const TextStyle(
                                              color: Colors.black87),
                                        ),
                                      )),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: certificateStatuses[certId] ==
                                              'Approved'
                                          ? null
                                          : () => updateCertificateStatus(
                                              certId, 'approve'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: certificateStatuses[certId] ==
                                                  'Approved'
                                              ? Colors.grey
                                              : Colors.green,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.check,
                                        color: certificateStatuses[certId] ==
                                                'Approved'
                                            ? Colors.grey
                                            : Colors.green,
                                      ),
                                      label: Text(
                                        'Approve',
                                        style: TextStyle(
                                          color: certificateStatuses[certId] ==
                                                  'Approved'
                                              ? Colors.grey
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: certificateStatuses[certId] ==
                                              'Rejected'
                                          ? null
                                          : () => showRemarksDialog(certId),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: certificateStatuses[certId] ==
                                                  'Rejected'
                                              ? Colors.grey
                                              : Colors.red,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.close,
                                        color: certificateStatuses[certId] ==
                                                'Rejected'
                                            ? Colors.grey
                                            : Colors.red,
                                      ),
                                      label: Text(
                                        'Reject',
                                        style: TextStyle(
                                          color: certificateStatuses[certId] ==
                                                  'Rejected'
                                              ? Colors.grey
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
