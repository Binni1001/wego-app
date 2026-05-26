import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/trip_model.dart';

class ManageBookingsScreen extends StatelessWidget {
  final TripModel trip;
  const ManageBookingsScreen({super.key, required this.trip});

  Future<void> _updateBooking(
      BuildContext context,
      String bookingId,
      String status,
      int seats,
      ) async {
    final batch = FirebaseFirestore.instance.batch();

    // Cập nhật booking
    final bookingRef = FirebaseFirestore.instance
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId);
    batch.update(bookingRef, {'status': status});

    // Nếu từ chối → trả lại ghế
    if (status == AppConstants.bookingRejected) {
      final tripRef = FirebaseFirestore.instance
          .collection(AppConstants.tripsCollection)
          .doc(trip.id);
      batch.update(tripRef, {
        'availableSeats': FieldValue.increment(seats),
      });
    }

    await batch.commit();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status == AppConstants.bookingConfirmed
            ? '✅ Đã xác nhận hành khách'
            : '❌ Đã từ chối yêu cầu'),
        backgroundColor: status == AppConstants.bookingConfirmed
            ? AppTheme.success
            : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hành khách'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            color: AppTheme.primary.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.route,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${trip.from} → ${trip.to}  ·  '
                        '${DateFormat('HH:mm dd/MM').format(trip.departureTime)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.bookingsCollection)
            .where('tripId', isEqualTo: trip.id)
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search,
                      size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('Chưa có hành khách nào đặt',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      )),
                ],
              ),
            );
          }

          final bookings = docs
              .map((d) => BookingModel.fromMap(
              d.data() as Map<String, dynamic>, d.id))
              .toList();

          // Tổng kết
          final confirmed = bookings
              .where((b) =>
          b.status == AppConstants.bookingConfirmed)
              .length;
          final pending = bookings
              .where((b) =>
          b.status == AppConstants.bookingPending)
              .length;
          final totalRevenue = bookings
              .where((b) =>
          b.status == AppConstants.bookingConfirmed)
              .fold(0.0, (sum, b) => sum + b.totalPrice);

          return Column(
            children: [
              // Summary
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary,
                      Color(0xFF1a3a5c)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      label: 'Đã xác nhận',
                      value: '$confirmed',
                      icon: Icons.check_circle,
                      color: AppTheme.success,
                    ),
                    _SummaryItem(
                      label: 'Chờ duyệt',
                      value: '$pending',
                      icon: Icons.hourglass_empty,
                      color: AppTheme.warning,
                    ),
                    _SummaryItem(
                      label: 'Doanh thu',
                      value: NumberFormat('#,###đ')
                          .format(totalRevenue),
                      icon: Icons.payments_outlined,
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),

              // Danh sách
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: bookings.length,
                  itemBuilder: (_, i) => _BookingRequestCard(
                    booking: bookings[i],
                    onConfirm: () => _updateBooking(
                      context,
                      bookings[i].id,
                      AppConstants.bookingConfirmed,
                      bookings[i].seats,
                    ),
                    onReject: () => _updateBooking(
                      context,
                      bookings[i].id,
                      AppConstants.bookingRejected,
                      bookings[i].seats,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            )),
        Text(label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            )),
      ],
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  const _BookingRequestCard({
    required this.booking,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending =
        booking.status == AppConstants.bookingPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? AppTheme.warning.withOpacity(0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                AppTheme.secondary.withOpacity(0.1),
                child: Text(
                  booking.passengerName.isNotEmpty
                      ? booking.passengerName[0].toUpperCase()
                      : 'K',
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.passengerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
                    Text(booking.passengerPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        )),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${booking.seats} ghế',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                  Text(
                    NumberFormat('#,###đ')
                        .format(booking.totalPrice),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Nút xác nhận (chỉ hiện khi pending)
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(
                          color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.status ==
                      AppConstants.bookingConfirmed
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status ==
                      AppConstants.bookingConfirmed
                      ? '✅ Đã xác nhận'
                      : '❌ Đã từ chối',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: booking.status ==
                        AppConstants.bookingConfirmed
                        ? AppTheme.success
                        : AppTheme.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}