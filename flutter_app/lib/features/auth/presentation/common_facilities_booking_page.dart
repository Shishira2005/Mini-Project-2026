import 'package:flutter/material.dart';

import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/college_banner.dart';

class CommonFacilitiesBookingPage extends StatelessWidget {
  const CommonFacilitiesBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Common Facility Booking')),
      bottomNavigationBar: const CollegeBanner(),
      body: AppBackground(
        opacity: 0.18,
        child: Center(
          child: Text(
            'Common Facility Booking page will be added later.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
