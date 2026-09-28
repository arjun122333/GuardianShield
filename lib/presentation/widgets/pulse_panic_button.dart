import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PulsePanicButton extends StatefulWidget {
  final VoidCallback onTriggered;
  final bool isSosActive;

  const PulsePanicButton({
    super.key,
    required this.onTriggered,
    this.isSosActive = false,
  });

  @override
  State<PulsePanicButton> createState() => _PulsePanicButtonState();
}

class _PulsePanicButtonState extends State<PulsePanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _holdProgress = 0.0;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    // Animate progress over 1.2s
    _animateHold();
  }

  void _animateHold() async {
    const totalSteps = 24;
    for (int i = 1; i <= totalSteps; i++) {
      if (!_isHolding) return;
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && _isHolding) {
        setState(() {
          _holdProgress = i / totalSteps;
        });
      }
    }

    if (_isHolding && mounted) {
      widget.onTriggered();
      setState(() {
        _isHolding = false;
        _holdProgress = 0.0;
      });
    }
  }

  void _onHoldEnd() {
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isSosActive ? AppColors.emergencyDarkRed : AppColors.emergencyRed;

    return Center(
      child: GestureDetector(
        onTapDown: (_) => _onHoldStart(),
        onTapUp: (_) => _onHoldEnd(),
        onTapCancel: _onHoldEnd,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = widget.isSosActive ? _pulseAnimation.value : 1.0;

            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow Ring
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyGlow.withValues(
                            alpha: widget.isSosActive ? 0.6 : 0.25,
                          ),
                          blurRadius: widget.isSosActive ? 40 : 25,
                          spreadRadius: widget.isSosActive ? 15 : 4,
                        ),
                      ],
                    ),
                  ),

                  // Circular Hold Progress Indicator
                  if (_isHolding)
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _holdProgress,
                        strokeWidth: 6,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),

                  // Main Button Core
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          activeColor,
                          const Color(0xFF8E0000),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isSosActive
                              ? Icons.shield_rounded
                              : Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.isSosActive ? 'SOS ACTIVE' : 'PRESS & HOLD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          widget.isSosActive
                              ? 'RECORDING'
                              : 'HOLD 1.2 SEC',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
