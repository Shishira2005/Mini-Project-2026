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
      final data =
          await _apiClient.get('/api/admin/accounts/verification-history')
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
        final decidedAt = entry['decidedAt']?.toString() ?? '';
        final isApproved = status == 'approved';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isApproved ? Colors.green : Colors.red,
            ),
            title: Text(name.isEmpty ? email : name),
            subtitle: Text(
              'Email: $email | Category: $category\nStatus: ${status.toUpperCase()}${decidedAt.isEmpty ? '' : ' | $decidedAt'}',
            ),
          ),
        );
      },
    );
  }
}
