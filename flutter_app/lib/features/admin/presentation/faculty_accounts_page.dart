// Admin list of faculty accounts fetched from the backend.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_background.dart';

class FacultyAccountsPage extends StatefulWidget {
  const FacultyAccountsPage({super.key});

  @override
  State<FacultyAccountsPage> createState() => _FacultyAccountsPageState();
}

class _FacultyAccountsPageState extends State<FacultyAccountsPage> {
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
      final data =
          await _apiClient.get('/api/admin/accounts/faculty') as List<dynamic>;

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

  Future<void> _deleteAccount(Map<String, dynamic> account) async {
    final loginId = account['loginId']?.toString() ?? '';
    if (loginId.isEmpty) return;

    final confirmed = await _showFirstConfirmation(loginId);
    if (confirmed != true) return;

    final typedLoginId = await _showSecondConfirmation(loginId);
    if (typedLoginId == null) return;

    if (typedLoginId.trim() != loginId.trim()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty ID does not match. Deletion cancelled.'),
        ),
      );
      return;
    }

    try {
      await _apiClient.delete(
        '/api/admin/accounts/faculty/${Uri.encodeComponent(loginId)}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted faculty account: $loginId')),
      );
      await _loadAccounts();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<bool?> _showFirstConfirmation(String loginId) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete faculty account?'),
          content: Text(
            'This will permanently remove the faculty account for $loginId. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showSecondConfirmation(String loginId) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Type the Faculty ID to confirm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter $loginId to confirm permanent deletion.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Confirm Faculty ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final typed = controller.text.trim();
                if (typed.isEmpty) return;
                Navigator.of(context).pop(typed);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Accounts')),
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
        children: const [Text('No faculty accounts found in the system.')],
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
            leading: const Icon(Icons.school_outlined),
            title: Text(name.isEmpty ? loginId : name),
            subtitle: Text('Faculty ID: $loginId'),
            trailing: OutlinedButton(
              onPressed: () => _deleteAccount(account),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ),
        );
      },
    );
  }
}
