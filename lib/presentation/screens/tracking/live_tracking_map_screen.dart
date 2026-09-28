import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/emergency_orchestrator.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  const LiveTrackingMapScreen({super.key});

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLocation();
    });
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await context.read<EmergencyOrchestrator>().fetchCurrentLocation();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orchestrator = context.watch<EmergencyOrchestrator>();
    final loc = orchestrator.currentLocation;
    final session = orchestrator.currentSession;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Emergency GPS Stream'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _refreshLocation,
            tooltip: 'Refresh GPS Fix',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Coordinate Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CURRENT COORDINATES',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: orchestrator.isSosActive
                                  ? AppColors.emergencyRed.withValues(alpha: 0.15)
                                  : AppColors.safeGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 3,
                                  backgroundColor: orchestrator.isSosActive
                                      ? AppColors.emergencyRed
                                      : AppColors.safeGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  orchestrator.isSosActive ? 'STREAMING' : 'IDLE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: orchestrator.isSosActive
                                        ? AppColors.emergencyRed
                                        : AppColors.safeGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc != null
                            ? '${loc.latitude.toStringAsFixed(6)}°, ${loc.longitude.toStringAsFixed(6)}°'
                            : 'Acquiring high-accuracy GPS fix...',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc != null
                            ? 'Accuracy: ±${loc.accuracy.toStringAsFixed(1)}m | Updated: ${loc.timestamp.toLocal().toString().split(' ')[1].split('.')[0]}'
                            : 'Ensuring line-of-sight to satellites',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      if (loc != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Open in Google Maps'),
                            onPressed: () {
                              launchUrl(
                                Uri.parse(loc.googleMapsUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Incident Location Breadcrumbs',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Breadcrumb History
              Expanded(
                child: session != null && session.locationBreadcrumbs.isNotEmpty
                    ? ListView.builder(
                        itemCount: session.locationBreadcrumbs.length,
                        itemBuilder: (context, index) {
                          final point = session.locationBreadcrumbs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.surfaceVariant,
                                child: Text('${index + 1}', style: const TextStyle(fontSize: 11)),
                              ),
                              title: Text(
                                '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                point.timestamp.toLocal().toString().split('.')[0],
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.launch, size: 18, color: AppColors.primaryLight),
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(point.googleMapsUrl),
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text(
                          'No location breadcrumbs recorded yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
