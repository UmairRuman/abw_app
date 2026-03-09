// lib/features/settings/presentation/providers/contact_settings_provider.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/contact_settings_model.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final contactSettingsProvider =
    NotifierProvider<ContactSettingsNotifier, ContactSettingsState>(
      ContactSettingsNotifier.new,
    );

// ── Notifier ──────────────────────────────────────────────────────────────────

class ContactSettingsNotifier extends Notifier<ContactSettingsState> {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'app_settings';
  static const _doc = 'contact';

  @override
  ContactSettingsState build() => ContactSettingsInitial();

  Future<void> load() async {
    state = ContactSettingsLoading();
    try {
      final doc = await _firestore.collection(_collection).doc(_doc).get();

      if (doc.exists && doc.data() != null) {
        state = ContactSettingsLoaded(
          settings: ContactSettingsModel.fromJson(doc.data()!),
        );
      } else {
        // Document doesn't exist yet — use empty model
        state = ContactSettingsLoaded(settings: ContactSettingsModel.empty);
      }
    } catch (e) {
      state = ContactSettingsError(message: e.toString());
      log('Error loading contact settings: $e');
    }
  }

  Future<bool> save(ContactSettingsModel settings) async {
    try {
      await _firestore.collection(_collection).doc(_doc).set({
        ...settings.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = ContactSettingsLoaded(settings: settings);
      log('Contact settings saved');
      return true;
    } catch (e) {
      log('Error saving contact settings: $e');
      return false;
    }
  }

  Future<bool> removeBanner() async {
    final current = _current;
    if (current == null) return false;
    return save(current.copyWith(bannerUrl: ''));
  }

  ContactSettingsModel? get _current {
    final s = state;
    if (s is ContactSettingsLoaded) return s.settings;
    return null;
  }
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ContactSettingsState {}

class ContactSettingsInitial extends ContactSettingsState {}

class ContactSettingsLoading extends ContactSettingsState {}

class ContactSettingsLoaded extends ContactSettingsState {
  final ContactSettingsModel settings;
  ContactSettingsLoaded({required this.settings});
}

class ContactSettingsError extends ContactSettingsState {
  final String message;
  ContactSettingsError({required this.message});
}
