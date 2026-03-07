// Faculty profile and timetable view page.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../auth/models/auth_user.dart';
import '../../../shared/widgets/app_background.dart';

class FacultyProfilePage extends StatefulWidget {
  const FacultyProfilePage({super.key, required this.user});

  final AuthUser user;

  @override
  State<FacultyProfilePage> createState() => _FacultyProfilePageState();
}

class _FacultyProfilePageState extends State<FacultyProfilePage> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _profile;

  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiClient.get(
        '/api/faculty/${Uri.encodeComponent(widget.user.loginId)}/profile',
      ) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _profile = data;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Profile'),
      ),
      body: AppBackground(
        opacity: 0.12,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadProfile,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return const Center(child: Text('No profile information available.'));
    }

    final entries = (profile['entries'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final facultyName = (profile['facultyName'] as String? ?? '').isNotEmpty
        ? profile['facultyName'] as String
        : widget.user.name;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeaderCard(
              name: facultyName,
              idLabel: 'Faculty ID',
              idValue: widget.user.loginId,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No teaching slots have been configured yet.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHeaderCard(
            name: facultyName,
            idLabel: 'Faculty ID',
            idValue: widget.user.loginId,
          ),
          const SizedBox(height: 16),
          Text(
            'Teaching Schedule',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final courseName = (entry['courseName'] as String? ?? '').isEmpty
                    ? 'Subject'
                    : entry['courseName'] as String;
                final dayName = entry['dayName'] as String? ?? '';
                final startTime = entry['startTime'] as String? ?? '';
                final endTime = entry['endTime'] as String? ?? '';
                final classroomName =
                    entry['classroomName'] as String? ?? 'Classroom';
                final batch = entry['batch'] as String? ?? '';

                final subtitleLines = <String>[
                  '$dayName, $startTime - $endTime',
                  'Room: $classroomName',
                ];
                if (batch.isNotEmpty) {
                  subtitleLines.add('Batch: $batch');
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          colorScheme.primaryContainer.withOpacity(0.9),
                      child: Icon(
                        Icons.menu_book_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    title: Text(courseName),
                    subtitle: Text(subtitleLines.join('\n')),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.idLabel,
    required this.idValue,
  });

  final String name;
  final String idLabel;
  final String idValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.9),
              child: Icon(
                Icons.school_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$idLabel: $idValue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
