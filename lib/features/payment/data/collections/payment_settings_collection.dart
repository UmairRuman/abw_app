// lib/features/payment/data/collections/payment_settings_collection.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_settings_model.dart';

class PaymentSettingsCollection {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _docPath = 'settings/payment_settings';

  // Get payment settings (stream)
  Stream<PaymentSettingsModel> getPaymentSettings() {
    return _firestore.doc(_docPath).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return PaymentSettingsModel.fromJson(doc.data()!);
      }
      return PaymentSettingsModel.defaultSettings();
    });
  }

  // Get payment settings (one-time)
  Future<PaymentSettingsModel> getPaymentSettingsOnce() async {
    try {
      final doc = await _firestore.doc(_docPath).get();
      if (doc.exists && doc.data() != null) {
        return PaymentSettingsModel.fromJson(doc.data()!);
      }
      // Create default settings if not exists
      final defaults = PaymentSettingsModel.defaultSettings();
      await _firestore.doc(_docPath).set(defaults.toJson());
      return defaults;
    } catch (e) {
      return PaymentSettingsModel.defaultSettings();
    }
  }

  // Update payment settings
  Future<bool> updatePaymentSettings(PaymentSettingsModel settings) async {
    try {
      await _firestore
          .doc(_docPath)
          .set(settings.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error updating payment settings: $e');
      return false;
    }
  }
}
