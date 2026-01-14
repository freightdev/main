import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:playground/core/models/payment.dart';
import 'package:playground/core/services/payment_service.dart';

final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

final paymentsProvider = FutureProvider<List<Payment>>((ref) {
  final service = ref.watch(paymentServiceProvider);
  return service.listPayments();
});
