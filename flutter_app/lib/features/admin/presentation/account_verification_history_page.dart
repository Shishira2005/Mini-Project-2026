// Admin page showing Common Facilities account approval/decline history.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class AccountVerificationHistoryPage extends StatefulWidget {
  const AccountVerificationHistoryPage({super.key});

  @override
  State<AccountVerificationHistoryPage> createState() =>
      _AccountVerificationHistoryPageState();
}

class _AccountVerificationHistoryPageState
    extends State<AccountVerificationHistoryPage> {
  late final ApiClient _apiClient;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiClient.get('/api/admin/accounts/verification-history')
          as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _history = data.cast<Map<String, dynamic>>();
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

  Future<void> _retryNotification(Map<String, dynamic> entry) async {
    final id = entry['id']?.toString() ?? '';
    if (id.isEmpty) return;

    try {
      final response = await _apiClient.patch(
        '/api/admin/accounts/verification-history/$id/retry-notification',
      ) as Map<String, dynamic>;

      if (!mounted) return;

      final notificationStatus = response['notificationStatus']?.toString() ?? '';
      final notificationError = response['notificationError']?.toString() ?? '';
      final message = notificationStatus == 'sent'
          ? 'Notification email resent successfully.'
          : notificationError.isEmpty
              ? 'Notification resend failed.'
              : 'Notification resend failed: $notificationError';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await _loadHistory();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Verification History')),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.12,
        child: RefreshIndicator(
          onRefresh: _loadHistory,
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      );
    }

    if (_history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [Text('No verification history yet.')],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        final name = entry['name']?.toString() ?? '';
        final email = entry['email']?.toString() ?? '';
        final category = entry['category']?.toString() ?? '';
        final status = entry['status']?.toString() ?? '';
        final notificationStatus =
            entry['notificationStatus']?.toString() ?? 'pending';
        final notificationError = entry['notificationError']?.toString() ?? '';
        final notificationAttempts =
            entry['notificationAttempts']?.toString() ?? '0';
        final decidedAt = _formatTimestamp(entry['decidedAt']?.toString());
        final isApproved = status == 'approved';
        final isNotificationFailed = notificationStatus == 'failed';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isApproved ? Colors.green : Colors.red,
            ),
            title: Text(name.isEmpty ? email : name),
            subtitle: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: $email | Category: $category'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusBadge(
                      label: status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
                      backgroundColor:
                          isApproved ? Colors.green.shade100 : Colors.red.shade100,
                      foregroundColor:
                          isApproved ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                    _StatusBadge(
                      label: notificationStatus.isEmpty
                          ? 'NOTIFICATION: PENDING'
                          : 'NOTIFICATION: ${notificationStatus.toUpperCase()}',
                      backgroundColor: _notificationBadgeColor(notificationStatus),
                      foregroundColor:
                          _notificationBadgeForeground(notificationStatus),
                    ),
                    _StatusBadge(
                      label: 'ATTEMPTS: $notificationAttempts',
                      backgroundColor: Colors.blueGrey.shade100,
                      foregroundColor: Colors.blueGrey.shade900,
                    ),
                  ],
                ),
                if (decidedAt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Decision time: $decidedAt'),
                ],
                if (notificationError.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Email error: $notificationError',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            trailing: isNotificationFailed
                ? OutlinedButton(
                    onPressed: () => _retryNotification(entry),
                    child: const Text('Retry email'),
                  )
                : null,
          ),
        );
      },
    );
  }

  Color _notificationBadgeColor(String notificationStatus) {
    switch (notificationStatus) {
      case 'sent':
        return Colors.green.shade100;
      case 'failed':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _notificationBadgeForeground(String notificationStatus) {
    switch (notificationStatus) {
      case 'sent':
        return Colors.green.shade900;
      case 'failed':
        return Colors.orange.shade900;
      default:
        return Colors.grey.shade800;
    }
  }

  String _formatTimestamp(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return '';
    }

    final dateTime = DateTime.tryParse(rawValue);
    if (dateTime == null) {
      return rawValue;
    }

    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year} $hour:$minute $period';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
            ),
          ),
        );
      },
    );
  }
}
