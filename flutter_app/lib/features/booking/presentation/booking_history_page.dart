import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';
import '../../auth/models/auth_user.dart';
import '../models/booking_model.dart';
import '../services/booking_api_service.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key, this.viewer});

  final AuthUser? viewer;

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  late final ApiClient _apiClient;
  late final BookingApiService _bookingApiService;

  bool _isLoading = false;
  List<BookingModel> _bookings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _bookingApiService = BookingApiService(_apiClient);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookings = await _bookingApiService.fetchAllBookings();
      if (!mounted) return;
      setState(() {
        _bookings = _filterForViewer(bookings).reversed.toList();
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

  List<BookingModel> _filterForViewer(List<BookingModel> all) {
    final viewer = widget.viewer;
    if (viewer == null || viewer.role == UserRole.admin) {
      // Admin (or no viewer specified) sees all bookings.
      return all;
    }

    final roleValue = viewer.role.value;
    final loginId = viewer.loginId;

    return all
        .where((b) =>
            b.createdByRole == roleValue && b.createdByLoginId == loginId)
        .toList();
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _bookingApiService.updateBookingStatus(
        bookingId: booking.id,
        status: 'cancelled',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled.')),
      );

      await _loadBookings();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        actions: [
          if (_bookings.isNotEmpty && widget.viewer?.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear booking history',
              onPressed: _confirmClearHistory,
            ),
        ],
      ),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.12,
        child: RefreshIndicator(
          onRefresh: _loadBookings,
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'No bookings yet.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final roomLabel =
            booking.roomNumber ?? booking.roomName ?? booking.roomId;

        final canCancel =
            booking.status == 'pending' || booking.status == 'approved';

        final statusColor = _statusColor(context, booking.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                roomLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                booking.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _MiniChip(
                              icon: Icons.today,
                              label:
                                  '${booking.date}  ${booking.startTime}-${booking.endTime}',
                            ),
                            if (booking.batch != null && booking.batch!.isNotEmpty)
                              _MiniChip(
                                icon: Icons.group_outlined,
                                label: 'Batch: ${booking.batch}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'By: ${booking.requestedBy}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Purpose: ${booking.purpose}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black87),
                        ),
                        if (canCancel) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _cancelBooking(booking),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancel booking'),
                            ),
                          ),
                        ],
                      ],
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

  Color _statusColor(BuildContext context, String status) {
    final normalized = status.toLowerCase();
    final scheme = Theme.of(context).colorScheme;

    if (normalized == 'approved') return scheme.primary;
    if (normalized == 'pending') return scheme.tertiary;
    if (normalized == 'cancelled' || normalized == 'rejected') {
      return scheme.error;
    }
    return scheme.outline;
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear booking history'),
          content: const Text(
            'This will permanently delete all bookings. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _bookingApiService.clearAllBookings();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking history cleared.')),
      );

      await _loadBookings();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
