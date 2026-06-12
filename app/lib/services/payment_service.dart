import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';

/// Payment service for Razorpay integration
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Razorpay? _razorpay;

  // Callbacks
  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  /// Initialize Razorpay
  void init({
    required Function(PaymentSuccessResponse) onPaymentSuccess,
    required Function(PaymentFailureResponse) onPaymentFailure,
    Function(ExternalWalletResponse)? onWalletSelected,
  }) {
    _razorpay = Razorpay();
    onSuccess = onPaymentSuccess;
    onFailure = onPaymentFailure;
    onExternalWallet = onWalletSelected;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  /// Open Razorpay checkout
  void openCheckout({
    required String orderId,
    required int amountInPaise,
    required String name,
    required String description,
    required String prefillEmail,
    required String prefillContact,
    String currency = 'INR',
    Map<String, dynamic>? notes,
  }) {
    if (_razorpay == null) {
      debugPrint('Razorpay not initialized. Call init() first.');
      return;
    }

    var options = {
      'key': ApiConfig.razorpayKeyId, // Your Razorpay Key ID
      'amount': amountInPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {'email': prefillEmail, 'contact': prefillContact},
      'notes': notes ?? {},
      'theme': {
        'color': '#F59B20', // EcoLogiq orange
      },
      'modal': {'confirm_close': true},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  /// Open checkout for shipment payment
  void payForShipment({
    required String orderId,
    required double amount,
    required String shipmentId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    bool isInitialPayment = true,
  }) {
    openCheckout(
      orderId: orderId,
      amountInPaise: (amount * 100).round(),
      name: 'EcoLogiq',
      description: isInitialPayment
          ? 'Initial Payment for Shipment #$shipmentId'
          : 'Final Payment for Shipment #$shipmentId',
      prefillEmail: customerEmail,
      prefillContact: customerPhone,
      notes: {
        'shipment_id': shipmentId,
        'payment_type': isInitialPayment ? 'INITIAL' : 'FINAL',
        'customer_name': customerName,
      },
    );
  }

  /// Clear Razorpay instance
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    onSuccess = null;
    onFailure = null;
    onExternalWallet = null;
  }
}
