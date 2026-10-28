import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/security/pin_vault_service.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/repositories/mock_firestore_repository.dart';
import '../../../services/emergency_orchestrator.dart';
import '../auth/child_safety_login_screen.dart';
import '../payment/premium_subscription_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings _settings = UserSettings();
  bool _isLoading = true;

  String get _currentUserEmail {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance.currentUser?.email ?? 'Guardian User';
      }
    } catch (_) {}
    return 'Guardian User';
  }

  bool get _isUserSignedIn {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance.currentUser != null;
      }
    } catch (_) {}
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final s = await SafeStorageRepository.getUserSettings();
    setState(() {
      _settings = s;
      _isLoading = false;
    });
  }

  void _saveSettings() async {
    await SafeStorageRepository.saveUserSettings(_settings);
    if (mounted) {
      context.read<EmergencyOrchestrator>().reloadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully.')),
      );
    }
  }

  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Update Master PIN', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'Current PIN'),
                ),
                TextField(
                  controller: newPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'New 4-Digit PIN'),
                ),
                TextField(
                  controller: confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'Confirm New PIN'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final isOldCorrect = await PinVaultService.verifyMasterPin(oldPinController.text);
                if (!isOldCorrect) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current PIN is incorrect.')));
                  return;
                }
                if (newPinController.text.length != 4 || newPinController.text != confirmPinController.text) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New PINs must match and be 4 digits.')));
                  return;
                }

                // Get current decoy pin to preserve it
                final currentDecoy = await PinVaultService.getDecoyPin();
                await PinVaultService.setupPins(masterPin: newPinController.text, decoyPin: currentDecoy);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Master PIN updated successfully.')));
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety & Trigger Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppColors.safeGreen),
            onPressed: _saveSettings,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Trigger Hardware Toggles
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SILENT TRIGGER MECHANISMS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Triple Shake Trigger (3x)'),
                          subtitle: const Text(
                            'Shake device rapidly 3 times to trigger silent SOS',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          value: _settings.shakeTriggerEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _settings.shakeTriggerEnabled = val),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Volume Key Rapid Press'),
                          subtitle: const Text(
                            'Press volume key 3 times in locked mode',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          value: _settings.volumeKeyTriggerEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _settings.volumeKeyTriggerEnabled = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Disguise & Decoy Preference
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DECOY DISGUISE MODE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<DisguiseType>(
                          value: _settings.preferredDisguise,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Disguise Screen during SOS',
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: AppColors.surfaceVariant,
                          items: const [
                            DropdownMenuItem(
                              value: DisguiseType.calculator,
                              child: Text('Functional Calculator Decoy', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: DisguiseType.lowBattery,
                              child: Text('Simulated Low Battery Decoy', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: DisguiseType.blackScreen,
                              child: Text('Pure Black AMOLED Blank Screen', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (val) => setState(() => _settings.preferredDisguise = val!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Auto-Call Configuration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AUTOMATED CALLING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Auto-call Primary Guardian'),
                          subtitle: Text(
                            'Initiates direct phone call ${_settings.autoCallDelaySeconds}s after SOS trigger',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          value: _settings.autoCallEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _settings.autoCallEnabled = val),
                        ),
                      ],
                    ),
                  ),
                ),
                // Evidence & Performance
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EVIDENCE COLLECTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Video Recording Duration',
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const Text(
                          'Saves video in smaller chunks to ensure preservation',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Slider(
                          value: _settings.videoChunkDurationSeconds.toDouble(),
                          min: 15,
                          max: 120,
                          divisions: 7,
                          label: '${_settings.videoChunkDurationSeconds}s per chunk',
                          activeColor: AppColors.primary,
                          onChanged: (val) => setState(() => _settings.videoChunkDurationSeconds = val.toInt()),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.cardBorder),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Security Access Keys'),
                          subtitle: const Text('Change your Master Safe PIN used to unlock the vault', style: TextStyle(fontSize: 11)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryLight),
                          onTap: _showChangePinDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Premium Protection Subscription Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PREMIUM PROTECTION TIER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.stars_rounded, color: Colors.white),
                          ),
                          title: Text(
                            _settings.isPremiumUser ? 'Active Plan: ${_settings.subscriptionType.toUpperCase()}' : 'Early Bird Founders Plan - ₹199/Yr',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            _settings.isPremiumUser
                                ? 'Expires: ${_settings.subscriptionExpiry ?? "Active"}'
                                : 'First 5,000 Users Special Offer! Tap to upgrade.',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryLight),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PremiumSubscriptionScreen()),
                            );
                            _loadSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Account & Authentication Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACCOUNT & SECURITY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.surfaceVariant,
                            child: Icon(Icons.person_rounded, color: AppColors.primaryLight),
                          ),
                          title: Text(
                            _currentUserEmail,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(
                            _isUserSignedIn ? 'Connected to Guardian Shield Cloud' : 'Not signed in',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.emergencyGlow,
                              side: const BorderSide(color: AppColors.emergencyDarkRed),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign Out of Account'),
                            onPressed: () async {
                              try {
                                if (Firebase.apps.isNotEmpty) {
                                  await FirebaseAuth.instance.signOut();
                                }
                              } catch (_) {}
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChildSafetyLoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
