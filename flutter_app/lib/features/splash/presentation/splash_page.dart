import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../auth/presentation/role_selection_page.dart';
import '../../auth/services/auth_api_service.dart';
import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to role selection after 4 seconds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 4), () {
        if (!mounted) return;

        const apiBaseUrl = String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://10.0.2.2:5000',
        );
        final apiClient = ApiClient(baseUrl: apiBaseUrl);
        final authApiService = AuthApiService(apiClient);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RoleSelectionPage(authApiService: authApiService),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        opacity: 0.2,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                height: 140,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/LBS LOGO.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'College Room Booking',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(flex: 2),
              const CollegeBanner(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
