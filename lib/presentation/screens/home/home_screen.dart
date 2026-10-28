import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/emergency_session.dart';
import '../../../data/models/user_settings.dart';
import '../../../services/emergency_orchestrator.dart';
import '../../widgets/pulse_panic_button.dart';
import '../contacts/emergency_contacts_screen.dart';
import '../disguise/fake_calculator_screen.dart';
import '../disguise/fake_low_battery_screen.dart';
import '../tracking/live_tracking_map_screen.dart';
import '../vault/encrypted_vault_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _launchDisguise(BuildContext context, DisguiseType type) {
    if (type == DisguiseType.calculator) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FakeCalculatorScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FakeLowBatteryScreen()),
      );
    }
  }

  void _promptCancelSos(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Resolve Emergency SOS', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your 4-digit Master Safe PIN to safely stand down and archive this incident.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 6, color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
              onPressed: () async {
                final orchestrator = context.read<EmergencyOrchestrator>();
                final success = await orchestrator.resolveEmergency(pinController.text);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency resolved and logged into secure vault.')),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Safe PIN! Emergency remains active.')),
                  );
                }
              },
              child: const Text('Resolve & Stand Down'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orchestrator = context.watch<EmergencyOrchestrator>();
    final isSosActive = orchestrator.isSosActive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/app_logo.png', height: 32, width: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text(AppStrings.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active SOS Emergency Header Banner
            if (isSosActive)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emergencyDarkRed,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergencyRed.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.activeSosTitle,
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            AppStrings.activeSosSubtitle,
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.emergencyDarkRed,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _promptCancelSos(context),
                      child: const Text('Resolve', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Guardian Status & Trigger Quick Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 5,
                        backgroundColor: isSosActive ? AppColors.emergencyRed : AppColors.safeGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSosActive ? 'Status: SOS TRIGGERED' : 'System: Shield Active',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (orchestrator.contacts.isEmpty)
                    const Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: AppColors.warningOrange, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'No Guardians!',
                          style: TextStyle(fontSize: 11, color: AppColors.warningOrange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${orchestrator.contacts.length} Guardians Linked',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),

            const Spacer(),

            // Animated Center Panic Button
            PulsePanicButton(
              isSosActive: isSosActive,
              onTriggered: () {
                orchestrator.triggerEmergency(SosTriggerType.panicButton);
                _launchDisguise(context, orchestrator.settings.preferredDisguise);
              },
            ),

            const SizedBox(height: 16),
            Text(
              isSosActive
                  ? 'Silent emergency loop active'
                  : AppStrings.panicHoldInstruction,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),

            const Spacer(),

            // Disguise & Navigation Quick Actions Grid
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Disguise Decoy Mode Quick Launch
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Open Disguise Mode (Calculator Decoy)'),
                      onPressed: () {
                        if (isSosActive) {
                          orchestrator.enterDecoyMode();
                        }
                        _launchDisguise(context, orchestrator.settings.preferredDisguise);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Nav Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavTile(
                        icon: Icons.people_alt_outlined,
                        label: 'Guardians',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                          );
                        },
                      ),
                      _buildNavTile(
                        icon: Icons.location_on_outlined,
                        label: 'Live GPS',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LiveTrackingMapScreen()),
                          );
                        },
                      ),
                      _buildNavTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Vault',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EncryptedVaultScreen()),
                          );
                        },
                      ),
                      _buildNavTile(
                        icon: Icons.vibration_rounded,
                        label: 'Triggers',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
