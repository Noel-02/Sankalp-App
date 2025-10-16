import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart'; // For kIsWeb

class Admin1Page extends StatefulWidget {
  const Admin1Page({super.key});

  @override
  _CertificateListScreenState createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<Admin1Page> {
  List<Map<String, dynamic>> certificates = [];
  bool isLoading = true;
  String certificateType = 'Income Certificate';

  final ScrollController _scrollController = ScrollController();

  final List<String> certificateTypes = [
    'Income Certificate',
    'Land Certificate',
  ];

  final Map<String, List<String>> certificateAttributes = {
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

  Future<void> fetchCertificates() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:5500/fetch/fetch_application_status?certificate_type=$certificateType',
        ),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        List<Map<String, dynamic>> parsedCertificates = [];
        if (responseBody is Map && responseBody.containsKey('data')) {
          var data = responseBody['data'];
          if (data is List) {
            parsedCertificates = List<Map<String, dynamic>>.from(data);
          }
        }

        setState(() {
          certificates = parsedCertificates;
          isLoading = false;
        });
      } else {
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

  Map<String, dynamic> formatDataForPDF(
      Map<String, dynamic> applicationData, String certificateType) {
    Map<String, dynamic> formattedData = {
      'application_id': applicationData['application_id'].toString(),
      'certificate_type': certificateType,
    };

    switch (certificateType) {
      case 'Income Certificate':
        formattedData.addAll({
          'name': applicationData['name'] ?? '',
          'annual_income': applicationData['annual_income'] ?? '',
          'source_of_income': applicationData['source_of_income'] ?? '',
          'address': applicationData['address'] ?? '',
        });
        break;
      case 'Land Certificate':
        formattedData.addAll({
          'owner_name': applicationData['owner_name'] ?? '',
          'property_address': applicationData['property_address'] ?? '',
          'market_value': applicationData['market_value'] ?? '',
          'area_sqft': applicationData['area_sqft'] ?? '',
          'survey_number': applicationData['survey_number'] ?? '',
        });
        break;
    }

    return formattedData;
  }

  Future<void> generatePDF(
      int applicationId, Map<String, dynamic> applicationData) async {
    try {
      Map<String, dynamic> formattedData = formatDataForPDF(
          {...applicationData, 'application_id': applicationId.toString()},
          certificateType);

      print('Sending data to generate PDF: ${json.encode(formattedData)}');

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5500/certi_gen/generate_pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/pdf',
        },
        body: json.encode(formattedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
        fetchCertificates();
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
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
          const SizedBox(width: 20),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                                      attribute
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )),
                          const DataColumn(
                            label: Text(
                              'ACTIONS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        rows: certificates.map((certificate) {
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
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Generate PDF'),
                                      onPressed: () => generatePDF(
                                        certificate['application_id'],
                                        applicationData,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.visibility),
                                      label: const Text('View PDF'),
                                      onPressed: () => viewPDF(
                                        certificate['application_id'],
                                        certificate['certificate_type'],
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
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
    _scrollController.dispose();
    super.dispose();
  }
}
