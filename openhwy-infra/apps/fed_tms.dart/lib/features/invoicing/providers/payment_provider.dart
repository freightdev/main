import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fed_tms/features/invoicing/data/models/payment.dart';
import 'package:fed_tms/features/invoicing/data/services/payment_service.dart';

final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

final paymentsProvider = FutureProvider<List<Payment>>((ref) {
  final service = ref.watch(paymentServiceProvider);
  return service.listPayments();
});
