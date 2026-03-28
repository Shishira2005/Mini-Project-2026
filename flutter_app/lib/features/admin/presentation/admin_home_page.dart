// Main admin dashboard with navigation to admin tools.
import 'package:flutter/material.dart';

import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/presentation/role_selection_page.dart';
import '../../auth/services/auth_api_service.dart';
import '../../../core/api/api_client.dart';
import '../../booking/presentation/admin_booking_page.dart';
import '../../booking/presentation/booking_history_page.dart';
import '../../booking/presentation/swap_history_page.dart';
import 'timetable_page.dart';
import 'blueprint_page.dart';
import 'student_accounts_page.dart';
import 'faculty_accounts_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key, required this.user});
  final AuthUser user;
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _bgIndex = 0;
  late final List<String> _bgImages;
  @override
  void initState() {
    super.initState();
    _bgImages = [
      'assets/LBS IMAGE.jpg',
      'assets/LBS IMAGE1.jpg',
      'assets/LBS IMAGE2.jpg',
      'assets/LBS IMAGE3.jpg',
    ];
    Future.microtask(_startSlideshow);
  }

  void _startSlideshow() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) break;
      setState(() {
        _bgIndex = (_bgIndex + 1) % _bgImages.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
      ),
      bottomNavigationBar: const CollegeBanner(),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user.name),
                accountEmail: const Text('Administrator'),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.admin_panel_settings, size: 26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Management',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Time Table'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TimetablePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Booking'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminBookingPage(user: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_toggle_off),
                title: const Text('Booking history'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingHistoryPage(viewer: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_vertical_circle_outlined),
                title: const Text('Swap history'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SwapHistoryPage(user: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.apartment_outlined),
                title: const Text('Blueprint'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BlueprintPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Student Accounts'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudentAccountsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Faculty Accounts'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FacultyAccountsPage(),
                    ),
                  );
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  final apiClient = ApiClient(baseUrl: apiBaseUrl);
                  final authApiService = AuthApiService(apiClient);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => RoleSelectionPage(
                        authApiService: authApiService,
                      ),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Image.asset(
              _bgImages[_bgIndex],
              key: ValueKey(_bgIndex),
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${user.name}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                // Removed instructional sentence as requested
              ],
            ),
          ),
        ],
      ),
    );
  }
}
