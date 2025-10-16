import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sankalp',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            backgroundColor: Colors.indigo.shade600,
            elevation: 8,
            shadowColor: Colors.indigo.withOpacity(0.5),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 32,
            letterSpacing: 0.5,
            fontFamily: 'Roboto',
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            letterSpacing: 0.3,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (context) => const LoginScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
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
          // Decorative Elements
          CustomPaint(
            size: Size.infinite,
            painter: BubblesPainter(),
          ),
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with gradient border
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
                      // Main Title
                      Text(
                        "Empowering Local\nGovernance",
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      Text(
                        "Make You Aware!!",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 60),
                      // Enhanced Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.shade900.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          icon: const Icon(Icons.arrow_forward,
                              color: Colors.white),
                          label: const Text(
                            "Get Started",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 15),
                            backgroundColor: Colors.indigo.shade600,
                            elevation: 8,
                            shadowColor: Colors.indigo.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
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
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.5),
      30,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.7),
      70,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
