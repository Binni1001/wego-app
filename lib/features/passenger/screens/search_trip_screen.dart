import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/models/trip_model.dart';
import 'trip_detail_screen.dart';

class SearchTripScreen extends StatefulWidget {
  const SearchTripScreen({super.key});

  @override
  State<SearchTripScreen> createState() => _SearchTripScreenState();
}

class _SearchTripScreenState extends State<SearchTripScreen> {
  final _fromController = TextEditingController();
  String _selectedBenXe = AppConstants.benXeList[0];
  DateTime _selectedDate = DateTime.now();
  List<TripModel> _trips = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _searchTrips() async {
    setState(() { _isSearching = true; _hasSearched = true; });

    final startOfDay = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.tripsCollection)
        .where('to', isEqualTo: _selectedBenXe)
        .where('status', isEqualTo: AppConstants.tripActive)
        .where('departureTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('departureTime',
        isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('departureTime')
        .get();

    setState(() {
      _trips = snapshot.docs
          .map((d) => TripModel.fromMap(d.data(), d.id))
          .where((t) => t.availableSeats > 0)
          .toList();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tìm chuyến xe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondary,
                    )),
                const SizedBox(height: 16),

                // Điểm đón
                TextField(
                  controller: _fromController,
                  decoration: const InputDecoration(
                    hintText: 'Điểm đón của bạn',
                    prefixIcon: Icon(Icons.location_on_outlined,
                        color: AppTheme.primary),
                    labelText: 'Điểm đón',
                  ),
                ),
                const SizedBox(height: 12),

                // Bến xe
                DropdownButtonFormField<String>(
                  value: _selectedBenXe,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.directions_bus_outlined,
                        color: AppTheme.secondary),
                    labelText: 'Bến xe đến',
                  ),
                  items: AppConstants.benXeList
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBenXe = v!),
                ),
                const SizedBox(height: 12),

                // Ngày đi
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down,
                            color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nút tìm
                ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchTrips,
                  icon: _isSearching
                      ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? 'Đang tìm...' : 'Tìm chuyến'),
                ),
              ],
            ),
          ),

          // Kết quả
          if (_hasSearched) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _trips.isEmpty
                        ? 'Không tìm thấy chuyến'
                        : 'Tìm thấy ${_trips.length} chuyến',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._trips.map((trip) => _TripCard(trip: trip)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar tài xế
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    trip.driverName.isNotEmpty
                        ? trip.driverName[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.driverName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          )),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(trip.driverRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                // Giá
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat('#,###đ').format(trip.pricePerSeat),
                      style: const TextStyle(
                        fontSize: 18,
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
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(trip.departureTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(trip.from,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${trip.availableSeats} ghế trống',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}