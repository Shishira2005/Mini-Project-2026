// Admin editor for the weekly classroom timetable grid.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';

class ClassroomTimetablePage extends StatefulWidget {
  const ClassroomTimetablePage({super.key, required this.classroomName});

  final String classroomName;

  @override
  State<ClassroomTimetablePage> createState() => _ClassroomTimetablePageState();
}

class _ClassroomTimetablePageState extends State<ClassroomTimetablePage> {
  // Days and periods configuration
  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  static const List<String> _periodHeaders = [
    '1',
    '2',
    '3',
    'LUNCH',
    '4',
    '5',
    '6',
  ];

  static const int _lunchColumnIndex = 3;

  // Time ranges for each period
  static const List<String> _monToThuTimes = [
    '09:30 - 10:30',
    '10:30 - 11:30',
    '11:30 - 12:30',
    '01:30 - 02:30',
    '02:30 - 03:30',
    '03:30 - 04:30',
  ];

  static const List<String> _fridayTimes = [
    '09:30 - 10:20',
    '10:20 - 11:10',
    '11:10 - 12:00',
    '02:00 - 02:50',
    '02:50 - 03:40',
    '03:40 - 04:30',
  ];

  // Grid is keyed by "dayIndex_periodIndex" (e.g. "0_0" for Monday Period 1)
  final Map<String, String> _gridSlots = {};

  // Slot details table rows
  final List<Map<String, String>> _slotDetails = [];

  bool _isLoading = false;

  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.get(
        '/api/timetable/admin-layout/${widget.classroomName}',
      ) as Map<String, dynamic>;

      final grid = data['grid'] as Map<String, dynamic>? ?? {};
      _gridSlots
        ..clear()
        ..addAll(grid.map((key, value) => MapEntry(key, value.toString())));

      final slotDetails = data['slotDetails'] as List<dynamic>? ?? [];
      _slotDetails
        ..clear()
        ..addAll(slotDetails.map((row) {
          final map = row as Map<String, dynamic>;
          return <String, String>{
            'slot': (map['slot'] ?? '').toString(),
            'courseName': (map['courseName'] ?? '').toString(),
            'facultyId': (map['facultyId'] ?? '').toString(),
            'facultyName': (map['facultyName'] ?? '').toString(),
          };
        }));
      if (_slotDetails.isEmpty) {
        // Provide a few empty rows by default
        _slotDetails.addAll(List.generate(6, (_) => {
              'slot': '',
              'courseName': '',
              'facultyId': '',
              'facultyName': '',
            }));
      }
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTimetable() async {
    setState(() => _isLoading = true);
    try {
      final body = {
        'grid': _gridSlots,
        'slotDetails': _slotDetails,
      };

      await _apiClient.put(
        '/api/timetable/admin-layout/${widget.classroomName}',
        body: body,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable saved successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildWeeklyGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECTION 1: WEEKLY TIMETABLE GRID',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Make sure the table is at least as wide as the screen
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: Theme.of(context).dividerColor),
              columnWidths: const {
                0: FixedColumnWidth(80), // Day column
              },
              children: [
                ..._buildGridRows(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCell(int dayIndex, int periodIndex) {
    // Lunch Break column is not editable; we show the label only, merged conceptually.
    if (periodIndex == _lunchColumnIndex) {
      return const Center(child: Text('LUNCH BREAK'));
    }

    final key = '${dayIndex}_$periodIndex';
    final initialValue = _gridSlots[key] ?? '';

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: TextFormField(
        initialValue: initialValue,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (value.trim().isEmpty) {
            _gridSlots.remove(key);
          } else {
            _gridSlots[key] = value.trim();
          }
        },
      ),
    );
  }

  List<TableRow> _buildGridRows() {
    final rows = <TableRow>[];

    // Header row
    rows.add(
      TableRow(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Day',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ..._periodHeaders.map(
            (title) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title == 'LUNCH' ? 'Lunch Break' : 'P$title',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    // Mon–Thu timing row (same timings for all these days)
    rows.add(
      TableRow(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Mon–Thu Time'),
          ),
          for (var periodIndex = 0;
              periodIndex < _periodHeaders.length;
              periodIndex++)
            Builder(
              builder: (context) {
                if (periodIndex == _lunchColumnIndex) {
                  return const Center(child: Text('Lunch Break'));
                }

                final timeIndex = periodIndex < _lunchColumnIndex
                    ? periodIndex
                    : periodIndex - 1;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _monToThuTimes[timeIndex],
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
        ],
      ),
    );

    // Rows for each day, inserting a Friday time row after Thursday
    for (var dayIndex = 0; dayIndex < _days.length; dayIndex++) {
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_days[dayIndex]),
            ),
            for (var periodIndex = 0;
                periodIndex < _periodHeaders.length;
                periodIndex++)
              _buildGridCell(dayIndex, periodIndex),
          ],
        ),
      );

      // After Thursday (index 3), insert a non-editable row
      // that shows the special Friday timings.
      if (dayIndex == 3) {
        rows.add(_buildFridayTimeRow());
      }
    }

    return rows;
  }

  TableRow _buildFridayTimeRow() {
    return TableRow(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Friday Time'),
        ),
        for (var periodIndex = 0;
            periodIndex < _periodHeaders.length;
            periodIndex++)
          Builder(
            builder: (context) {
              if (periodIndex == _lunchColumnIndex) {
                return const Center(child: Text('Lunch Break'));
              }

              final timeIndex =
                  periodIndex < _lunchColumnIndex ? periodIndex : periodIndex - 1;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _fridayTimes[timeIndex],
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSlotDetailsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'SECTION 2: SLOT DETAILS TABLE',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(60),
            4: FixedColumnWidth(56),
          },
          border: TableBorder.all(color: Theme.of(context).dividerColor),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: const [
                _HeaderCell('Slot'),
                _HeaderCell('Course Name'),
                _HeaderCell('Faculty ID'),
                _HeaderCell('Faculty Name'),
                _HeaderCell(''),
              ],
            ),
            for (var i = 0; i < _slotDetails.length; i++)
              TableRow(
                children: [
                  _EditableCell(
                    initialValue: _slotDetails[i]['slot'] ?? '',
                    onChanged: (value) => _slotDetails[i]['slot'] = value,
                  ),
                  _EditableCell(
                    initialValue: _slotDetails[i]['courseName'] ?? '',
                    onChanged: (value) => _slotDetails[i]['courseName'] = value,
                  ),
                  _EditableCell(
                    initialValue: _slotDetails[i]['facultyId'] ?? '',
                    onChanged: (value) => _slotDetails[i]['facultyId'] = value,
                  ),
                  _EditableCell(
                    initialValue: _slotDetails[i]['facultyName'] ?? '',
                    onChanged: (value) => _slotDetails[i]['facultyName'] = value,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _slotDetails.removeAt(i);
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Remove row',
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _slotDetails.add({
                  'slot': '',
                  'courseName': '',
                  'facultyId': '',
                  'facultyName': '',
                });
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Slot Row'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.classroomName} Time Table')),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.12,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeeklyGrid(),
                      _buildSlotDetailsTable(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveTimetable,
                          child: const Text('Save Timetable'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EditableCell extends StatelessWidget {
  const _EditableCell({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
