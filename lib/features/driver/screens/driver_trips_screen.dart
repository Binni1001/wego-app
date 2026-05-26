import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/models/trip_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'manage_bookings_screen.dart';

class DriverTripsScreen extends StatelessWidget {
  const DriverTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid =
        context.read<AuthProvider>().firebaseUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.tripsCollection)
          .where('driverId', isEqualTo: uid)
          .orderBy('departureTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car_outlined,
                    size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                const Text('Chưa có chuyến nào',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    )),
                const SizedBox(height: 8),
                const Text('Bấm "Đăng chuyến mới" để bắt đầu',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    )),
              ],
            ),
          );
        }

        final trips = docs
            .map((d) => TripModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (_, i) => _DriverTripCard(trip: trips[i]),
        );
      },
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  final TripModel trip;
  const _DriverTripCard({required this.trip});

  Color _statusColor(String status) {
    switch (status) {
      case 'full': return AppTheme.warning;
      case 'completed': return AppTheme.secondary;
      case 'cancelled': return AppTheme.error;
      default: return AppTheme.success;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'full': return 'Đầy chỗ';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã huỷ';
      default: return 'Đang mở';
    }
  }

  Future<void> _cancelTrip(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Huỷ chuyến?'),
        content: const Text(
            'Hành khách đã đặt sẽ bị huỷ. Bạn chắc chắn muốn huỷ chuyến này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Huỷ chuyến'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection(AppConstants.tripsCollection)
        .doc(trip.id)
        .update({'status': AppConstants.tripCancelled});
  }

  @override
  Widget build(BuildContext context) {
    final filledSeats = trip.totalSeats - trip.availableSeats;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.from} → ${trip.to}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(trip.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(trip.status),
                  style: TextStyle(
                    color: _statusColor(trip.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Info
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 15, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('HH:mm - dd/MM/yyyy')
                    .format(trip.departureTime),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ghế + Giá
          Row(
            children: [
              // Progress ghế
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$filledSeats/${trip.totalSeats} ghế đã đặt',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: trip.totalSeats > 0
                            ? filledSeats / trip.totalSeats
                            : 0,
                        backgroundColor:
                        const Color(0xFFE5E7EB),
                        color: AppTheme.primary,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                NumberFormat('#,###đ').format(trip.pricePerSeat),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const Text('/ghế',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ManageBookingsScreen(trip: trip),
                    ),
                  ),
                  icon: const Icon(Icons.people_outline, size: 16),
                  label: const Text('Hành khách'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondary,
                    side: const BorderSide(
                        color: AppTheme.secondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (trip.status == AppConstants.tripActive)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelTrip(context),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16),
                    label: const Text('Huỷ chuyến'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(
                          color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}