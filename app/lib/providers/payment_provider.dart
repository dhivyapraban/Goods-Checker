import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/payment_model.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';

/// Payment provider for Razorpay integration
class PaymentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final PaymentService _paymentService = PaymentService();

  bool _isLoading = false;
  String? _error;
  PaymentModel? _currentPayment;
  RazorpayOrderModel? _currentOrder;
  List<PaymentModel> _paymentHistory = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  PaymentModel? get currentPayment => _currentPayment;
  RazorpayOrderModel? get currentOrder => _currentOrder;
  List<PaymentModel> get paymentHistory => _paymentHistory;

  /// Initialize payment service with callbacks
  void initPaymentService(BuildContext context) {
    _paymentService.init(
      onPaymentSuccess: (response) => _handleSuccess(context, response),
      onPaymentFailure: (response) => _handleFailure(context, response),
      onWalletSelected: (response) => _handleExternalWallet(response),
    );
  }

  /// Create payment order on backend
  Future<bool> createPaymentOrder({
    required double amount,
    required String shipmentId,
    required String paymentType, // 'INITIAL' or 'FINAL'
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/payments/create-order',
        data: {
          'amount': (amount * 100).round(), // Convert to paise
          'shipmentId': shipmentId,
          'paymentType': paymentType,
          'currency': 'INR',
        },
      );

      if (response.success && response.data != null) {
        _currentOrder = RazorpayOrderModel.fromJson(response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to create payment order';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Open Razorpay checkout
  void openCheckout({
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String shipmentId,
    bool isInitialPayment = true,
  }) {
    if (_currentOrder == null) {
      _error = 'No payment order created';
      notifyListeners();
      return;
    }

    _paymentService.payForShipment(
      orderId: _currentOrder!.orderId,
      amount: _currentOrder!.amount,
      shipmentId: shipmentId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      isInitialPayment: isInitialPayment,
    );
  }

  /// Handle successful payment
  void _handleSuccess(
    BuildContext context,
    PaymentSuccessResponse response,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verify payment on backend
      final verifyResponse = await _apiService.post<Map<String, dynamic>>(
        '/payments/verify',
        data: {
          'orderId': response.orderId,
          'paymentId': response.paymentId,
          'signature': response.signature,
        },
      );

      if (verifyResponse.success && verifyResponse.data != null) {
        _currentPayment = PaymentModel.fromJson(verifyResponse.data!);
        _error = null;

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful!'),
              backgroundColor: Color(0xFF00D47E),
            ),
          );
        }
      } else {
        _error = 'Payment verification failed';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Handle payment failure
  void _handleFailure(BuildContext context, PaymentFailureResponse response) {
    _error = response.message ?? 'Payment failed';
    _isLoading = false;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  /// Get payment history for a shipment
  Future<void> loadPaymentHistory(String shipmentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get<List<dynamic>>(
        '/payments/shipment/$shipmentId',
      );

      if (response.success && response.data != null) {
        _paymentHistory = (response.data as List)
            .map((json) => PaymentModel.fromJson(json))
            .toList();
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear payment state
  void clearPayment() {
    _currentPayment = null;
    _currentOrder = null;
    _error = null;
    notifyListeners();
  }

  /// Dispose payment service
  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }
}
