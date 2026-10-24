import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class BiometricDevicesScreen extends ConsumerStatefulWidget {
  const BiometricDevicesScreen({super.key});

  @override
  ConsumerState<BiometricDevicesScreen> createState() => _BiometricDevicesScreenState();
}

class _BiometricDevicesScreenState extends ConsumerState<BiometricDevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).loadBiometricDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);
    final devices = state.biometricDevices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Biometric Devices & Sync',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.tealAccent),
            onPressed: () => ref.read(superAdminProvider.notifier).loadBiometricDevices(),
          ),
        ],
      ),
      body: state.isLoading && devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? Center(
                  child: Text('No biometric terminals configured.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  itemBuilder: (ctx, index) {
                    final dev = devices[index];
                    return _buildDeviceCard(dev);
                  },
                ),
    );
  }

  Widget _buildDeviceCard(SuperAdminBiometricModel dev) {
    final isOnline = dev.status == 'ONLINE';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOnline ? AppColors.emerald.withOpacity(0.3) : AppColors.rose.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Colors.tealAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dev.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      '${dev.schoolName ?? 'School Terminal'} • ID: ${dev.deviceId}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.emerald : AppColors.rose).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dev.status,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isOnline ? AppColors.emerald : AppColors.rose,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Location: ${dev.location ?? 'Campus Gate'}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
              Text('Battery: ${dev.batteryPercent}%', style: GoogleFonts.inter(fontSize: 12, color: AppColors.emerald)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last Sync: ${dev.lastSyncAt != null ? dev.lastSyncAt!.toLocal().toString().split('.')[0] : 'Never'}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Sync Terminal Logs Now'),
              onPressed: () => ref.read(superAdminProvider.notifier).syncBiometric(dev.id),
            ),
          ),
        ],
      ),
    );
  }
}
