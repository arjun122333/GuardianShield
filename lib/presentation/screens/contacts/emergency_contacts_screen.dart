import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/repositories/mock_firestore_repository.dart';
import '../../../services/emergency_orchestrator.dart';
import '../../../services/sms_alert_service.dart';
import '../../widgets/guardian_card.dart';
import 'add_contact_dialog.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() async {
    final list = await SafeStorageRepository.getContacts();
    setState(() {
      _contacts = list;
      _isLoading = false;
    });
    if (mounted) {
      context.read<EmergencyOrchestrator>().reloadSettings();
    }
  }

  void _deleteContact(String id) async {
    await SafeStorageRepository.deleteContact(id);
    _loadContacts();
  }

  void _testCall(String number) {
    SmsAlertService.launchEmergencyCall(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Guardians'),
      ),
      floatingActionButton: _contacts.length < 5
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Guardian'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddContactDialog(onSaved: _loadContacts),
                );
              },
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_contacts.length}/5 Guardians Configured. These contacts receive your live GPS link immediately during SOS.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact List
                ..._contacts.map((contact) {
                  return GuardianCard(
                    contact: contact,
                    onDelete: () => _deleteContact(contact.id),
                    onTestCall: () => _testCall(contact.phoneNumber),
                  );
                }),

                if (_contacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No guardians added yet.\nTap "+ Add Guardian" to configure emergency alerts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
