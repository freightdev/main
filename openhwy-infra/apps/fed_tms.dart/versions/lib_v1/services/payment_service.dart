import 'dart:async';
import 'dart:core';

import '../models/payment.dart';
import '../models/payment.dart' as payment_model;
import 'api_client.dart';
import '../screens/payments_screen.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Payment>> listPayments() async {
    final response = await _apiClient.get('/payments');
    final data = (response.data['data'] as List).cast<Map<String, dynamic>>();
    return data.map((json) => Payment.fromJson(json)).toList();
  }

  Future<Payment> createPayment({
    required String userId,
    required double amount,
    payment_model.PaymentStatus status = payment_model.PaymentStatus.pending,
    String method = 'card',
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiClient.post(
      '/payments',
      data: {
        'user_id': userId,
        'amount': amount,
        'status': status.toString(),
        'method': method,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }
}
