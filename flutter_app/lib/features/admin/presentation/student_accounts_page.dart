import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_background.dart';

class StudentAccountsPage extends StatefulWidget {
  const StudentAccountsPage({super.key});

  @override
  State<StudentAccountsPage> createState() => _StudentAccountsPageState();
}

class _StudentAccountsPageState extends State<StudentAccountsPage> {
  late final ApiClient _apiClient;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiClient.get('/api/admin/accounts/representatives')
          as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _accounts = data.cast<Map<String, dynamic>>();
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
      appBar: AppBar(
        title: const Text('Student Accounts'),
      ),
      body: AppBackground(
        opacity: 0.12,
        child: RefreshIndicator(
          onRefresh: _loadAccounts,
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

    if (_accounts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'No representative accounts found. Configure General/Lady CR in classroom settings.',
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        final loginId = account['loginId']?.toString() ?? '';
        final name = account['name']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(name.isEmpty ? loginId : name),
            subtitle: Text('Admission Number: $loginId'),
          ),
        );
      },
    );
  }
}
