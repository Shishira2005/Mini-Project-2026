// Page for choosing the user role before login.
import 'package:flutter/material.dart';

import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';
import '../models/auth_user.dart';
import '../services/auth_api_service.dart';
import 'role_login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key, required this.authApiService});

  final AuthApiService authApiService;

  void _openLogin(BuildContext context, UserRole role) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleLoginPage(
          role: role,
          authApiService: authApiService,
        ),
      ),
    );
  }

  List<_RoleOption> _roleOptions(ColorScheme colorScheme) {
    return [
      _RoleOption(
        role: UserRole.faculty,
        title: 'Faculty',
        description: 'Manage classes, track bookings, and approve usage.',
        icon: Icons.school_outlined,
        accent: colorScheme.primary,
      ),
      _RoleOption(
        role: UserRole.representative,
        title: 'Representative',
        description: 'Book rooms for teams and coordinate with faculty.',
        icon: Icons.groups_outlined,
        accent: colorScheme.secondary,
      ),
      _RoleOption(
        role: UserRole.admin,
        title: 'Admin',
        description: 'Oversee schedules, permissions, and campus spaces.',
        icon: Icons.admin_panel_settings_outlined,
        accent: colorScheme.tertiary,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roles = _roleOptions(colorScheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your access'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      bottomNavigationBar: const CollegeBanner(),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        opacity: 0.18,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Campus Spaces',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick the role that matches what you need today.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 540;
                          return GridView.builder(
                            itemCount: roles.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 2 : 1,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isWide ? 1.15 : 1.35,
                            ),
                            itemBuilder: (_, index) {
                              final option = roles[index];
                              return _RoleCard(
                                option: option,
                                onTap: () => _openLogin(context, option.role),
                              );
                            },
                          );
                        },
                      ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.option, required this.onTap});

  final _RoleOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: option.accent.withOpacity(0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: option.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  option.icon,
                  color: option.accent,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                option.title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                option.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Continue',
                    style: textTheme.labelLarge?.copyWith(
                      color: option.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: option.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final UserRole role;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}
