import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/emergency_contact.dart';

class GuardianCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback? onDelete;
  final VoidCallback? onTestCall;

  const GuardianCard({
    super.key,
    required this.contact,
    this.onDelete,
    this.onTestCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary
              ? AppColors.emergencyRed.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.2),
          child: Icon(
            contact.isPrimary ? Icons.star_rounded : Icons.person_rounded,
            color: contact.isPrimary ? AppColors.emergencyRed : AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                contact.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (contact.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    color: AppColors.emergencyRed,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contact.phoneNumber,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Text(
              contact.relationship,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onTestCall != null)
              IconButton(
                icon: const Icon(Icons.phone_outlined, size: 20),
                color: AppColors.primaryLight,
                onPressed: onTestCall,
                tooltip: 'Test Call',
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.textMuted,
                onPressed: onDelete,
                tooltip: 'Remove',
              ),
          ],
        ),
      ),
    );
  }
}
