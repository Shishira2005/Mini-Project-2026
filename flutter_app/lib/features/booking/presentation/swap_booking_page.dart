// Form page used to submit a room swap request.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../auth/models/auth_user.dart';
import '../models/swap_models.dart';
import '../services/swap_api_service.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class SwapBookingPage extends StatefulWidget {
  const SwapBookingPage({super.key, required this.args});

  final SwapBookingArgs args;

  @override
  State<SwapBookingPage> createState() => _SwapBookingPageState();
}

class SwapBookingArgs {
  SwapBookingArgs({
    required this.user,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.projectorRequired,
    required this.requesterEntry,
    required this.targetOption,
  });

  final AuthUser user;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool projectorRequired;
  final SwapOptionModel requesterEntry;
  final SwapOptionModel targetOption;
}

class _SwapBookingPageState extends State<SwapBookingPage> {
  final _reasonController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _error = 'Please provide a reason for swapping.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    final apiClient = ApiClient(baseUrl: apiBaseUrl);
    final swapApi = SwapApiService(apiClient);

    try {
      final d = widget.args.date;
      final dateStr =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      await swapApi.createSwapRequest(
        date: dateStr,
        startTime: widget.args.startTime,
        endTime: widget.args.endTime,
        projectorRequired: widget.args.projectorRequired,
        requesterFacultyId: widget.args.user.loginId,
        requesterFacultyName: widget.args.user.name,
        requesterClassroomName: widget.args.requesterEntry.classroomName,
        targetClassroomName: widget.args.targetOption.classroomName,
        targetFacultyId: widget.args.targetOption.facultyId,
        targetFacultyName: widget.args.targetOption.facultyName,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swap request submitted.')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Failed to submit swap request.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final dateLabel =
        '${a.date.day}/${a.date.month}/${a.date.year} ${a.startTime}-${a.endTime}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Booking'),
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
                'Swap request for $dateLabel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Your class: ${a.requesterEntry.classroomName} — ${a.requesterEntry.courseName}',
              ),
              const SizedBox(height: 4),
              Text(
                'Target class: ${a.targetOption.classroomName} — ${a.targetOption.courseName} (${a.targetOption.facultyName})',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason for swap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit swap request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
