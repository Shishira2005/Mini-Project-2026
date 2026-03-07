import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/college_banner.dart';
import '../../../shared/widgets/app_background.dart';
import 'classroom_timetable_page.dart';

class ClassroomSettingsPage extends StatefulWidget {
  const ClassroomSettingsPage({super.key, required this.classroomName});

  final String classroomName;

  @override
  State<ClassroomSettingsPage> createState() => _ClassroomSettingsPageState();
}

class _ClassroomSettingsPageState extends State<ClassroomSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _batchController = TextEditingController();
  final _capacityController = TextEditingController();
  final _generalCrNameController = TextEditingController();
  final _generalCrAdmissionController = TextEditingController();
  final _ladyCrNameController = TextEditingController();
  final _ladyCrAdmissionController = TextEditingController();

  bool _hasProjector = false;
  bool _isLoading = false;

  late final ApiClient _apiClient;

  bool get _isSeminarHallOrWadLab {
    final name = widget.classroomName.toUpperCase();
    return name.contains('SEMINAR HALL') || name.contains('WAD LAB');
  }

  @override
  void initState() {
    super.initState();
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000',
    );
    _apiClient = ApiClient(baseUrl: apiBaseUrl);
    _loadSettings();
  }

  @override
  void dispose() {
    _batchController.dispose();
    _capacityController.dispose();
    _generalCrNameController.dispose();
    _generalCrAdmissionController.dispose();
    _ladyCrNameController.dispose();
    _ladyCrAdmissionController.dispose();
    super.dispose();
  }

  void _applyLoadedData(Map<String, dynamic> data) {
    if (!_isSeminarHallOrWadLab) {
      _batchController.text = (data['batch'] ?? '') as String;
      _generalCrNameController.text = (data['generalCrName'] ?? '') as String;
      _generalCrAdmissionController.text =
          (data['generalCrAdmission'] ?? '') as String;
      _ladyCrNameController.text = (data['ladyCrName'] ?? '') as String;
      _ladyCrAdmissionController.text = (data['ladyCrAdmission'] ?? '') as String;
    }

    final capacity = data['capacity'];
    if (capacity != null) {
      _capacityController.text = capacity.toString();
    }
    _hasProjector = (data['hasProjector'] ?? false) as bool;
  }

  Future<void> _loadSettingsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'classroom_settings_${widget.classroomName}';
    final stored = prefs.getString(key);
    if (stored == null || !mounted) return;

    final data = jsonDecode(stored) as Map<String, dynamic>;
    setState(() {
      _applyLoadedData(data);
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.get(
        '/api/admin/classroom-settings/${Uri.encodeComponent(widget.classroomName)}',
      ) as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _applyLoadedData(data);
      });

      // Cache latest settings locally for offline use.
      final prefs = await SharedPreferences.getInstance();
      final key = 'classroom_settings_${widget.classroomName}';
      await prefs.setString(key, jsonEncode(data));
    } catch (_) {
      // If backend is unreachable, fall back to locally cached values.
      await _loadSettingsFromLocal();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final data = <String, dynamic>{
      'capacity': int.parse(_capacityController.text.trim()),
      'hasProjector': _hasProjector,
    };

    if (!_isSeminarHallOrWadLab) {
      data.addAll({
        'batch': _batchController.text.trim(),
        'generalCrName': _generalCrNameController.text.trim(),
        'generalCrAdmission': _generalCrAdmissionController.text.trim(),
        'ladyCrName': _ladyCrNameController.text.trim(),
        'ladyCrAdmission': _ladyCrAdmissionController.text.trim(),
      });
    }

    try {
      await _apiClient.put(
        '/api/admin/classroom-settings/${Uri.encodeComponent(widget.classroomName)}',
        body: data,
      ) as Map<String, dynamic>;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }

    // Always cache the latest values locally as well.
    final prefs = await SharedPreferences.getInstance();
    final key = 'classroom_settings_${widget.classroomName}';
    await prefs.setString(key, jsonEncode(data));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved settings for ${widget.classroomName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSeminarHallOrWadLab = _isSeminarHallOrWadLab;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.classroomName} Settings')),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.12,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    child: Icon(
                                      Icons.meeting_room_outlined,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.classroomName,
                                          style: theme
                                              .textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isSeminarHallOrWadLab
                                              ? 'Hall settings and capacity'
                                              : 'Classroom batch, capacity and CR details',
                                          style: theme
                                              .textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (!isSeminarHallOrWadLab) ...[
                                Text(
                                  'Batch details',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _batchController,
                                  decoration: const InputDecoration(
                                    labelText: 'Batch in the Class',
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              Text(
                                'Room configuration',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _capacityController,
                                decoration: const InputDecoration(
                                  labelText: 'Capacity of Class / Hall',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter capacity';
                                  }
                                  final parsed = int.tryParse(value.trim());
                                  if (parsed == null || parsed <= 0) {
                                    return 'Enter a valid positive number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Projector availability'),
                                value: _hasProjector,
                                onChanged: (value) {
                                  setState(() => _hasProjector = value);
                                },
                              ),
                              if (!isSeminarHallOrWadLab) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Class representatives',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add the names and admission numbers of the General and Lady CRs.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _generalCrNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name of General CR',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _generalCrAdmissionController,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Admission Number of General CR',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _ladyCrNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name of Lady CR',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _ladyCrAdmissionController,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'Admission Number of Lady CR',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _save,
                                      child: const Text('Save settings'),
                                    ),
                                  ),
                                  if (!isSeminarHallOrWadLab) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ClassroomTimetablePage(
                                                classroomName:
                                                    widget.classroomName,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.grid_view),
                                        label: const Text('Set time table'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
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
