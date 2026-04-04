import 'package:flutter/material.dart';

import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class CommonFacilitiesHistoryPage extends StatelessWidget {
  const CommonFacilitiesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.18,
        child: Center(
          child: Text(
            'Booking history page will be added later.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
