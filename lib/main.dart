import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'core/security/pin_vault_service.dart';
import 'services/emergency_orchestrator.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/legal_consent_screen.dart';
import 'presentation/screens/auth/child_safety_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safely initialize Firebase Services
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Set system overlays to dark styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Check if initial consent and PIN setup was completed
  final isConfigured = await PinVaultService.isConfigured();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmergencyOrchestrator()),
      ],
      child: GuardianShieldApp(isConfigured: isConfigured),
    ),
  );
}

class GuardianShieldApp extends StatelessWidget {
  final bool isConfigured;

  const GuardianShieldApp({super.key, required this.isConfigured});

  Widget _getInitialScreen() {
    if (!isConfigured) {
      return const LegalConsentScreen();
    }
    
    try {
      if (Firebase.apps.isNotEmpty) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          return const HomeScreen();
        }
      }
    } catch (e) {
      debugPrint('Auth check notice: $e');
    }
    
    return const ChildSafetyLoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _getInitialScreen(),
    );
  }
}
