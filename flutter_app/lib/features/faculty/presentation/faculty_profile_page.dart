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
      final data =
          await _apiClient.get(
                '/api/faculty/${Uri.encodeComponent(widget.user.loginId)}/profile',
              )
              as Map<String, dynamic>;

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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary.withOpacity(0.95),
        foregroundColor: Colors.white,
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

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _FacultyHeroCard(
                name: facultyName,
                loginId: widget.user.loginId,
                totalSlots: entries.length,
                uniqueRooms: entries
                    .map((entry) => entry['classroomName']?.toString() ?? '')
                    .where((value) => value.isNotEmpty)
                    .toSet()
                    .length,
                uniqueBatches: entries
                    .map((entry) => entry['batch']?.toString() ?? '')
                    .where((value) => value.isNotEmpty)
                    .toSet()
                    .length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (entries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyScheduleCard(
                  colorScheme: colorScheme,
                  onRefresh: _loadProfile,
                  message:
                      'No teaching slots have been configured yet for this faculty account.',
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teaching Schedule',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A polished view of your active timetable slots',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  final courseName =
                      (entry['courseName'] as String? ?? '').isEmpty
                      ? 'Subject'
                      : entry['courseName'] as String;
                  final dayName = entry['dayName'] as String? ?? '';
                  final startTime = entry['startTime'] as String? ?? '';
                  final endTime = entry['endTime'] as String? ?? '';
                  final classroomName =
                      entry['classroomName'] as String? ?? 'Classroom';
                  final batch = entry['batch'] as String? ?? '';

                  return _ScheduleCard(
                    courseName: courseName,
                    dayName: dayName,
                    startTime: startTime,
                    endTime: endTime,
                    classroomName: classroomName,
                    batch: batch,
                    accentColor: _accentColorForIndex(index, colorScheme),
                  );
                }, childCount: entries.length),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _accentColorForIndex(int index, ColorScheme colorScheme) {
    final accents = [
      colorScheme.primary,
      colorScheme.tertiary,
      Colors.teal,
      Colors.deepOrange,
      Colors.indigo,
      Colors.pink,
    ];

    return accents[index % accents.length];
  }
}

class _FacultyHeroCard extends StatelessWidget {
  const _FacultyHeroCard({
    required this.name,
    required this.loginId,
    required this.totalSlots,
    required this.uniqueRooms,
    required this.uniqueBatches,
  });

  final String name;
  final String loginId;
  final int totalSlots;
  final int uniqueRooms;
  final int uniqueBatches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.95),
                    colorScheme.tertiary.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Faculty Profile',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Faculty ID: $loginId',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Slots',
                    value: totalSlots.toString(),
                    icon: Icons.event_note_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    label: 'Rooms',
                    value: uniqueRooms.toString(),
                    icon: Icons.meeting_room_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(
                    label: 'Batches',
                    value: uniqueBatches.toString(),
                    icon: Icons.groups_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.courseName,
    required this.dayName,
    required this.startTime,
    required this.endTime,
    required this.classroomName,
    required this.batch,
    required this.accentColor,
  });

  final String courseName;
  final String dayName;
  final String startTime;
  final String endTime;
  final String classroomName;
  final String batch;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              child: const SizedBox(width: 10),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(22),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        courseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _DayPill(label: dayName, color: accentColor),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  text: '$startTime - $endTime',
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  text: classroomName,
                ),
                if (batch.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.group_work_outlined, text: batch),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({
    required this.colorScheme,
    required this.onRefresh,
    required this.message,
  });

  final ColorScheme colorScheme;
  final VoidCallback onRefresh;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.info_outline, color: colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'If the schedule was updated recently, refresh to load the latest timetable.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
