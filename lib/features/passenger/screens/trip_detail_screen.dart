import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/models/trip_model.dart';
import '../../shared/models/booking_model.dart';
import '../../auth/providers/auth_provider.dart';

class TripDetailScreen extends StatefulWidget {
  final TripModel trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _selectedSeats = 1;
  bool _isBooking = false;

  Future<void> _bookTrip() async {
    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    if (user == null) return;

    setState(() => _isBooking = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Tạo booking
      final bookingRef = FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .doc();

      final booking = BookingModel(
        id: bookingRef.id,
        tripId: widget.trip.id,
        passengerId: user.uid,
        passengerName: user.name,
        passengerPhone: user.phone,
        seats: _selectedSeats,
        totalPrice: widget.trip.pricePerSeat * _selectedSeats,
        status: AppConstants.bookingPending,
        createdAt: DateTime.now(),
        from: widget.trip.from,
        to: widget.trip.to,
        departureTime: widget.trip.departureTime,
      );

      batch.set(bookingRef, booking.toMap());

      // Giảm ghế trống
      final tripRef = FirebaseFirestore.instance
          .collection(AppConstants.tripsCollection)
          .doc(widget.trip.id);

      batch.update(tripRef, {
        'availableSeats':
        widget.trip.availableSeats - _selectedSeats,
      });

      await batch.commit();

      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Đặt chỗ thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            const Text(
              'Đang chờ tài xế xác nhận.\nBạn sẽ nhận thông báo sớm nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Xem đặt chỗ của tôi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final total = trip.pricePerSeat * _selectedSeats;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chuyến xe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Thông tin tài xế
            _SectionCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      trip.driverName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.driverName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${trip.driverRating.toStringAsFixed(1)} · Tài xế WEGO',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Lộ trình
            _SectionCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.my_location,
                    color: AppTheme.primary,
                    label: 'Điểm đón',
                    value: trip.from.isEmpty ? 'Thoả thuận' : trip.from,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on,
                    color: AppTheme.error,
                    label: 'Điểm đến',
                    value: trip.to,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time,
                    color: AppTheme.secondary,
                    label: 'Giờ khởi hành',
                    value: DateFormat('HH:mm - dd/MM/yyyy')
                        .format(trip.departureTime),
                  ),
                  if (trip.note != null && trip.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.notes,
                      color: AppTheme.warning,
                      label: 'Ghi chú',
                      value: trip.note!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Chọn số ghế
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Số ghế muốn đặt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _selectedSeats > 1
                            ? () => setState(() => _selectedSeats--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppTheme.primary,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppTheme.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$_selectedSeats',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      IconButton(
                        onPressed:
                        _selectedSeats < trip.availableSeats
                            ? () => setState(() => _selectedSeats++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.primary,
                      ),
                      const Spacer(),
                      Text('Còn ${trip.availableSeats} ghế',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // Bottom bar thanh toán
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng tiền',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    )),
                Text(
                  NumberFormat('#,###đ').format(total),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isBooking ? null : _bookTrip,
                child: _isBooking
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Đặt chỗ ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon, required this.color,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}