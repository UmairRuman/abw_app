// lib/features/payment/presentation/providers/payment_settings_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/collections/payment_settings_collection.dart';
import '../../data/models/payment_settings_model.dart';

// State
abstract class PaymentSettingsState {}

class PaymentSettingsInitial extends PaymentSettingsState {}

class PaymentSettingsLoading extends PaymentSettingsState {}

class PaymentSettingsLoaded extends PaymentSettingsState {
  final PaymentSettingsModel settings;
  PaymentSettingsLoaded(this.settings);
}

class PaymentSettingsError extends PaymentSettingsState {
  final String message;
  PaymentSettingsError(this.message);
}

// Notifier
class PaymentSettingsNotifier extends StateNotifier<PaymentSettingsState> {
  final PaymentSettingsCollection _collection = PaymentSettingsCollection();

  PaymentSettingsNotifier() : super(PaymentSettingsInitial());

  // Load settings
  Future<void> loadSettings() async {
    state = PaymentSettingsLoading();
    try {
      final settings = await _collection.getPaymentSettingsOnce();
      state = PaymentSettingsLoaded(settings);
    } catch (e) {
      state = PaymentSettingsError(e.toString());
    }
  }

  // Update settings
  Future<bool> updateSettings(PaymentSettingsModel settings) async {
    try {
      final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
      final success = await _collection.updatePaymentSettings(updatedSettings);
      if (success) {
        state = PaymentSettingsLoaded(updatedSettings);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Get current settings safely
  PaymentSettingsModel? get currentSettings {
    if (state is PaymentSettingsLoaded) {
      return (state as PaymentSettingsLoaded).settings;
    }
    return null;
  }
}

// Providers
final paymentSettingsProvider =
    StateNotifierProvider<PaymentSettingsNotifier, PaymentSettingsState>(
      (ref) => PaymentSettingsNotifier(),
    );

// Stream provider for real-time updates
final paymentSettingsStreamProvider = StreamProvider<PaymentSettingsModel>((
  ref,
) {
  return PaymentSettingsCollection().getPaymentSettings();
});
