import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/repositories/mock_firestore_repository.dart';
import '../../../services/emergency_orchestrator.dart';
import '../../../services/razorpay_payment_service.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final RazorpayPaymentService _paymentService = RazorpayPaymentService();
  UserSettings _settings = UserSettings();
  bool _isLoading = true;
  String _selectedPlan = 'freeTrial30'; // 'freeTrial30', 'earlyBird199', 'monthly49', 'annual500'

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _loadSettings() async {
    final s = await SafeStorageRepository.getUserSettings();
    setState(() {
      _settings = s;
      _isLoading = false;
    });
  }

  void _activateFreeTrial() async {
    final now = DateTime.now();
    final expiryDate = now.add(const Duration(days: 30));

    _settings.isPremiumUser = true;
    _settings.subscriptionType = 'Free Trial (1 Month)';
    _settings.subscriptionExpiry = "${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";

    await SafeStorageRepository.saveUserSettings(_settings);

    if (mounted) {
      context.read<EmergencyOrchestrator>().reloadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 1-Month Free Trial Activated! Protection active until ${_settings.subscriptionExpiry}'),
          backgroundColor: AppColors.safeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final now = DateTime.now();
    DateTime expiryDate;
    if (_selectedPlan == 'monthly49') {
      expiryDate = now.add(const Duration(days: 30));
    } else {
      expiryDate = now.add(const Duration(days: 365));
    }

    _settings.isPremiumUser = true;
    _settings.subscriptionType = _selectedPlan;
    _settings.subscriptionExpiry = "${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";
    _settings.registeredUserCount = _settings.registeredUserCount + 1;

    await SafeStorageRepository.saveUserSettings(_settings);

    if (mounted) {
      context.read<EmergencyOrchestrator>().reloadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Payment Successful! ID: ${response.paymentId}. Premium Activated!'),
          backgroundColor: AppColors.safeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message ?? "User cancelled transaction"}'),
          backgroundColor: AppColors.emergencyRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected Wallet: ${response.walletName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startRazorpayPayment() {
    if (_selectedPlan == 'freeTrial30') {
      _activateFreeTrial();
      return;
    }

    double price = 199;
    String name = 'Early Bird 1-Year Pass (First 5000 Users)';

    if (_selectedPlan == 'monthly49') {
      price = 49;
      name = 'Monthly Premium Membership';
    } else if (_selectedPlan == 'annual500') {
      price = 500;
      name = 'Annual Standard Membership';
    }

    _paymentService.openCheckout(
      amountInRupees: price,
      planName: name,
      userEmail: 'guardian.user@app.com',
      userContact: '9876543210',
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSpots = (5000 - _settings.registeredUserCount).clamp(0, 5000);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guardian Shield Premium'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          Color(0xFF1A237E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 48, color: Colors.white),
                        const SizedBox(height: 10),
                        const Text(
                          'UNLIMITED PROTECTION',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enable Instant Cloud Vault Sync, Direct Emergency Hotline & Advanced Decoy Customization',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                        ),
                        if (_settings.isPremiumUser) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.safeGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'Active Plan: ${_settings.subscriptionType.toUpperCase()} (Expires: ${_settings.subscriptionExpiry ?? "Active"})',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Early Bird Special Banner (First 5,000 Users)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.emergencyDarkRed.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emergencyRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: AppColors.emergencyGlow, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Early Bird Founders Special!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'First 5,000 Users pay only ₹199 for 1 Full Year! ($remainingSpots / 5000 spots left)',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Select Plan Tier',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Plan Option 0: 1-Month Free Trial
                  Card(
                    color: _selectedPlan == 'freeTrial30' ? AppColors.surfaceVariant : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedPlan == 'freeTrial30' ? AppColors.warningOrange : AppColors.cardBorder,
                        width: _selectedPlan == 'freeTrial30' ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: 'freeTrial30',
                      groupValue: _selectedPlan,
                      activeColor: AppColors.warningOrange,
                      onChanged: (val) => setState(() => _selectedPlan = val!),
                      title: Row(
                        children: [
                          const Text('1-Month Free Trial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.warningOrange, borderRadius: BorderRadius.circular(4)),
                            child: const Text('FREE 30 DAYS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                        ],
                      ),
                      subtitle: const Text('₹0 for 30 Days (Then ₹49/month or ₹500/year)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      secondary: const Text('₹0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.warningOrange)),
                    ),
                  ),

                  // Plan Option 1: Early Bird ₹199 / 1 Year
                  Card(
                    color: _selectedPlan == 'earlyBird199' ? AppColors.surfaceVariant : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedPlan == 'earlyBird199' ? AppColors.safeGreen : AppColors.cardBorder,
                        width: _selectedPlan == 'earlyBird199' ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: 'earlyBird199',
                      groupValue: _selectedPlan,
                      activeColor: AppColors.safeGreen,
                      onChanged: (val) => setState(() => _selectedPlan = val!),
                      title: Row(
                        children: [
                          const Text('Early Bird Founders Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.safeGreen, borderRadius: BorderRadius.circular(4)),
                            child: const Text('SAVE 60%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      subtitle: const Text('₹199 / 1 Year (First 5,000 Users Only)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      secondary: const Text('₹199', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.safeGreen)),
                    ),
                  ),

                  // Plan Option 2: Monthly ₹49 / Month
                  Card(
                    color: _selectedPlan == 'monthly49' ? AppColors.surfaceVariant : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedPlan == 'monthly49' ? AppColors.primary : AppColors.cardBorder,
                        width: _selectedPlan == 'monthly49' ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: 'monthly49',
                      groupValue: _selectedPlan,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _selectedPlan = val!),
                      title: const Text('Standard Monthly Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('₹49 / Month (Billed Monthly after trial)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      secondary: const Text('₹49', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                    ),
                  ),

                  // Plan Option 3: Annual ₹500 / Year
                  Card(
                    color: _selectedPlan == 'annual500' ? AppColors.surfaceVariant : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _selectedPlan == 'annual500' ? AppColors.primary : AppColors.cardBorder,
                        width: _selectedPlan == 'annual500' ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: 'annual500',
                      groupValue: _selectedPlan,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _selectedPlan = val!),
                      title: const Text('Standard Annual Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('₹500 / 1 Year (Save ₹88 vs monthly)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      secondary: const Text('₹500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Features Included Checklist
                  const Text('All Plans Include:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  const FeatureRow(text: '⚡ Silent Background SMS Alerts (Direct Telephony)'),
                  const FeatureRow(text: '📍 Real-Time Google Maps / WhatsApp GPS Stream'),
                  const FeatureRow(text: '🎥 Unlimited Encrypted Video Evidence Cloud Vault'),
                  const FeatureRow(text: '🧮 Functional Calculator & Low Battery Decoy Disguises'),
                  const FeatureRow(text: '🔒 Duress PIN Anti-Coercion Stealth Mode'),
                  const SizedBox(height: 28),

                  // Razorpay Checkout Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPlan == 'freeTrial30' ? AppColors.warningOrange : AppColors.primary,
                        foregroundColor: _selectedPlan == 'freeTrial30' ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(_selectedPlan == 'freeTrial30' ? Icons.card_giftcard_rounded : Icons.payment_rounded),
                      label: Text(
                        _selectedPlan == 'freeTrial30'
                            ? 'Activate 1-Month Free Trial Now (₹0)'
                            : _selectedPlan == 'earlyBird199'
                                ? 'Pay ₹199 via Razorpay (UPI / Card / NetBanking)'
                                : _selectedPlan == 'monthly49'
                                    ? 'Pay ₹49 via Razorpay'
                                    : 'Pay ₹500 via Razorpay',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _startRazorpayPayment,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      '🔒 Secured 256-bit Encrypted Checkout by Razorpay',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class FeatureRow extends StatelessWidget {
  final String text;
  const FeatureRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.safeGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
