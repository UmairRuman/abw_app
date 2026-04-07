// lib/core/utils/order_copy_helper.dart
// Call copyOrderToClipboard(context, order) from any screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/orders/data/models/order_model.dart';
import '../../features/orders/domain/entities/order_entity.dart';

class OrderCopyHelper {
  /// Builds a clean plain-text summary of the order and copies it to clipboard.
  /// Shows a SnackBar confirmation when done.
  static Future<void> copyOrderToClipboard(
    BuildContext context,
    OrderModel order,
  ) async {
    final buffer = StringBuffer();

    // ── Header ────────────────────────────────────────────────────────────────
    buffer.writeln('📋 ORDER SUMMARY');
    buffer.writeln('Order #${order.id.substring(order.id.length - 8)}');
    buffer.writeln('─' * 32);

    // ── Restaurant ────────────────────────────────────────────────────────────
    buffer.writeln('🏪 RESTAURANT');
    buffer.writeln(
      order.storeName.isNotEmpty ? order.storeName : 'Unknown Store',
    );
    buffer.writeln();

    // ── Products ──────────────────────────────────────────────────────────────
    buffer.writeln('🍽️ ITEMS');
    for (final item in order.items) {
      // Name + quantity
      buffer.writeln('• ${item.quantity}x ${item.productName}');

      // Variant (size)
      if (item.selectedVariant != null) {
        buffer.writeln('  Size: ${item.selectedVariant!.name}');
      }

      // Addons
      if (item.selectedAddons.isNotEmpty) {
        final addons = item.selectedAddons.map((a) => a.name).join(', ');
        buffer.writeln('  Extras: $addons');
      }

      // Per-item special instructions
      if (item.specialInstructions != null &&
          item.specialInstructions!.isNotEmpty) {
        buffer.writeln('  📝 Note: ${item.specialInstructions}');
      }

      // Price
      final lineTotal = (item.discountedPrice * item.quantity).toInt();
      buffer.writeln('  PKR $lineTotal');
    }

    buffer.writeln();

    // ── Order-level special instructions ─────────────────────────────────────
    if (order.specialInstructions != null &&
        order.specialInstructions!.isNotEmpty) {
      buffer.writeln('📝 ORDER NOTE');
      buffer.writeln(order.specialInstructions);
      buffer.writeln();
    }

    // ── Bill summary ──────────────────────────────────────────────────────────
    buffer.writeln('💰 BILL');
    buffer.writeln('Subtotal:     PKR ${order.subtotal.toInt()}');
    buffer.writeln('Delivery Fee: PKR ${order.deliveryFee.toInt()}');
    if (order.discount > 0) {
      buffer.writeln('Discount:    -PKR ${order.discount.toInt()}');
    }
    buffer.writeln('TOTAL:        PKR ${order.total.toInt()}');
    buffer.writeln();

    // ── Payment ───────────────────────────────────────────────────────────────
    final paymentName = _paymentName(order.paymentMethod);
    final paymentStatus =
        order.paymentStatus == PaymentStatus.completed
            ? 'Verified ✅'
            : 'Pending ⏳';
    buffer.writeln('💳 PAYMENT: $paymentName — $paymentStatus');
    buffer.writeln();

    // ── Delivery address ──────────────────────────────────────────────────────
    buffer.writeln('📍 DELIVER TO');
    buffer.writeln(order.userName);
    buffer.writeln(
      '${order.deliveryAddress.addressLine1}, '
      '${order.deliveryAddress.area}, '
      '${order.deliveryAddress.city}',
    );
    if (order.userPhone.isNotEmpty) {
      buffer.writeln('📞 ${order.userPhone}');
    }

    // ── Copy ─────────────────────────────────────────────────────────────────
    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.copy, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Order details copied to clipboard'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static String _paymentName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.jazzcash:
        return 'JazzCash';
      case PaymentMethod.easypaisa:
        return 'EasyPaisa';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}
