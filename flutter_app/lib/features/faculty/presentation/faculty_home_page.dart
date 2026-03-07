// Faculty home dashboard with quick access to features.
import 'package:flutter/material.dart';

import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/presentation/role_selection_page.dart';
import '../../auth/services/auth_api_service.dart';
import '../../../core/api/api_client.dart';
import '../../booking/presentation/admin_booking_page.dart';
import '../../booking/presentation/booking_history_page.dart';
import '../../admin/presentation/blueprint_page.dart';
import '../../booking/presentation/swap_room_page.dart';
import '../../booking/presentation/swap_history_page.dart';
import '../../booking/presentation/swap_notifications_page.dart';
import 'faculty_profile_page.dart';

class FacultyHomePage extends StatelessWidget {
  const FacultyHomePage({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Home'),
      ),
      bottomNavigationBar: const CollegeBanner(),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user.name),
                accountEmail: Text('Faculty ID: ${user.loginId}'),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.school_outlined, size: 26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Actions',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
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
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Swap Room'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SwapRoomPage(user: user),
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
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Swap notifications'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SwapNotificationsPage(user: user),
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
                    MaterialPageRoute(
                      builder: (_) => const BlueprintPage(),
                    ),
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  'Your profile',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('View profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FacultyProfilePage(user: user),
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
      body: AppBackground(
        opacity: 0.75,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the menu to view bookings, blueprint, or your teaching profile.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
