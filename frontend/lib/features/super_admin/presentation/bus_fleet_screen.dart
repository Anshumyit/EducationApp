import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../models/super_admin_models.dart';
import '../providers/super_admin_provider.dart';

class BusFleetScreen extends ConsumerStatefulWidget {
  const BusFleetScreen({super.key});

  @override
  ConsumerState<BusFleetScreen> createState() => _BusFleetScreenState();
}

class _BusFleetScreenState extends ConsumerState<BusFleetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).loadBuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);
    final buses = state.buses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Bus Fleet & GPS Telemetry',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.amber),
            onPressed: () => ref.read(superAdminProvider.notifier).loadBuses(),
          ),
        ],
      ),
      body: state.isLoading && buses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : buses.isEmpty
              ? Center(
                  child: Text('No fleet vehicles registered.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: buses.length,
                  itemBuilder: (ctx, index) {
                    final bus = buses[index];
                    return _buildBusCard(bus);
                  },
                ),
    );
  }

  Widget _buildBusCard(SuperAdminBusModel bus) {
    final isTrip = bus.status == 'ACTIVE_TRIP';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTrip ? AppColors.emerald.withOpacity(0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus_rounded, color: AppColors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.busNumber,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      '${bus.schoolName ?? 'School Bus'} • Reg: ${bus.registrationNumber}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isTrip ? AppColors.emerald : AppColors.amber).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bus.status.replaceAll('_', ' '),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isTrip ? AppColors.emerald : AppColors.amber,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Driver: ${bus.driverName ?? 'Assigned Driver'}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                  Text(bus.driverPhone ?? 'Contact N/A', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Speed: ${bus.currentSpeedKmph.toInt()} km/h', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.emerald)),
                  Text('${bus.latitude.toStringAsFixed(4)}, ${bus.longitude.toStringAsFixed(4)}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
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
              icon: const Icon(Icons.satellite_alt_rounded, size: 16),
              label: const Text('Simulate GPS Movement'),
              onPressed: () => ref.read(superAdminProvider.notifier).simulateBusMovement(bus.id),
            ),
          ),
        ],
      ),
    );
  }
}
