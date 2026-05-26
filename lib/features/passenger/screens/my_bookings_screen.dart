import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .where('passengerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
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
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppTheme.textSecondary),
                SizedBox(height: 16),
                Text('Chưa có đặt chỗ nào',
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return AppTheme.success;
      case 'rejected': return AppTheme.error;
      case 'completed': return AppTheme.secondary;
      default: return AppTheme.warning;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'confirmed': return 'Đã xác nhận';
      case 'rejected': return 'Bị từ chối';
      case 'completed': return 'Hoàn thành';
      default: return 'Chờ xác nhận';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.from} → ${booking.to}',
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
                  color: _statusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(booking.status),
                  style: TextStyle(
                    color: _statusColor(booking.status),
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
          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 15, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('HH:mm - dd/MM/yyyy')
                    .format(booking.departureTime),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${booking.seats} ghế',
                  style: const TextStyle(fontSize: 13)),
              Text(
                NumberFormat('#,###đ').format(booking.totalPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}