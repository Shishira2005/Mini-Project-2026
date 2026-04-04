// Admin page for approving or declining Common Facilities account requests.
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class AccountVerificationPage extends StatefulWidget {
  const AccountVerificationPage({super.key});

  @override
  State<AccountVerificationPage> createState() =>
      _AccountVerificationPageState();
}

class _AccountVerificationPageState extends State<AccountVerificationPage> {
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
          await _apiClient.get('/api/admin/accounts/verification')
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

  Future<void> _verifyAccount(Map<String, dynamic> account) async {
    final email = account['email']?.toString() ?? '';
    if (email.isEmpty) return;

    try {
      await _apiClient.patch(
        '/api/admin/accounts/verification/${Uri.encodeComponent(email)}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approved request for $email')));
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

  Future<void> _declineAccount(Map<String, dynamic> account) async {
    final email = account['email']?.toString() ?? '';
    if (email.isEmpty) return;

    try {
      await _apiClient.patch(
        '/api/admin/accounts/verification/${Uri.encodeComponent(email)}/decline',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Declined request for $email')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Verification')),
      bottomNavigationBar: const CollegeBanner(),
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
          Text('No Common Facilities requests are waiting for approval.'),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        final email = account['email']?.toString() ?? '';
        final name = account['name']?.toString() ?? '';
        final category = account['category']?.toString() ?? '';
        final subtitle = category.isEmpty
            ? 'Email: $email'
            : 'Email: $email | Category: $category';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(name.isEmpty ? email : name),
            subtitle: Text(subtitle),
            trailing: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _verifyAccount(account),
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  onPressed: () => _declineAccount(account),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
