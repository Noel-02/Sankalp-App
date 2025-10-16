import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:io';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _certificateHistory = [];
  List<Map<String, dynamic>> _complaintHistory = [];
  bool _isLoading = true;
  bool _isComplaintLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserIdAndHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIdAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    if (userId != null) {
      await _fetchCertificateHistory();
      await _fetchComplaintHistory();
    }
  }

  Future<void> _fetchCertificateHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5500/fetch/get_certificate_history?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );

      print("Raw Response: ${response.body}"); // Debugging step

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> historyData = responseData['data'];

        print("Parsed History Data: $historyData"); // Check data structure

        setState(() {
          _certificateHistory = List<Map<String, dynamic>>.from(historyData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError(
            'Failed to load certificate history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Network error occurred: $e');
    }
  }

  Future<void> _fetchComplaintHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:5500/fetch/get_complaint_history?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );

      print("Raw Response: ${response.body}"); // Debugging step

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> historyData = responseData['data'];

        print("Parsed History Data: $historyData"); // Check data structure

        setState(() {
          _complaintHistory = List<Map<String, dynamic>>.from(historyData);
          _isComplaintLoading = false;
        });
      } else {
        setState(() {
          _isComplaintLoading = false;
        });
        _showError('Failed to load complaint history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isComplaintLoading = false;
      });
      _showError('Network error occurred: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCertificateTable() {
    if (_certificateHistory.isEmpty) {
      return const Center(child: Text("No applications found"));
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(Colors.indigo.withOpacity(0.1)),
            columns: const [
              DataColumn(
                  label: Text('Certificate Type',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Status',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _certificateHistory.map((certificate) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      certificate['certificate_type']
                              ?.toString()
                              .replaceAll('_', ' ') ??
                          'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                            certificate['status']?.toString() ?? 'pending'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        certificate['status']?.toString().toUpperCase() ??
                            'PENDING',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          color: Colors.indigo,
                          onPressed: () => _showCertificateDetails(certificate),
                        ),
                        if (certificate['status']?.toString().toLowerCase() ==
                            'approved')
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf),
                            color: Colors.red,
                            onPressed: () => viewPDF(
                              certificate['application_id'],
                              certificate['certificate_type'],
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
    );
  }

  Future<void> viewPDF(int applicationId, String certificateType) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5500/certi_gen/get_pdf'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'application_id': applicationId.toString(),
          'certificate_type': certificateType,
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        if (kIsWeb) {
          // Web implementation
          final blob = html.Blob([bytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', '${certificateType}_$applicationId.pdf')
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          // Mobile/Desktop implementation
          final directory = await getTemporaryDirectory();
          final file =
              File('${directory.path}/$certificateType\_$applicationId.pdf');
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
        }
      } else {
        throw Exception('Failed to fetch PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error handling PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling PDF: ${e.toString()}')),
      );
    }
  }

  Widget _buildComplaintTable() {
    if (_complaintHistory.isEmpty) {
      return const Center(child: Text("No complaints found"));
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(Colors.indigo.withOpacity(0.1)),
            columns: const [
              DataColumn(
                label: Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Phone',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Short Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: _complaintHistory.map((complaint) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      complaint['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  DataCell(
                    Text(
                      complaint['phone']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  DataCell(
                    Text(
                      complaint['short_description']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      color: Colors.indigo,
                      onPressed: () => _showComplaintDetails(complaint),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showCertificateDetails(Map<String, dynamic> certificate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Map<String, dynamic>? applicationData;

        try {
          if (certificate.containsKey('application_data')) {
            applicationData = certificate['application_data'] is String
                ? json.decode(certificate['application_data'])
                : certificate['application_data'];
          }
        } catch (e) {
          applicationData = {};
          print("Error decoding application_data: $e");
        }

        return AlertDialog(
          title: Text(
            '${certificate['certificate_type']?.toString().replaceAll('_', ' ')} Details',
            style: const TextStyle(color: Colors.indigo),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  'Status',
                  certificate['status']?.toString().toUpperCase() ?? 'PENDING',
                ),
                // Only show remarks if they exist and are not null
                if (certificate['remarks'] != null &&
                    certificate['remarks'].toString().isNotEmpty)
                  _buildDetailRow('Remarks', certificate['remarks'].toString()),
                const Divider(),
                const Text(
                  'Application Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildApplicationDetails(applicationData),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Complaint Details',
            style: TextStyle(color: Colors.indigo),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                    'Name', complaint['name']?.toString() ?? 'Unknown'),
                _buildDetailRow(
                    'Phone', complaint['phone']?.toString() ?? 'Unknown'),
                _buildDetailRow('Short Description',
                    complaint['short_description']?.toString() ?? 'Unknown'),
                _buildDetailRow('Full Complaint',
                    complaint['full_complaint']?.toString() ?? 'Unknown'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(color: Colors.black))),
        ],
      ),
    );
  }

  List<Widget> _buildApplicationDetails(Map<String, dynamic>? applicationData) {
    if (applicationData == null || applicationData.isEmpty) {
      return [
        const Text(
          "No additional details available.",
          style: TextStyle(color: Colors.black),
        )
      ];
    }

    return applicationData.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${entry.key}: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Expanded(
              child: Text(
                entry.value.toString(),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildComplaintDetails(Map<String, dynamic>? detailsData) {
    if (detailsData == null || detailsData.isEmpty) {
      return [
        const Text(
          "No additional details available.",
          style: TextStyle(color: Colors.black),
        )
      ];
    }

    return detailsData.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${entry.key}: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
            Expanded(
              child: Text(
                entry.value.toString(),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Application History'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.description),
                text: "Certificate Applications",
              ),
              Tab(
                icon: Icon(Icons.report_problem),
                text: "Complaint Applications",
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                // Wrap with SingleChildScrollView
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Certificate Applications',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo),
                            ),
                            const SizedBox(height: 16),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _buildCertificateTable(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                // Wrap with SingleChildScrollView
                child: Column(
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complaint Applications',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo),
                            ),
                            const SizedBox(height: 16),
                            _isComplaintLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _buildComplaintTable(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
