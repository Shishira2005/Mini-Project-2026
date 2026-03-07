import 'package:flutter/material.dart';

import '../../../shared/widgets/app_background.dart';
import '../models/auth_user.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${user.role.title} Dashboard')),
      body: AppBackground(
        opacity: 0.12,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, ${user.name}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Role: ${user.role.title}'),
              Text('Login ID: ${user.loginId}'),
            ],
          ),
        ),
      ),
    );
  }
}
