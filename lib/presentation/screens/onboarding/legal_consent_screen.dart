import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/security/pin_vault_service.dart';
import '../../../core/permissions/permission_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/child_safety_login_screen.dart';
import '../home/home_screen.dart';

class LegalConsentScreen extends StatefulWidget {
  const LegalConsentScreen({super.key});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _consentEmergencyRecording = false;
  bool _consentLocationSharing = false;
  final _masterPinController = TextEditingController(text: '1234');
  final _decoyPinController = TextEditingController(text: '9119');

  bool get _canProceed =>
      _consentEmergencyRecording &&
      _consentLocationSharing &&
      _masterPinController.text.length == 4 &&
      _decoyPinController.text.length == 4;

  void _onCompleteSetup() async {
    // 1. Save security PINs
    await PinVaultService.setupPins(
      masterPin: _masterPinController.text,
      decoyPin: _decoyPinController.text,
    );

    // 2. Request initial permissions
    await PermissionManager.requestEmergencyPermissions();

    if (mounted) {
      User? currentUser;
      try {
        if (Firebase.apps.isNotEmpty) {
          currentUser = FirebaseAuth.instance.currentUser;
        }
      } catch (_) {}

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => currentUser != null
              ? const HomeScreen()
              : const ChildSafetyLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety & Privacy Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 48,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  AppStrings.consentTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.consentSummary,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // PIN Configuration Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Security Access Keys',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _masterPinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Master Safe PIN (To resolve emergency)',
                          helperText: 'Default: 1234',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _decoyPinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: 'Decoy Calculator Trigger (e.g. 9119=)',
                          helperText: 'Type this number in calculator to unlock',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Explicit Consent Checkboxes
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consentEmergencyRecording,
                activeColor: AppColors.primary,
                title: const Text(
                  'I consent to silent camera recording strictly during user-initiated emergencies.',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                onChanged: (val) => setState(() => _consentEmergencyRecording = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consentLocationSharing,
                activeColor: AppColors.primary,
                title: const Text(
                  'I consent to sharing live GPS coordinates with my designated emergency contacts.',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                onChanged: (val) => setState(() => _consentLocationSharing = val ?? false),
              ),
              const SizedBox(height: 28),

              // Proceed Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed ? AppColors.primary : AppColors.surfaceVariant,
                  ),
                  onPressed: _canProceed ? _onCompleteSetup : null,
                  child: const Text('Agree & Initialize Protection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
