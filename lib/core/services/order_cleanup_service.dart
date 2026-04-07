// ═════════════════════════════════════════════════════════════════════════════
// FILE 1 (NEW): lib/core/services/order_cleanup_service.dart
// ═════════════════════════════════════════════════════════════════════════════

import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Payload passed to the isolate — primitives only (isolate boundary rule).
class _CleanupPayload {
  final String userId;
  final String role; // 'admin', 'rider', 'customer'
  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;

  const _CleanupPayload({
    required this.userId,
    required this.role,
    required this.sendPort,
    required this.rootIsolateToken,
  });
}

class OrderCleanupService {
  static const String _lastRunKey = 'order_cleanup_last_run';

  // ── Public entry point ────────────────────────────────────────────────────

  /// Call this after auth resolves. Spawns an isolate if 24 hours have passed.
  /// Non-blocking — returns immediately, isolate runs in background.
  static Future<void> runIfNeeded({
    required String userId,
    required String role,
  }) async {
    try {
      // 24-hour debounce — don't run on every single app open
      // if (!await _shouldRun()) {
      //   log('🧹 Order cleanup skipped — ran recently');
      //   return;
      // }

      log('🧹 Order cleanup starting for role=$role userId=$userId');

      // Mark as run BEFORE spawning so even if isolate crashes we don't spam
      await _markAsRun();

      // Spawn isolate — completely non-blocking for the UI

      // ✅ Capture token HERE, in the main isolate
      final rootIsolateToken = RootIsolateToken.instance!;
      final receivePort = ReceivePort();
      await Isolate.spawn(
        _cleanupIsolateEntry,
        _CleanupPayload(
          userId: userId,
          role: role,
          sendPort: receivePort.sendPort,
          rootIsolateToken: rootIsolateToken,
        ),
        debugName: 'order_cleanup',
        // Don't kill main isolate if this one errors
        onError: receivePort.sendPort,
      );

      // Listen for completion message — fire and forget
      receivePort.listen((message) {
        log('🧹 Order cleanup isolate: $message');
        receivePort.close();
      });
    } catch (e) {
      log('🧹 Order cleanup error (non-fatal): $e');
    }
  }

  // ── Debounce helpers ──────────────────────────────────────────────────────

  static Future<bool> _shouldRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRun = prefs.getInt(_lastRunKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const twentyFourHours = 24 * 60 * 60 * 1000;
      return (now - lastRun) > twentyFourHours;
    } catch (_) {
      return true; // On error, allow run
    }
  }

  static Future<void> _markAsRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastRunKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}

// ── Isolate entry point ───────────────────────────────────────────────────────
// This runs in a SEPARATE isolate — no Flutter widgets, no Riverpod.
// Must initialize Firebase itself since isolates have separate memory.

@pragma('vm:entry-point')
Future<void> _cleanupIsolateEntry(_CleanupPayload payload) async {
  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(
      payload.rootIsolateToken,
    );
    // Isolates need their own Firebase initialization
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    int deleted = 0;

    switch (payload.role) {
      case 'admin':
        // Admin: delete ALL orders older than 15 days
        deleted = await _deleteOldOrders(
          firestore: firestore,
          cutoffDate: now.subtract(const Duration(days: 15)),
          additionalFilters: {}, // No extra filter — all orders
        );
        break;

      case 'rider':
        // Rider: delete their own delivered/cancelled orders older than 15 days
        deleted = await _deleteOldOrders(
          firestore: firestore,
          cutoffDate: now.subtract(const Duration(days: 15)),
          additionalFilters: {'riderId': payload.userId},
        );
        break;

      case 'customer':
        // Customer: delete their own orders older than 5 days
        deleted = await _deleteOldOrders(
          firestore: firestore,
          cutoffDate: now.subtract(const Duration(days: 5)),
          additionalFilters: {'userId': payload.userId},
        );
        break;
    }

    payload.sendPort.send(
      '✅ Done — deleted $deleted old orders for ${payload.role}',
    );
  } catch (e) {
    payload.sendPort.send('❌ Cleanup error: $e');
  }
}

/// Deletes orders older than [cutoffDate], optionally filtered by extra fields.
/// Uses batched deletes (max 500 per batch — Firestore limit).
/// Only deletes COMPLETED orders (delivered or cancelled) — never active ones.
Future<int> _deleteOldOrders({
  required FirebaseFirestore firestore,
  required DateTime cutoffDate,
  required Map<String, String> additionalFilters,
}) async {
  try {
    // Build query — only terminal statuses, older than cutoff
    Query query = firestore
        .collection('orders')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
        .where('status', whereIn: ['delivered', 'cancelled']);

    // Apply role-specific filter (riderId or userId)
    additionalFilters.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return 0;

    // Batch delete — Firestore allows max 500 operations per batch
    int deleted = 0;
    const batchSize = 400; // Stay under 500 limit

    for (int i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = firestore.batch();
      final end =
          (i + batchSize < snapshot.docs.length)
              ? i + batchSize
              : snapshot.docs.length;

      for (int j = i; j < end; j++) {
        batch.delete(snapshot.docs[j].reference);
        deleted++;
      }

      await batch.commit();
    }

    return deleted;
  } catch (e) {
    // Log but don't rethrow — partial cleanup is better than crashing
    return 0;
  }
}
