import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/emergency_orchestrator.dart';

class FakeLowBatteryScreen extends StatelessWidget {
  const FakeLowBatteryScreen({super.key});

  void _promptExit(BuildContext context) async {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Resolve Emergency'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'Enter 4-Digit Safe PIN',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final orchestrator = context.read<EmergencyOrchestrator>();
                final success = await orchestrator.resolveEmergency(pinController.text);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          // Secret triple tap anywhere on screen prompts unlock
          onDoubleTap: () => _promptExit(context),
          child: const SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.battery_alert_rounded,
                  color: Colors.redAccent,
                  size: 80,
                ),
                SizedBox(height: 16),
                Text(
                  'Battery critically low (1%)',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Shutting down device...',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
