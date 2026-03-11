// Admin view for creating and managing room bookings.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';
import '../../auth/models/auth_user.dart';
import '../../admin/presentation/admin_home_page.dart';
import '../../faculty/presentation/faculty_home_page.dart';
import '../../auth/presentation/representative_home_page.dart';
import '../services/booking_api_service.dart';

class AdminBookingPage extends StatefulWidget {
  const AdminBookingPage({super.key, required this.user});

  final AuthUser user;

  @override
  State<AdminBookingPage> createState() => _AdminBookingPageState();
}

class _AdminBookingPageState extends State<AdminBookingPage> {
  DateTime? _selectedDate;
  String _spaceType = 'classroom'; // 'classroom' or 'seminar_wad'
  String? _selectedTimeSlot;
  bool? _projectorRequired;

  static const List<String> _classroomSlots = [
    '9:30-10:30',
    '10:30-11:30',
    '11:30-12:30',
    '1:30-2:30',
    '2:30-3:30',
    '3:30-4:30',
  ];

  // Special Friday pattern for classrooms.
  static const List<String> _fridayClassroomSlots = [
    '9:30-10:20',
    '10:20-11:10',
    '11:10-12:00',
    '2:00-2:50',
    '2:50-3:40',
    '3:40-4:30',
  ];

  static const List<String> _seminarAndLabSlots = [
    '9:30-10:30',
    '10:30-11:30',
    '11:30-12:30',
    '12:30-1:30',
    '1:30-2:30',
    '2:30-3:30',
    '3:30-4:30',
  ];

  List<String> get _currentSlots {
    // DateTime.weekday: Monday = 1, ..., Friday = 5, Saturday = 6, Sunday = 7
    final weekday = _selectedDate?.weekday;

    final isFriday = weekday == DateTime.friday;
    final isSaturdayOrSunday =
        weekday == DateTime.saturday || weekday == DateTime.sunday;

    // On Saturday and Sunday, all spaces (classrooms, seminar hall, WAD lab)
    // share the same 9:30–4:30 slot pattern.
    if (isSaturdayOrSunday) {
      return _classroomSlots;
    }

    // On Friday, only classrooms use the special Friday pattern.
    if (_spaceType == 'classroom') {
      return isFriday ? _fridayClassroomSlots : _classroomSlots;
    }

    // Other weekdays for Seminar Hall / WAD Lab.
    return _seminarAndLabSlots;
  }

  bool get _canProceed =>
      _selectedDate != null && _selectedTimeSlot != null && _projectorRequired != null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Reset selected time slot if the day changes,
        // because the available default slots may change
        // (e.g., Friday vs weekend vs weekday).
        _selectedTimeSlot = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    // Simple yyyy-mm-dd formatting without extra packages.
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = widget.user.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Booking' : 'Room Booking'),
      ),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.12,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select booking details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Space type – controls which default time slots are shown.
                      Text(
                        'Space type',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              value: 'classroom',
                              groupValue: _spaceType,
                              title: const Text(
                                'Classrooms (CS001, CS003, CS007, CS008, CS010, CS101, CS103, CS104, CS107, CS108, CS110)',
                              ),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _spaceType = value;
                                  _selectedTimeSlot = null;
                                });
                              },
                            ),
                            const Divider(height: 0),
                            RadioListTile<String>(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              value: 'seminar_wad',
                              groupValue: _spaceType,
                              title: const Text('Seminar Hall / WAD Lab'),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _spaceType = value;
                                  _selectedTimeSlot = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Date selector.
                      Text(
                        'Date',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _selectedDate == null
                                ? 'Select date'
                                : _formatDate(_selectedDate!),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Time slot selector with default slots per space type.
                      Text(
                        'Time slot',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTimeSlot,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select time slot',
                          isDense: true,
                        ),
                        items: _currentSlots
                            .map(
                              (slot) => DropdownMenuItem<String>(
                                value: slot,
                                child: Text(slot),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeSlot = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Projector availability – must be chosen explicitly.
                      Text(
                        'Projector availability',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Required'),
                            selected: _projectorRequired == true,
                            onSelected: (_) {
                              setState(() {
                                _projectorRequired = true;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Not required'),
                            selected: _projectorRequired == false,
                            onSelected: (_) {
                              setState(() {
                                _projectorRequired = false;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _canProceed
                              ? () {
                                  if (_selectedDate == null ||
                                      _selectedTimeSlot == null ||
                                      _projectorRequired == null) {
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AdminBookingNextPage(
                                        user: widget.user,
                                        date: _formatDate(_selectedDate!),
                                        timeSlot: _selectedTimeSlot!,
                                        projectorRequired: _projectorRequired!,
                                        spaceType: _spaceType,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          label: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Floor { ground, first }

enum _RoomKind { classroom, seminarOrLab, other }

class _RoomTile {
  const _RoomTile({
    required this.label,
    required this.kind,
  });

  final String label;
  final _RoomKind kind;
}

class AdminBookingNextPage extends StatefulWidget {
  const AdminBookingNextPage({
    super.key,
    required this.user,
    required this.date,
    required this.timeSlot,
    required this.projectorRequired,
    required this.spaceType,
  });

  final AuthUser user;
  final String date; // yyyy-MM-dd
  final String timeSlot; // e.g. 9:30-10:30
  final bool projectorRequired;
  final String spaceType; // 'classroom' or 'seminar_wad'

  @override
  State<AdminBookingNextPage> createState() => _AdminBookingNextPageState();
}

class _AdminBookingNextPageState extends State<AdminBookingNextPage> {
  late final ApiClient _apiClient;
  late final BookingApiService _bookingApiService;

  _Floor _selectedFloor = _Floor.ground;
  bool _isLoading = false;
  Map<String, bool> _availabilityByRoom = {};
  final Map<String, String> _roomIdByRoomNumber = {};
  final Map<String, String?> _reasonByRoom = {};
  String? _error;

  static const List<_RoomTile> _groundFloorRooms = [
    _RoomTile(label: 'CS001', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS003', kind: _RoomKind.classroom),
    _RoomTile(label: 'WAD LAB', kind: _RoomKind.seminarOrLab),
    _RoomTile(label: 'CS007', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS008', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS010', kind: _RoomKind.classroom),
    _RoomTile(label: 'WASHROOM', kind: _RoomKind.other),
    _RoomTile(label: 'STAFF ROOM', kind: _RoomKind.other),
    _RoomTile(label: 'HOD ROOM', kind: _RoomKind.other),
  ];

  static const List<_RoomTile> _firstFloorRooms = [
    _RoomTile(label: 'CS101', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS103', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS104', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS107', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS108', kind: _RoomKind.classroom),
    _RoomTile(label: 'CS110', kind: _RoomKind.classroom),
    _RoomTile(label: 'SEMINAR HALL', kind: _RoomKind.seminarOrLab),
    _RoomTile(label: 'WASHROOM', kind: _RoomKind.other),
    _RoomTile(label: 'STAFF ROOM', kind: _RoomKind.other),
    _RoomTile(label: 'HOD ROOM', kind: _RoomKind.other),
  ];

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _bookingApiService = BookingApiService(_apiClient);
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slotParts = widget.timeSlot.split('-');
      if (slotParts.length != 2) {
        throw Exception('Invalid time slot format');
      }

      final startTime = _normalizeTime(slotParts[0]);
      final endTime = _normalizeTime(slotParts[1]);

      final availabilityList = await _bookingApiService.checkAvailability(
        date: widget.date,
        startTime: startTime,
        endTime: endTime,
        projector: widget.projectorRequired,
      );

      final map = <String, bool>{};
      final reasonMap = <String, String?>{};
      for (final item in availabilityList) {
        if (item is! Map<String, dynamic>) continue;
        final room = item['room'];
        if (room is! Map<String, dynamic>) continue;

        final roomNumber =
            (room['roomNumber'] ?? room['name'] ?? '').toString().toUpperCase();
        final available = item['available'] == true;
        final reason = item['reason']?.toString();
        if (roomNumber.isEmpty) continue;
        final normalizedKey = _normalizeRoomKey(roomNumber);

        // Store both raw and normalized keys so UI lookups match backend values
        // even if hyphens/spaces differ (e.g., CS-007 vs CS007).
        map[roomNumber] = available;
        map[normalizedKey] = available;

        reasonMap[roomNumber] = reason;
        reasonMap[normalizedKey] = reason;

        final roomId = room['_id']?.toString();
        if (roomId != null && roomId.isNotEmpty) {
          _roomIdByRoomNumber[roomNumber] = roomId;
          _roomIdByRoomNumber[normalizedKey] = roomId;
        }
      }

      setState(() {
        _availabilityByRoom = map;
        _reasonByRoom
          ..clear()
          ..addAll(reasonMap);
      });
    } catch (error) {
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

  String _normalizeTime(String raw) {
    final trimmed = raw.trim();
    final parts = trimmed.split(':');
    if (parts.length != 2) return trimmed;

    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    // Treat afternoon hours (1–4) as 13:00–16:00.
    if (hour == 12) {
      // keep 12 as 12
    } else if (hour >= 1 && hour <= 4) {
      hour += 12;
    }

    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.date;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Room (Blueprint)'),
      ),
      bottomNavigationBar: const CollegeBanner(),
      body: Container
        (color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.08),
                          child: Icon(
                            Icons.meeting_room_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select room from blueprint',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap on an available (green) room to continue with your booking.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme
                                      .textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.today,
                          label: 'Date',
                          value: date,
                        ),
                        _InfoChip(
                          icon: Icons.schedule,
                          label: 'Time',
                          value: widget.timeSlot,
                        ),
                        _InfoChip(
                          icon: Icons.meeting_room_outlined,
                          label: 'Space',
                          value: widget.spaceType == 'classroom'
                              ? 'Classrooms'
                              : 'Seminar Hall / WAD Lab',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Ground Floor'),
                              selected: _selectedFloor == _Floor.ground,
                              onSelected: (_) {
                                setState(() => _selectedFloor = _Floor.ground);
                              },
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('1st Floor'),
                              selected: _selectedFloor == _Floor.first,
                              onSelected: (_) {
                                setState(() => _selectedFloor = _Floor.first);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: const [
                            _LegendDot(color: Colors.green, label: 'Available'),
                            SizedBox(width: 12),
                            _LegendDot(color: Colors.red, label: 'Not available'),
                            SizedBox(width: 12),
                            _LegendDot(color: Colors.grey, label: 'Other room'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                )
                              : _buildFloorPlan(),
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

  Widget _buildFloorPlan() {
    final rooms =
        _selectedFloor == _Floor.ground ? _groundFloorRooms : _firstFloorRooms;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final color = _colorForRoom(room);

        return InkWell(
          onTap: _isRoomSelectable(room)
              ? () {
                  final backendKey =
                      _backendKeyForDisplayLabel(room.label).toUpperCase();

                  if (color == Colors.green) {
                    final roomId = _roomIdByRoomNumber[backendKey];

                    if (roomId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not find room details for booking.'),
                        ),
                      );
                      return;
                    }

                    final slotParts = widget.timeSlot.split('-');
                    if (slotParts.length != 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid time slot format.'),
                        ),
                      );
                      return;
                    }

                    final startTime = _normalizeTime(slotParts[0]);
                    final endTime = _normalizeTime(slotParts[1]);

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminBookingConfirmPage(
                          user: widget.user,
                          date: widget.date,
                          timeSlot: widget.timeSlot,
                          startTime: startTime,
                          endTime: endTime,
                          roomId: roomId,
                          roomLabel: room.label,
                          projectorRequired: widget.projectorRequired,
                          spaceType: widget.spaceType,
                        ),
                      ),
                    );
                  } else if (color == Colors.red) {
                    final reason =
                        _reasonByRoom[backendKey] ?? 'Room not available for this slot.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(reason)),
                    );
                  }
                }
              : null,
          child: Ink(
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black26),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  room.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isRoomSelectable(_RoomTile room) {
    if (room.kind == _RoomKind.other) return false;

    if (widget.spaceType == 'classroom') {
      // Allow all classroom tiles from the blueprint when classroom mode is selected.
      return room.kind == _RoomKind.classroom;
    }

    // Seminar/WAD mode: allow Seminar Hall and WAD Lab.
    return room.label == 'SEMINAR HALL' || room.label == 'WAD LAB';
  }

  Color _colorForRoom(_RoomTile room) {
    if (room.kind == _RoomKind.other) {
      return Colors.grey;
    }

    if (!_isRoomSelectable(room)) {
      return Colors.grey.shade600;
    }

    // Map the UI label (e.g. CS001) to the backend roomNumber
    // used in availability (e.g. C-101).
    final backendKey = _backendKeyForDisplayLabel(room.label);
    final available = _availabilityByRoom[backendKey];

    if (available == null) {
      return Colors.grey.shade500;
    }

    return available ? Colors.green : Colors.red;
  }

  /// Translate blueprint labels to backend roomNumber keys.
  ///
  /// Fallback is the uppercased label itself so if backend and
  /// UI labels already match, colours still work.
  String _backendKeyForDisplayLabel(String label) {
    switch (label.toUpperCase()) {
      case 'CS001':
        return _normalizeRoomKey('CS001');
      case 'CS003':
        return _normalizeRoomKey('CS003');
      case 'WAD LAB':
        return _normalizeRoomKey('WAD LAB');
      case 'SEMINAR HALL':
        return _normalizeRoomKey('SEMINAR HALL');
      default:
        return _normalizeRoomKey(label);
    }
  }

  String _normalizeRoomKey(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

class AdminBookingConfirmPage extends StatefulWidget {
  const AdminBookingConfirmPage({
    super.key,
    required this.user,
    required this.date,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    required this.roomId,
    required this.roomLabel,
    required this.projectorRequired,
    required this.spaceType,
  });

  final AuthUser user;
  final String date;
  final String timeSlot;
  final String startTime;
  final String endTime;
  final String roomId;
  final String roomLabel;
  final bool projectorRequired;
  final String spaceType;

  @override
  State<AdminBookingConfirmPage> createState() => _AdminBookingConfirmPageState();
}

class _AdminBookingConfirmPageState extends State<AdminBookingConfirmPage> {
  late final ApiClient _apiClient;
  late final BookingApiService _bookingApiService;

  final _formKey = GlobalKey<FormState>();
  final _requestedByController = TextEditingController();
  final _purposeController = TextEditingController();
  final _batchController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _bookingApiService = BookingApiService(_apiClient);
  }

  @override
  void dispose() {
    _requestedByController.dispose();
    _purposeController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _bookingApiService.createBooking(
        roomId: widget.roomId,
        date: widget.date,
        startTime: widget.startTime,
        endTime: widget.endTime,
        requestedBy: _requestedByController.text.trim(),
        purpose: _purposeController.text.trim(),
        createdByRole: widget.user.role.value,
        createdByLoginId: widget.user.loginId,
        createdByName: widget.user.name,
        batch: _batchController.text.trim().isEmpty
            ? null
            : _batchController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created successfully.')),
      );

      final user = widget.user;
      final destinationPage = user.role == UserRole.admin
          ? AdminHomePage(user: user)
          : user.role == UserRole.faculty
              ? FacultyHomePage(user: user)
              : RepresentativeHomePage(user: user);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destinationPage),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      bottomNavigationBar: const CollegeBanner(),
      body: Container(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.08),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Review and confirm booking',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Double‑check the details below, then add requester and purpose to finalize the booking.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme
                                      .textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.meeting_room_outlined,
                          label: 'Room',
                          value: widget.roomLabel,
                        ),
                        _InfoChip(
                          icon: Icons.today,
                          label: 'Date',
                          value: widget.date,
                        ),
                        _InfoChip(
                          icon: Icons.schedule,
                          label: 'Time',
                          value: widget.timeSlot,
                        ),
                        _InfoChip(
                          icon: Icons.category_outlined,
                          label: 'Type',
                          value: widget.spaceType == 'classroom'
                              ? 'Classroom'
                              : 'Seminar / WAD',
                        ),
                        _InfoChip(
                          icon: Icons.videocam_outlined,
                          label: 'Projector',
                          value:
                              widget.projectorRequired ? 'Required' : 'Not required',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Booking details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _requestedByController,
                            decoration: const InputDecoration(
                              labelText: 'Requested by',
                              hintText: 'Faculty / staff name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter requester name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _purposeController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Purpose',
                              hintText: 'Lecture, exam, seminar, meeting…',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter purpose';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _batchController,
                            decoration: const InputDecoration(
                              labelText: 'Batch (optional)',
                              hintText: 'e.g. CS S6 A',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                                  child: const Text('Back'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Confirm booking'),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
