class AppConstants {
  // Firestore collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String bookingsCollection = 'bookings';

  // Các bến xe mặc định cho demo
  static const List<String> benXeList = [
    'Bến xe Đà Nẵng',
    'Bến xe miền Đông',
    'Bến xe miền Tây',
    'Bến xe Nước Ngầm',
    'Bến xe Giáp Bát',
  ];

  // Trạng thái booking
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingRejected = 'rejected';
  static const String bookingCompleted = 'completed';

  // Trạng thái trip
  static const String tripActive = 'active';
  static const String tripFull = 'full';
  static const String tripCompleted = 'completed';
  static const String tripCancelled = 'cancelled';
}