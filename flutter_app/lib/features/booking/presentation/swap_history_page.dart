// List of previous room swap requests and their status.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../auth/models/auth_user.dart';
import '../models/swap_models.dart';
import '../services/swap_api_service.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class SwapHistoryPage extends StatefulWidget {
  const SwapHistoryPage({super.key, required this.user});

  final AuthUser user;

  @override
  State<SwapHistoryPage> createState() => _SwapHistoryPageState();
}

class _SwapHistoryPageState extends State<SwapHistoryPage> {
  bool _loading = true;
  String? _error;
  List<SwapRequestModel> _items = <SwapRequestModel>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      final facultyId =
          widget.user.role == UserRole.faculty ? widget.user.loginId : null;
      final items = await swapApi.fetchHistory(facultyId: facultyId);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load swap history.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap history'),
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
      return const Center(child: Text('No swap history.'));
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

        Color cardColor;
        switch (item.status) {
          case 'accepted':
            cardColor = Colors.blue.shade200; // Accepted swaps shown in blue
            break;
          case 'rejected':
          case 'cancelled':
            cardColor = Colors.red.shade100;
            break;
          default:
            cardColor = Colors.yellow.shade100;
        }

        return Card(
          color: cardColor,
          child: ListTile(
            title: Text(dateLabel),
            subtitle: Text(
              'From ${item.requesterClassroomName} (${item.requesterFacultyName})\n'
              'To ${item.targetClassroomName} (${item.targetFacultyName})\n'
              'Reason: ${item.reason}\n'
              'Status: ${item.status}',
            ),
          ),
        );
      },
    );
  }
}
