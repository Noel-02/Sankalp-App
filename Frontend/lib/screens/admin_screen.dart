import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: constraints.maxWidth < 600 ? 1 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  context,
                  'New Admin Registration',
                  Icons.admin_panel_settings,
                  Colors.blue,
                  const AdminUsersView(),
                ),
                _buildDashboardCard(
                  context,
                  'Upload New Scheme Data',
                  Icons.upload_file,
                  Colors.orange,
                  const UploadPDFView(),
                ),
                _buildDashboardCard(
                  context,
                  'View Complaints',
                  Icons.report_problem,
                  Colors.red,
                  const ComplaintsView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon,
      Color color, Widget destination) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  _AdminUsersViewState createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final String _selectedRole = 'admin'; // Fixed role as admin

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> registerAdmin() async {
    final userId = _usernameController.text;
    final password = _passwordController.text;
    final mobile = _mobileController.text;
    final email = _emailController.text;

    if (userId.isNotEmpty &&
        password.isNotEmpty &&
        mobile.isNotEmpty &&
        email.isNotEmpty &&
        (mobile.length == 10)) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5500/login/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'password': password,
            'mobile': mobile,
            'email': email,
            'role': _selectedRole,
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin registration successful!')),
          );
          Navigator.pop(context);
        } else {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Registration failed')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly.')),
      );
    }
  }

  void _showRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Icon(
                Icons.person_add_alt_1,
                size: 50,
                color: Colors.indigo,
              ),
              const SizedBox(height: 10),
              Text(
                'Register New Admin',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.indigo),
                    prefixIcon: Icon(Icons.person, color: Colors.indigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.indigo),
                    prefixIcon: Icon(Icons.email, color: Colors.indigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo, width: 2.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.indigo),
                    prefixIcon: Icon(Icons.lock, color: Colors.indigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo, width: 2.0),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _mobileController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: TextStyle(color: Colors.indigo),
                    prefixIcon: Icon(Icons.phone, color: Colors.indigo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.indigo, width: 2.0),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    border: Border.all(color: Colors.indigo),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_ind, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Text(
                        'Role: ',
                        style: TextStyle(color: Colors.indigo),
                      ),
                      Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.indigo),
              ),
            ),
            ElevatedButton(
              onPressed: registerAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 5,
              ),
              child: const Text(
                'Register Admin',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Registration',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRegistrationDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 100,
              color: Colors.indigo.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Register New Admin Users',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Click the + button to add a new admin user',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadPDFView extends StatefulWidget {
  const UploadPDFView({super.key});

  @override
  _UploadPDFViewState createState() => _UploadPDFViewState();
}

class _UploadPDFViewState extends State<UploadPDFView> {
  String _uploadStatus = "";
  bool _isUploading = false;
  String? _fileName;

  Future<void> uploadPDF() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = "Selecting file...";
    });

    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

      if (result != null) {
        setState(() => _uploadStatus = "Uploading file...");

        final file = result.files.single;
        final url = Uri.parse('http://127.0.0.1:5500/sample/pdf');
        final request = http.MultipartRequest('POST', url);

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        if (response.statusCode == 200) {
          setState(() {
            _uploadStatus =
                'Upload Successful: ${data['filename'] ?? 'Unknown'}';
          });
        } else {
          setState(() {
            _uploadStatus = 'Upload Failed: ${response.statusCode}';
          });
        }
      } else {
        setState(() {
          _uploadStatus = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload PDF',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          color: Colors.grey,
          elevation: 6,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_upload, size: 72, color: Colors.indigo),
                const SizedBox(height: 20),
                Text(
                  'Select a PDF file to upload',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_isUploading)
                  const CircularProgressIndicator(color: Colors.indigo)
                else
                  ElevatedButton.icon(
                    onPressed: uploadPDF,
                    icon: const Icon(Icons.upload_file,
                        color: Colors.white), // Set icon color to white
                    label: const Text('Choose File',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (_fileName != null)
                  Text(
                    'Selected: $_fileName',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                const SizedBox(height: 16),
                if (_uploadStatus.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _uploadStatus.contains('Successful')
                          ? Colors.green.withOpacity(0.1)
                          : _uploadStatus.contains('Error') ||
                                  _uploadStatus.contains('Failed')
                              ? Colors.red.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _uploadStatus,
                      style: TextStyle(
                        color: _uploadStatus.contains('Successful')
                            ? Colors.green
                            : _uploadStatus.contains('Error') ||
                                    _uploadStatus.contains('Failed')
                                ? Colors.red
                                : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ComplaintsView extends StatefulWidget {
  const ComplaintsView({super.key});

  @override
  _ComplaintsViewState createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
  List<Map<String, dynamic>> _complaintHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaintHistory();
  }

  Future<void> _fetchComplaintHistory() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5500/fetch/get_complaint'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> historyData = responseData['data'];

        setState(() {
          _complaintHistory = List<Map<String, dynamic>>.from(historyData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Failed to load complaint history: ${response.statusCode}');
        _showError('Failed to load complaint history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Network error occurred: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                MaterialStateProperty.all(Colors.indigo.withOpacity(0.1)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Complaints'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildComplaintTable(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
