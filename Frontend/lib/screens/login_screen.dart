import 'package:flutter/material.dart';
import 'user_screen.dart';
import 'clerk1.dart';
import 'RegistrationPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin1.dart';
import 'admin2.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
  }

  Future<void> loginUser() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5500/login/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];

        if (data.containsKey('user_id') && data['user_id'] != null) {
          await saveUserId(data['user_id']);
        }

        if (userId == 'clerk1') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const CertificateListScreen()),
          );
        } else if (role == 'admin') {
          if (userId == 'admin1') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Admin1Page()),
            );
          } else if (userId == 'admin2') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Admin2Page()),
            );
          } else if (userId == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminScreen()),
            );
          } else {
            _showError('Invalid admin ID');
          }
        } else if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SankalpUI()),
          );
        } else {
          _showError('Invalid role');
        }
      } else {
        final data = jsonDecode(response.body);
        _showError(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade900,
                  Colors.indigo.shade600,
                  Colors.blue.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.2, 0.5, 1.0],
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: BubblesPainter(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.indigo.shade600
                                ],
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 65,
                                backgroundImage: AssetImage('assets/logo.jpg'),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Welcome to Sankalp',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login to continue',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _userIdController,
                            decoration: InputDecoration(
                              labelText: 'User ID',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: Colors.indigo.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                backgroundColor: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.5,
                              ),
                              labelStyle: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              floatingLabelStyle: TextStyle(
                                color: Colors.indigo.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                backgroundColor: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.5,
                              ),
                              labelStyle: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade600,
                                Colors.blue.shade400
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegistrationScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Create an Account',
                            style: TextStyle(
                              color: Colors.yellow.shade200,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class BubblesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      60,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      40,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.8),
      50,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
