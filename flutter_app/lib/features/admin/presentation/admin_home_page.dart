// Main admin dashboard with navigation to admin tools.
import 'package:flutter/material.dart';

import '../../../shared/widgets/college_banner.dart';
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
import 'account_verification_page.dart';
import 'account_verification_history_page.dart';
import 'common_facilities_accounts_page.dart';

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
    _bgImages = ['assets/LBS IMAGE.jpg'];
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
      appBar: AppBar(title: const Text('Admin Home')),
      bottomNavigationBar: const CollegeBanner(),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Account Verification'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountVerificationPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Account Verification History'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountVerificationHistoryPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Common Facilities Accounts'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommonFacilitiesAccountsPage(),
                    ),
                  );
                },
              ),
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
                      builder: (_) =>
                          RoleSelectionPage(authApiService: authApiService),
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
          Container(color: Colors.black.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome, ${user.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Card(
                        color: Colors.white.withOpacity(0.88),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Quick Access',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 16),
                              _HomeActionTile(
                                icon: Icons.apartment_outlined,
                                title: 'Blueprint',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BlueprintPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _HomeActionTile(
                                icon: Icons.people_outline,
                                title: 'Student Accounts',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const StudentAccountsPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _HomeActionTile(
                                icon: Icons.school_outlined,
                                title: 'Faculty Accounts',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FacultyAccountsPage(),
                                    ),
                                  );
                                },
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
          ),
        ],
      ),
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(title),
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
