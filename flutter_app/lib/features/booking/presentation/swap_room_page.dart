// Page for selecting a timetable slot and target room to swap.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/services/auth_api_service.dart';
import '../../auth/presentation/role_selection_page.dart';
import '../../booking/services/swap_api_service.dart';
import '../models/swap_models.dart';
import 'swap_booking_page.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class SwapRoomPage extends StatefulWidget {
  const SwapRoomPage({super.key, required this.user});

  final AuthUser user;

  @override
  State<SwapRoomPage> createState() => _SwapRoomPageState();
}

class _SwapRoomPageState extends State<SwapRoomPage> {
  DateTime? _selectedDate;
  String? _selectedStartTime;
  String? _selectedEndTime;
  bool _projectorRequired = false;
  bool _loading = false;
  String? _error;
  SwapOptionsResult? _result;
  int? _selectedRequesterIndex;

  static const _monThuSlots = <Map<String, String>>[
    {'start': '09:30', 'end': '10:30'},
    {'start': '10:30', 'end': '11:30'},
    {'start': '11:30', 'end': '12:30'},
    {'start': '13:30', 'end': '14:30'},
    {'start': '14:30', 'end': '15:30'},
    {'start': '15:30', 'end': '16:30'},
  ];

  static const _friSlots = <Map<String, String>>[
    {'start': '09:30', 'end': '10:20'},
    {'start': '10:20', 'end': '11:10'},
    {'start': '11:10', 'end': '12:00'},
    {'start': '14:00', 'end': '14:50'},
    {'start': '14:50', 'end': '15:40'},
    {'start': '15:40', 'end': '16:30'},
  ];

  List<Map<String, String>> get _currentSlots {
    if (_selectedDate == null) return _monThuSlots;
    final weekday = _selectedDate!.weekday; // 1=Mon..7=Sun
    if (weekday == DateTime.friday) return _friSlots;
    return _monThuSlots;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedStartTime = null;
        _selectedEndTime = null;
        _result = null;
        _selectedRequesterIndex = null;
        _error = null;
      });
    }
  }

  Future<void> _search() async {
    if (widget.user.role != UserRole.faculty) {
      setState(() {
        _error = 'Swap Room is only available for faculty accounts.';
        _result = null;
      });
      return;
    }

    if (_selectedDate == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      setState(() {
        _error = 'Please select date and period.';
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _selectedRequesterIndex = null;
    });

    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    final apiClient = ApiClient(baseUrl: apiBaseUrl);
    final swapApi = SwapApiService(apiClient);

    try {
      final dateStr =
          '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      final result = await swapApi.fetchSwapOptions(
        facultyId: widget.user.loginId,
        date: dateStr,
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
        projectorRequired: _projectorRequired,
      );

      setState(() {
        _loading = false;
        _result = result;
        // Default selection: first requester entry if multiple, otherwise
        // the single requesterEntry if present.
        if (result.requesterEntries.isNotEmpty) {
          _selectedRequesterIndex = 0;
        } else if (result.requesterEntry != null) {
          _selectedRequesterIndex = 0;
        } else {
          _selectedRequesterIndex = null;
        }
        _error = result.available ? null : (result.message.isEmpty ? 'NO SWAPPING AVAILABLE' : result.message);
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load swap options.';
      });
    }
  }

  void _logout() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    final apiClient = ApiClient(baseUrl: apiBaseUrl);
    final authApiService = AuthApiService(apiClient);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RoleSelectionPage(authApiService: authApiService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate == null
        ? 'Select date'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Faculty: ${widget.user.name} (${widget.user.loginId})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(dateLabel),
                      onPressed: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedStartTime,
                      items: _currentSlots
                          .map(
                            (slot) => DropdownMenuItem<String>(
                              value: slot['start'],
                              child: Text('${slot['start']} - ${slot['end']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final slot = _currentSlots.firstWhere(
                          (s) => s['start'] == value,
                        );
                        setState(() {
                          _selectedStartTime = slot['start'];
                          _selectedEndTime = slot['end'];
                          _result = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Projector required'),
                value: _projectorRequired,
                onChanged: (value) {
                  setState(() {
                    _projectorRequired = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: const Icon(Icons.search),
                  label: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Find rooms to swap'),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (_result != null && _result!.available)
                Expanded(
                  child: _buildResultsList(_result!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(SwapOptionsResult result) {
    final tiles = <Widget>[];
    final requesterEntries = result.requesterEntries.isNotEmpty
        ? result.requesterEntries
        : (result.requesterEntry != null
            ? <SwapOptionModel>[result.requesterEntry!]
            : <SwapOptionModel>[]);

    if (requesterEntries.isNotEmpty) {
      tiles.add(
        Card(
          color: Colors.grey.shade300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  requesterEntries.length > 1
                      ? 'Select which of your classes you are in for this period:'
                      : 'Your class at this period:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (var i = 0; i < requesterEntries.length; i++)
                RadioListTile<int>(
                  value: i,
                  groupValue: _selectedRequesterIndex,
                  onChanged: (value) {
                    setState(() {
                      _selectedRequesterIndex = value;
                    });
                  },
                  title: Text(requesterEntries[i].classroomName),
                  subtitle: Text(
                    'Class: ${requesterEntries[i].courseName} (Capacity: ${requesterEntries[i].capacity ?? '-'}; Projector: ${requesterEntries[i].hasProjector ? 'Yes' : 'No'})',
                  ),
                ),
            ],
          ),
        ),
      );
    }

    for (final option in result.options) {
      final isGreen = option.colorHint == 'green';
      final color = isGreen ? Colors.green.shade200 : Colors.red.shade200;

      tiles.add(
        Card(
          color: color,
          child: ListTile(
            title: Text(option.classroomName),
            subtitle: Text(
              '${option.courseName.isEmpty ? 'No subject' : option.courseName} — ${option.facultyName.isEmpty ? 'Unknown faculty' : option.facultyName}\nCapacity: ${option.capacity ?? '-'}; Projector: ${option.hasProjector ? 'Yes' : 'No'}',
            ),
            onTap: isGreen
                ? () {
                    final requesterList = requesterEntries;
                    SwapOptionModel? selectedRequester;
                    if (requesterList.isNotEmpty) {
                      final index = (_selectedRequesterIndex ?? 0)
                          .clamp(0, requesterList.length - 1);
                      selectedRequester = requesterList[index];
                    } else {
                      selectedRequester = result.requesterEntry;
                    }

                    if (selectedRequester == null) {
                      return;
                    }

                    final args = SwapBookingArgs(
                      user: widget.user,
                      date: _selectedDate!,
                      startTime: _selectedStartTime!,
                      endTime: _selectedEndTime!,
                      projectorRequired: _projectorRequired,
                      requesterEntry: selectedRequester,
                      targetOption: option,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SwapBookingPage(args: args),
                      ),
                    );
                  }
                : null,
          ),
        ),
      );
    }

    return ListView(
      children: tiles,
    );
  }
}
