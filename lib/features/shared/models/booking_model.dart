import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String tripId;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final int seats;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'rejected', 'completed'
  final DateTime createdAt;
  final String from;
  final String to;
  final DateTime departureTime;

  BookingModel({
    required this.id,
    required this.tripId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.seats,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.from,
    required this.to,
    required this.departureTime,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookingModel(
      id: docId,
      tripId: map['tripId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerPhone: map['passengerPhone'] ?? '',
      seats: map['seats'] ?? 1,
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'seats': seats,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'from': from,
      'to': to,
      'departureTime': Timestamp.fromDate(departureTime),
    };
  }
}