import 'package:flutter/material.dart';

import '../../../shared/widgets/app_background.dart';

enum _Floor { ground, first }

class BlueprintPage extends StatefulWidget {
  const BlueprintPage({super.key});

  @override
  State<BlueprintPage> createState() => _BlueprintPageState();
}

class _BlueprintPageState extends State<BlueprintPage> {
  _Floor _selectedFloor = _Floor.ground;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('College Blueprint'),
      ),
      body: AppBackground(
        opacity: 0.12,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Floor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Ground Floor'),
                    selected: _selectedFloor == _Floor.ground,
                    onSelected: (_) {
                      setState(() => _selectedFloor = _Floor.ground);
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('1st Floor'),
                    selected: _selectedFloor == _Floor.first,
                    onSelected: (_) {
                      setState(() => _selectedFloor = _Floor.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: _selectedFloor == _Floor.ground
                      ? _buildGroundFloorBlueprint()
                      : _buildFirstFloorBlueprint(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroundFloorBlueprint() {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 3,
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Image.asset(
          'assets/blueprints/ground_floor_blueprint.jpeg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFirstFloorBlueprint() {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 3,
      child: AspectRatio(
        aspectRatio: 3 / 2,
        child: Image.asset(
          'assets/blueprints/first floor blueprint.jpeg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
