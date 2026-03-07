// Admin overview page for timetable and related tooling.
import 'package:flutter/material.dart';

import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';
import 'classroom_settings_page.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  static const List<String> groundFloorClassrooms = [
    'CS001',
    'CS003',
    'WAD LAB',
    'CS007',
    'CS008',
    'CS010',
  ];

  static const List<String> firstFloorClassrooms = [
    'CS101',
    'CS103',
    'CS104',
    'CS107',
    'CS108',
    'CS110',
    'SEMINAR HALL',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Time Table')),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.12,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure Classroom Time Tables',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick a classroom to set its capacity, CRs and weekly timetable grid.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.meeting_room_outlined,
                                  color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Ground floor',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ClassroomGrid(classrooms: groundFloorClassrooms),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.stairs_outlined,
                                  color: colorScheme.secondary),
                              const SizedBox(width: 8),
                              Text(
                                'First floor',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ClassroomGrid(classrooms: firstFloorClassrooms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassroomGrid extends StatelessWidget {
  const _ClassroomGrid({required this.classrooms});

  final List<String> classrooms;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classrooms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
      ),
      itemBuilder: (context, index) {
        final classroom = classrooms[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ClassroomSettingsPage(classroomName: classroom),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      classroom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
