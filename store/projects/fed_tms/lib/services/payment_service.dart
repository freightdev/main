import 'dart:async';
import 'dart:core';

import 'package:playground/core/models/payment.dart';
import 'package:playground/core/services/api_client.dart';
import 'package:playground/screens/accounting/payments_screen.dart';

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
    PaymentStatus status = PaymentStatus.pending,
    String method = 'card',
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiClient.post(
      '/payments',
      data: {
        'user_id': userId,
        'amount': amount,
        'status': status.name,
        'method': method,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return Payment.fromJson(response.data as Map<String, dynamic>);
  }
}
