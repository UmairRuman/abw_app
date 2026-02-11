// lib/features/riders/data/collections/riders_collection.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rider_model.dart';
import '../../domain/entities/rider_entity.dart';

class RidersCollection {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _path = 'riders';

  // Get rider by ID (stream)
  Stream<RiderModel?> getRiderStream(String riderId) {
    return _firestore.collection(_path).doc(riderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return RiderModel.fromJson({'id': doc.id, ...doc.data()!});
    });
  }

  // Get rider once
  Future<RiderModel?> getRiderById(String riderId) async {
    try {
      final doc = await _firestore.collection(_path).doc(riderId).get();
      if (!doc.exists || doc.data() == null) return null;
      return RiderModel.fromJson({'id': doc.id, ...doc.data()!});
    } catch (e) {
      return null;
    }
  }

  // Get all available riders (for admin assign)
  Future<List<RiderModel>> getAvailableRiders() async {
    try {
      final snapshot = await _firestore
          .collection(_path)
          .where('isApproved', isEqualTo: true)
          .where('status', isEqualTo: 'available')
          .get();

      return snapshot.docs
          .map((doc) =>
              RiderModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Update rider status
  Future<bool> updateRiderStatus(
      String riderId, RiderStatus status) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update current order
  Future<bool> updateCurrentOrder(
      String riderId, String? orderId) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'currentOrderId': orderId,
        'status':
            orderId != null ? RiderStatus.busy.name : RiderStatus.available.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update earnings after delivery
  Future<bool> updateEarnings(
      String riderId, double amount) async {
    try {
      await _firestore.collection(_path).doc(riderId).update({
        'totalEarnings': FieldValue.increment(amount),
        'totalDeliveries': FieldValue.increment(1),
        'currentOrderId': null,
        'status': RiderStatus.available.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}