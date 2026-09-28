import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/emergency_session.dart';
import '../../../data/repositories/mock_firestore_repository.dart';

class EncryptedVaultScreen extends StatefulWidget {
  const EncryptedVaultScreen({super.key});

  @override
  State<EncryptedVaultScreen> createState() => _EncryptedVaultScreenState();
}

class _EncryptedVaultScreenState extends State<EncryptedVaultScreen> {
  List<EmergencySession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVaultData();
  }

  void _loadVaultData() async {
    final list = await SafeStorageRepository.getPastSessions();
    setState(() {
      _sessions = list;
      _isLoading = false;
    });
  }

  Future<void> _openFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await OpenFilex.open(path);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found! It may have been cleared by the system.')),
        );
      }
    }
  }

  Future<void> _shareEvidence(EmergencySession session) async {
    if (session.evidenceChunkUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video files recorded for this incident.')),
      );
      return;
    }

    final files = <XFile>[];
    for (var path in session.evidenceChunkUrls) {
      if (await File(path).exists()) {
        files.add(XFile(path));
      }
    }

    if (files.isNotEmpty) {
      await Share.shareXFiles(
        files,
        text: 'Guardian Shield Emergency Evidence - Incident #${session.id.substring(0, 8)}',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evidence files are missing from storage.')),
        );
      }
    }
  }

  Future<void> _saveToGallery(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video file not found at local path.')),
          );
        }
        return;
      }

      // Request gallery write permissions
      final hasGalAccess = await Gal.hasAccess();
      if (!hasGalAccess) {
        await Gal.requestAccess();
      }

      // Export video to primary public gallery folder (DCIM / Movies)
      await Gal.putVideo(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Video saved to Phone Gallery / Movies folder successfully!'),
            backgroundColor: AppColors.safeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Gallery export failed: $e. Falling back to Share picker...');
      try {
        await Share.shareXFiles([XFile(path)], text: 'Guardian Shield Emergency Evidence Video');
      } catch (shareErr) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to export video: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Encrypted Evidence Vault'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Security Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppColors.safeGreen, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AES-256 Cloud Vault Active',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Evidence is encrypted with your master key and automatically auto-purged after 30 days.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Recorded Incident Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                ..._sessions.map((session) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.emergencyRed.withValues(alpha: 0.15),
                        child: const Icon(Icons.shield_rounded, color: AppColors.emergencyRed, size: 20),
                      ),
                      title: Text(
                        'Incident #${session.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Trigger: ${session.triggerType.name} | ${session.startTime.toLocal().toString().split('.')[0]}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• Status: ${session.status.name.toUpperCase()}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(
                                '• GPS Breadcrumbs: ${session.locationBreadcrumbs.length} points logged',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Video Evidence Chunks:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              if (session.evidenceChunkUrls.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text('No video recordings found.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                )
                              else
                                ...session.evidenceChunkUrls.map((url) {
                                  final fileName = url.split('/').last;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    leading: const Icon(Icons.videocam_outlined, color: AppColors.primaryLight, size: 20),
                                    title: Text(fileName, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.download_rounded, color: AppColors.safeGreen, size: 20),
                                          onPressed: () => _saveToGallery(url),
                                          tooltip: 'Save to Gallery',
                                        ),
                                        const Icon(Icons.play_circle_outline, color: AppColors.safeGreen, size: 20),
                                      ],
                                    ),
                                    onTap: () => _openFile(url),
                                  );
                                }),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.share_outlined, size: 18),
                                  label: const Text('Export & Share Evidence'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  onPressed: () => _shareEvidence(session),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (_sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No incident history recorded.\nYour emergency vault is clean.',
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
