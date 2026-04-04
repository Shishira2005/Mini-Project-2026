// Common Facilities home page.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';
import '../models/auth_user.dart';
import '../services/auth_api_service.dart';
import 'common_facilities_booking_page.dart';
import 'common_facilities_history_page.dart';
import 'common_facilities_notifications_page.dart';
import 'common_facilities_profile_page.dart';
import 'common_facilities_settings_page.dart';
import 'role_selection_page.dart';

class CommonFacilitiesPortalPage extends StatelessWidget {
  const CommonFacilitiesPortalPage({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Common Facilities Home'),
        centerTitle: true,
      ),
      bottomNavigationBar: const CollegeBanner(),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user.name),
                accountEmail: Text(user.loginId),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.apartment_outlined, size: 26),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommonFacilitiesProfilePage(user: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: const Text('Common Facility Booking'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommonFacilitiesBookingPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Notification'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommonFacilitiesNotificationsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Booking History'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommonFacilitiesHistoryPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Setting'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CommonFacilitiesSettingsPage(),
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
      body: AppBackground(
        opacity: 0.2,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, ${user.name}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Use the menu at the top left to open your Common Facilities tools.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
