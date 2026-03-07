import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../auth/models/auth_user.dart';
import '../models/swap_models.dart';
import '../services/swap_api_service.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class SwapNotificationsPage extends StatefulWidget {
  const SwapNotificationsPage({super.key, required this.user});

  final AuthUser user;

  @override
  State<SwapNotificationsPage> createState() => _SwapNotificationsPageState();
}

class _SwapNotificationsPageState extends State<SwapNotificationsPage> {
  bool _loading = true;
  String? _error;
  List<SwapRequestModel> _items = <SwapRequestModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.user.role != UserRole.faculty) {
      setState(() {
        _loading = false;
        _error = 'Swap notifications are only available for faculty accounts.';
        _items = <SwapRequestModel>[];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    final apiClient = ApiClient(baseUrl: apiBaseUrl);
    final swapApi = SwapApiService(apiClient);

    try {
      final items = await swapApi.fetchNotifications(
        facultyId: widget.user.loginId,
      );
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load swap notifications.';
      });
    }
  }

  Future<void> _updateStatus(SwapRequestModel item, String action) async {
    setState(() {
      _loading = true;
    });

    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    final apiClient = ApiClient(baseUrl: apiBaseUrl);
    final swapApi = SwapApiService(apiClient);

    try {
      await swapApi.updateRequestStatus(
        requestId: item.id,
        action: action,
      );
      await _load();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to update swap request.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap notifications'),
      ),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.2,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No pending swap requests.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final date = DateTime.tryParse(item.date);
        final dateLabel = date == null
            ? item.date
            : '${date.day}/${date.month}/${date.year} ${item.startTime}-${item.endTime}';

        return Card(
          child: ListTile(
            title: Text(dateLabel),
            subtitle: Text(
              '${item.requesterFacultyName} requests to swap\n'
              'From ${item.requesterClassroomName} to ${item.targetClassroomName}\n'
              'Reason: ${item.reason}',
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _updateStatus(item, 'accept'),
                  tooltip: 'Accept',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _updateStatus(item, 'reject'),
                  tooltip: 'Reject',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
