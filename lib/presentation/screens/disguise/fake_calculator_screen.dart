import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/security/pin_vault_service.dart';
import '../../../services/emergency_orchestrator.dart';

class FakeCalculatorScreen extends StatefulWidget {
  const FakeCalculatorScreen({super.key});

  @override
  State<FakeCalculatorScreen> createState() => _FakeCalculatorScreenState();
}

class _FakeCalculatorScreenState extends State<FakeCalculatorScreen> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;
  String _keystrokeHistory = '';

  void _onNumberTap(String number) {
    setState(() {
      _keystrokeHistory += number;
      if (_display == '0' || _shouldResetDisplay) {
        _display = number;
        _shouldResetDisplay = false;
      } else {
        _display += number;
      }
    });
  }

  void _onOperatorTap(String op) {
    setState(() {
      _keystrokeHistory += op;
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onClearTap() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
      _keystrokeHistory = '';
    });
  }

  void _onEqualsTap() async {
    final decoyPin = await PinVaultService.getDecoyPin();

    // Check if the secret unlock PIN was entered
    if (_keystrokeHistory.contains(decoyPin) || _display == decoyPin) {
      if (mounted) {
        _showSecretUnlockDialog();
        return;
      }
    }

    if (_firstOperand == null || _operator == null) return;
    final secondOperand = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        result = secondOperand != 0 ? _firstOperand! / secondOperand : 0;
        break;
    }

    setState(() {
      // Format clean integer if whole number
      _display = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = true;
    });
  }

  void _showSecretUnlockDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Safety Master Control',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your 4-digit Master Safe PIN to resolve emergency or exit disguise.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(fontSize: 22, letterSpacing: 8, color: Colors.white),
                textAlign: TextAlign.center,
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
              child: const Text('Cancel (Stay Hidden)'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
              onPressed: () async {
                final orchestrator = context.read<EmergencyOrchestrator>();
                final success = await orchestrator.resolveEmergency(pinController.text);
                if (!context.mounted) return;
                
                if (success) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Exit calculator
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect Safe PIN!')),
                  );
                }
              },
              child: const Text('Resolve Emergency'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orchestrator = context.watch<EmergencyOrchestrator>();
    final cameraController = orchestrator.cameraService.controller;

    return PopScope(
      canPop: false, // Prevent back button from exposing real app
      child: Scaffold(
        backgroundColor: AppColors.calcBg,
        body: SafeArea(
          child: Stack(
            children: [
              // Hidden Micro Camera Stream (0.01 opacity keeps texture active)
              if (cameraController != null && cameraController.value.isInitialized)
                Opacity(
                  opacity: 0.001,
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CameraPreview(cameraController),
                  ),
                ),

              // Actual Functional Calculator UI
              Column(
                children: [
                  // Calculator Display
                  Expanded(
                    child: Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Text(
                        _display,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Calculator Button Keypad
                  _buildButtonRow(['C', '±', '%', '÷'], [
                    AppColors.calcBtnGray,
                    AppColors.calcBtnGray,
                    AppColors.calcBtnGray,
                    AppColors.calcBtnOrange
                  ]),
                  _buildButtonRow(['7', '8', '9', '×'], [
                    AppColors.calcBtnDark,
                    AppColors.calcBtnDark,
                    AppColors.calcBtnDark,
                    AppColors.calcBtnOrange
                  ]),
                  _buildButtonRow(['4', '5', '6', '-'], [
                    AppColors.calcBtnDark,
                    AppColors.calcBtnDark,
                    AppColors.calcBtnDark,
                    AppColors.calcBtnOrange
                  ]),
                  _buildButtonRow(['1', '2', '3', '+'], [
                    AppColors.calcBtnDark,
                    AppColors.calcBtnDark,
                    AppColors.calcBtnDark,
                    AppColors.calcBtnOrange
                  ]),
                  _buildBottomRow(),
                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> labels, List<Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          return _buildCalcButton(
            label: labels[i],
            bgColor: colors[i],
            textColor: colors[i] == AppColors.calcBtnGray ? Colors.black : Colors.white,
            onTap: () {
              if (labels[i] == 'C') {
                _onClearTap();
              } else if (['+', '-', '×', '÷'].contains(labels[i])) {
                _onOperatorTap(labels[i]);
              } else {
                _onNumberTap(labels[i]);
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Wide 0 Button
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.calcBtnDark,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => _onNumberTap('0'),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text('0', style: TextStyle(fontSize: 28, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
          // Dot Button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildCalcButton(
                label: '.',
                bgColor: AppColors.calcBtnDark,
                textColor: Colors.white,
                onTap: () => _onNumberTap('.'),
              ),
            ),
          ),
          // Equals Button (The secret trigger trigger key)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildCalcButton(
                label: '=',
                bgColor: AppColors.calcBtnOrange,
                textColor: Colors.white,
                onTap: _onEqualsTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcButton({
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
