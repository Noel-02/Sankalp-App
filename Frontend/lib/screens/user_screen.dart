import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'chatbot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'certi_bot.dart';
import 'history.dart';
import 'complaint.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SankalpApp());
}

class SankalpApp extends StatelessWidget {
  const SankalpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sankalp',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
              fontSize: 16, color: Colors.black87, fontFamily: 'CustomFont'),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'CustomFont',
          ),
          titleMedium: TextStyle(
              fontSize: 18, color: Colors.black87, fontFamily: 'CustomFont'),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: const SankalpUI(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SankalpUI extends StatefulWidget {
  const SankalpUI({super.key});

  @override
  _SankalpUIState createState() => _SankalpUIState();
}

class _SankalpUIState extends State<SankalpUI>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');
    if (storedUserId != null && storedUserId.isNotEmpty) {
      setState(() {
        userId = storedUserId;
      });
      print('Loaded User ID: $userId');
    } else {
      print('User ID not found in SharedPreferences.');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpg', height: 35),
            const SizedBox(width: 12),
            const Text(
              "Sankalp",
              style: TextStyle(
                fontFamily: 'CustomFont',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      drawer: buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[100]!, Colors.grey[50]!],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            buildChatbotTab(context),
            const Center(
                child: Text(
                    "Services Tab Content")), // Placeholder for Services Tab
          ],
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo, Colors.indigo.shade700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sankalp App',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'CustomFont',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.chat,
              title: 'Chat Bot',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.assignment,
              title: 'Apply Certificate',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ApplyCertificateScreen()),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.report_problem,
              title: 'Complaint Bot',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ComplaintScreen()),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: 'History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              ),
            ),
            const Divider(thickness: 1),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'CustomFont',
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.indigo.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget buildChatbotTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              kToolbarHeight - // AppBar height
              kBottomNavigationBarHeight - // TabBar height
              MediaQuery.of(context).padding.top - // Status bar
              MediaQuery.of(context).padding.bottom, // Bottom padding
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensure the Column doesn't expand
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Ensure the inner Column doesn't expand
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.support_agent,
                        size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Welcome to Sankalp Assistant",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "How can we help you today?",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildServiceCard(
              context: context,
              title: "Chat Assistant",
              description: "Get instant help with your queries",
              icon: Icons.chat_bubble_outline,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceCard(
              context: context,
              title: "Apply Certificate",
              description: "Apply for various certificates easily",
              icon: Icons.assignment_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ApplyCertificateScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceCard(
              context: context,
              title: "File Complaint",
              description: "Register and track your complaints",
              icon: Icons.report_problem_outlined,
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ComplaintScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6), // Add margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12), // Reduced padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reduced from 12
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 28, color: Colors.white), // Reduced from 32
              ),
              const SizedBox(width: 12), // Reduced from 16
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Add this
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16, // Reduced from 18
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'CustomFont',
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13, // Reduced from 14
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'CustomFont',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 16), // Reduced from 20
            ],
          ),
        ),
      ),
    );
  }
}
