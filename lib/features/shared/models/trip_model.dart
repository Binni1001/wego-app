import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String driverId;
  final String driverName;
  final double driverRating;
  final String from;        // điểm đón
  final String to;          // bến xe
  final DateTime departureTime;
  final int totalSeats;
  final int availableSeats;
  final double pricePerSeat;
  final String status;      // 'active', 'full', 'completed', 'cancelled'
  final String? note;

  TripModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    this.status = 'active',
    this.note,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String docId) {
    return TripModel(
      id: docId,
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverRating: (map['driverRating'] ?? 5.0).toDouble(),
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      totalSeats: map['totalSeats'] ?? 4,
      availableSeats: map['availableSeats'] ?? 4,
      pricePerSeat: (map['pricePerSeat'] ?? 0).toDouble(),
      status: map['status'] ?? 'active',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'from': from,
      'to': to,
      'departureTime': Timestamp.fromDate(departureTime),
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'pricePerSeat': pricePerSeat,
      'status': status,
      'note': note,
    };
  }
}