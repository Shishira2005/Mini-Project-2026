// Flutter entry point for the college room booking app.
import 'package:flutter/material.dart';

import 'features/splash/presentation/splash_page.dart';

void main() {
  runApp(const RoomBookingApp());
}

class RoomBookingApp extends StatelessWidget {
  const RoomBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LBS BOOKIFY',
      theme: ThemeData(useMaterial3: true),
      home: const SplashPage(),
    );
  }
}
