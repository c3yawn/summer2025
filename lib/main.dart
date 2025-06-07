import 'package:care_connnect_prototype_v1/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:care_connnect_prototype_v1/screens/welcome_screen.dart';
import 'package:care_connnect_prototype_v1/screens/login_screen.dart';
import 'package:care_connnect_prototype_v1/screens/registration_screen.dart';
import 'package:care_connnect_prototype_v1/screens/password_reset_screen.dart';
import 'package:care_connnect_prototype_v1/screens/caregiver_dashboard.dart';
import 'package:care_connnect_prototype_v1/screens/patient_dashboard.dart';
import 'package:care_connnect_prototype_v1/theme/app_theme.dart';

void main() {
  runApp(const CareConnectApp());
}

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/password-reset': (context) => const PasswordResetScreen(),
        '/caregiver-dashboard': (context) => const CaregiverDashboard(),
        '/patient-dashboard': (context) => const PatientDashboard(),
      },
    );
  }
}
