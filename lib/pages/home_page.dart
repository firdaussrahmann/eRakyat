import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart'; // Import Local Auth package
import 'package:authenticationapp2/pages/profile_page.dart';
import 'package:authenticationapp2/auth/geolocation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _isAuthenticated = false; // Track if user is authenticated
  bool _isBiometricVerified = false; // Track if biometric is verified

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth =
      LocalAuthentication(); // Local Auth instance

  final List<Widget> _pages = [
    const HomeScreen(),
    const ServicesPage(),
    const NotificationsPage(),
    // Profile Page will only be shown after biometric verification
    // Placeholder Profile page; will be dynamically replaced after authentication
    const SizedBox
        .shrink(), // Empty widget, as Profile page should not load initially
  ];

  final List<String> _titles = [
    "Home",
    "Services",
    "Notifications",
    "Profile",
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus(); // Check authentication on app start
  }

  // Check if user is authenticated when app starts
  Future<void> _checkAuthenticationStatus() async {
    final savedToken = await _secureStorage.read(key: 'user_token');
    if (savedToken != null) {
      setState(() {
        _isAuthenticated =
            true; // User is authenticated, no need for biometric check
      });
    }
  }

  // Logout logic
  Future<void> logout() async {
    await _secureStorage.delete(key: 'user_token'); // Clear token
    await FirebaseAuth.instance.signOut(); // Firebase sign out

    setState(() {
      _isAuthenticated = false; // User is no longer authenticated
      _isBiometricVerified = false; // Reset biometric status
    });

    Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page
  }

  // Trigger biometric authentication when Profile page button is pressed
  Future<void> _authenticateWithBiometrics() async {
    try {
      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your profile',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (isAuthenticated) {
        // After successful biometric authentication, update the status
        setState(() {
          _isBiometricVerified = true; // Mark as biometric verified
          _currentIndex = 3; // Switch to Profile tab
        });
      } else {
        // Handle unsuccessful authentication attempt
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication failed.')),
        );
      }
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error during authentication.')),
      );
    }
  }

  // Handle accessing private space based on geolocation
  Future<void> _handlePrivateSpace() async {
    setState(() => _isAuthenticated = true);

    try {
      final isInMalaysia = await Geolocation().isUserInMalaysia();

      if (isInMalaysia) {
        Navigator.pushNamed(context, '/secretpage');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be in Malaysia to access this space.')),
        );
      }
    } catch (e) {
      debugPrint('Error during geolocation check: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error checking location.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
        title: Text(
          _titles[_currentIndex],
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _isBiometricVerified
            ? [
                const HomeScreen(),
                const ServicesPage(),
                const NotificationsPage(),
                const ProfilePage(
                    scannedData: {}), // Only show Profile Page after biometric verification
              ]
            : _pages, // Only show a placeholder for Profile Page before authentication
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.orangeAccent,
        indicatorColor: const Color(0xFFFFFFFF),
        height: 75,
        elevation: 0.0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.room_service_sharp), label: 'Services'),
          NavigationDestination(
              icon: Icon(Icons.notifications), label: 'Notifications'),
          NavigationDestination(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          // If the Profile page is selected, trigger biometric authentication
          if (index == 3 && !_isBiometricVerified) {
            _authenticateWithBiometrics();
          }
        },
        selectedIndex: _currentIndex,
      ),
    );
  }

  // Drawer widget with logout functionality
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.orangeAccent,
      elevation: 100.00,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('User Name'),
            accountEmail: Text('user@example.com'),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.account_circle, size: 70),
            ),
            decoration: BoxDecoration(color: Colors.orangeAccent),
          ),
          _buildDrawerTile(
            icon: Icons.privacy_tip_rounded,
            label: 'Private Space',
            onTap: _handlePrivateSpace,
          ),
          _buildDrawerTile(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildDrawerTile(
            icon: Icons.logout,
            label: 'Logout',
            onTap: logout,
          ),
        ],
      ),
    );
  }

  // Drawer tile for private space, settings, logout
  ListTile _buildDrawerTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

// Dummy widgets for demonstration purposes
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carouselItems = [
      {
        'title': 'National ID Services',
        'subtitle': 'Manage your ID easily',
        'color': Colors.blue
      },
      {
        'title': 'Driving License',
        'subtitle': 'Renew your license in minutes',
        'color': Colors.green
      },
      {
        'title': 'Passport Renewal',
        'subtitle': 'Hassle-free passport services',
        'color': Colors.orange
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Carousel
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: carouselItems.length,
              controller: PageController(viewportFraction: 0.9),
              itemBuilder: (context, index) {
                final item = carouselItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Card(
                    color: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4169E1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search for services...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Notifications Page', style: TextStyle(color: Colors.white)),
    );
  }
}
