import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../shared/models/trip_model.dart';
import '../../auth/providers/auth_provider.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedBenXe = AppConstants.benXeList[0];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  int _totalSeats = 3;
  bool _isLoading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final user = auth.userModel;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final departureTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final tripRef = FirebaseFirestore.instance
          .collection(AppConstants.tripsCollection)
          .doc();

      final trip = TripModel(
        id: tripRef.id,
        driverId: user.uid,
        driverName: user.name,
        driverRating: user.rating,
        from: _fromController.text.trim(),
        to: _selectedBenXe,
        departureTime: departureTime,
        totalSeats: _totalSeats,
        availableSeats: _totalSeats,
        pricePerSeat: double.parse(_priceController.text),
        note: _noteController.text.trim(),
      );

      await tripRef.set(trip.toMap());

      if (!mounted) return;
      _showSuccessSnackbar();
      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Đăng chuyến thành công!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    _fromController.clear();
    _priceController.clear();
    _noteController.clear();
    setState(() {
      _totalSeats = 3;
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 7, minute: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_road, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đăng chuyến mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                      Text('Lấp đầy ghế trống, tăng thu nhập',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lộ trình
            _SectionTitle(title: '📍 Lộ trình'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _fromController,
              decoration: const InputDecoration(
                labelText: 'Điểm xuất phát',
                hintText: 'VD: Đại học Đà Nẵng, Q.Liên Chiểu',
                prefixIcon: Icon(Icons.my_location,
                    color: AppTheme.primary),
              ),
              validator: (v) =>
              v == null || v.isEmpty ? 'Nhập điểm xuất phát' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedBenXe,
              decoration: const InputDecoration(
                labelText: 'Điểm đến (Bến xe)',
                prefixIcon: Icon(Icons.location_on,
                    color: AppTheme.error),
              ),
              items: AppConstants.benXeList
                  .map((b) => DropdownMenuItem(
                  value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedBenXe = v!),
            ),
            const SizedBox(height: 20),

            // Thời gian
            _SectionTitle(title: '🕐 Thời gian khởi hành'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: _PickerBox(
                      icon: Icons.calendar_today,
                      label: 'Ngày đi',
                      value: DateFormat('dd/MM/yyyy')
                          .format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: _PickerBox(
                      icon: Icons.access_time,
                      label: 'Giờ đi',
                      value: _selectedTime.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ghế & Giá
            _SectionTitle(title: '💺 Ghế & Giá'),
            const SizedBox(height: 10),
            Row(
              children: [
                // Số ghế
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Số ghế trống',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline),
                              color: AppTheme.primary,
                              onPressed: _totalSeats > 1
                                  ? () => setState(
                                      () => _totalSeats--)
                                  : null,
                            ),
                            Text('$_totalSeats',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                )),
                            IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline),
                              color: AppTheme.primary,
                              onPressed: _totalSeats < 15
                                  ? () => setState(
                                      () => _totalSeats++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Giá
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giá mỗi ghế (đ)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'VD: 50000',
                          prefixIcon: Icon(
                              Icons.attach_money,
                              color: AppTheme.primary),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'Nhập giá';
                          if (double.tryParse(v) == null)
                            return 'Không hợp lệ';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ghi chú
            _SectionTitle(title: '📝 Ghi chú (tuỳ chọn)'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'VD: Xe 7 chỗ, có điều hoà, nhận hành lý...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.notes,
                      color: AppTheme.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Nút đăng
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _createTrip,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Đăng chuyến ngay'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.secondary,
        ));
  }
}

class _PickerBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PickerBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    )),
                Text(value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}