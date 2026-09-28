import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/repositories/mock_firestore_repository.dart';

class AddContactDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const AddContactDialog({super.key, required this.onSaved});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relationship = 'Parent';
  bool _isPrimary = false;
  bool _receiveAutoCall = true;

  final _relationships = ['Parent', 'Spouse', 'Sibling', 'Friend', 'Police', 'Colleague'];

  void _saveContact() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and valid phone number.')),
      );
      return;
    }

    final newContact = EmergencyContact(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      relationship: _relationship,
      isPrimary: _isPrimary,
      receiveAutoCall: _receiveAutoCall,
    );

    try {
      await SafeStorageRepository.addContact(newContact);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Emergency Guardian', style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Guardian Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (with Country Code)',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+1234567890',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              dropdownColor: AppColors.surfaceVariant,
              items: _relationships.map((r) {
                return DropdownMenuItem(value: r, child: Text(r));
              }).toList(),
              onChanged: (val) => setState(() => _relationship = val ?? 'Parent'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Designate as Primary Guardian', style: TextStyle(fontSize: 13)),
              value: _isPrimary,
              activeColor: AppColors.emergencyRed,
              onChanged: (val) => setState(() => _isPrimary = val),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-call during emergency', style: TextStyle(fontSize: 13)),
              value: _receiveAutoCall,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _receiveAutoCall = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          child: const Text('Save Guardian'),
        ),
      ],
    );
  }
}
