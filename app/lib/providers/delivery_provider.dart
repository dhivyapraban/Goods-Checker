import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/delivery_model.dart';
import '../models/transaction_model.dart';
import '../models/eway_bill_model.dart';
import '../services/api_service.dart';

/// Delivery Provider for driver's deliveries
class DeliveryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<DeliveryModel> _deliveries = [];
  List<DeliveryModel> _returnLoads = [];
  List<DeliveryModel> _availableReturnLoads = [];
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  WeeklySummaryModel? _weeklySummary;
  EwayBillModel? _currentEwayBill;

  DeliveryModel? _selectedDelivery;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<DeliveryModel> get deliveries => _deliveries;
  List<DeliveryModel> get activeDeliveries =>
      _deliveries.where((d) => d.isActive).toList();
  List<DeliveryModel> get pendingDeliveries =>
      _deliveries.where((d) => d.isPending).toList();
  List<DeliveryModel> get completedDeliveries =>
      _deliveries.where((d) => d.isCompleted).toList();

  // Return loads getters
  List<DeliveryModel> get assignedReturnLoads => _returnLoads;
  List<DeliveryModel> get availableReturnLoads => _availableReturnLoads;
  int get returnLoadsCount => _returnLoads.length;

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get filteredTransactions => _filteredTransactions;
  WeeklySummaryModel? get weeklySummary => _weeklySummary;
  EwayBillModel? get currentEwayBill => _currentEwayBill;
  DeliveryModel? get selectedDelivery => _selectedDelivery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch assigned deliveries
  Future<void> fetchDeliveries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConfig.assignedDeliveries);

      if (response.isSuccess && response.rawData != null) {
        final data = response.rawData as List<dynamic>;
        _deliveries = data.map((d) => DeliveryModel.fromJson(d)).toList();
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch deliveries';
      if (kDebugMode) print('Fetch deliveries error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch return loads (assigned and available)
  Future<void> loadReturnLoads() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch assigned return loads
      final assignedResponse = await _apiService.get(ApiConfig.returnLoads);
      if (assignedResponse.isSuccess && assignedResponse.rawData != null) {
        final data = assignedResponse.rawData as List<dynamic>;
        _returnLoads = data.map((d) => DeliveryModel.fromJson(d)).toList();
      }

      // Fetch available return loads
      final availableResponse = await _apiService.get(
        ApiConfig.availableReturnLoads,
      );
      if (availableResponse.isSuccess && availableResponse.rawData != null) {
        final data = availableResponse.rawData as List<dynamic>;
        _availableReturnLoads = data
            .map((d) => DeliveryModel.fromJson(d))
            .toList();
      }
    } catch (e) {
      _error = 'Failed to fetch return loads';
      if (kDebugMode) print('Fetch return loads error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Accept a return load
  Future<bool> acceptReturnLoad(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConfig.acceptReturnLoad(id));

      _isLoading = false;

      if (response.isSuccess) {
        await loadReturnLoads(); // Refresh list
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to accept return load';
      notifyListeners();
      return false;
    }
  }

  /// Scan shipper's QR code for return load pickup
  Future<bool> scanShipperQR(String returnLoadId, String qrData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConfig.scanShipperQR(returnLoadId),
        data: {'qrData': qrData},
      );

      _isLoading = false;

      if (response.isSuccess) {
        await loadReturnLoads();
        await fetchDeliveries();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to verify QR code';
      notifyListeners();
      return false;
    }
  }

  /// Accept a delivery
  Future<bool> acceptDelivery(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConfig.acceptDelivery(id));

      _isLoading = false;

      if (response.isSuccess) {
        await fetchDeliveries(); // Refresh list
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to accept delivery';
      notifyListeners();
      return false;
    }
  }

  /// Reject a delivery
  Future<bool> rejectDelivery(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConfig.rejectDelivery(id));

      _isLoading = false;

      if (response.isSuccess) {
        await fetchDeliveries();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to reject delivery';
      notifyListeners();
      return false;
    }
  }

  /// Start delivery (begin navigation)
  Future<bool> startDelivery(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConfig.startDelivery(id));

      _isLoading = false;

      if (response.isSuccess) {
        await fetchDeliveries();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to start delivery';
      notifyListeners();
      return false;
    }
  }

  /// Mark cargo as picked up
  Future<bool> pickupCargo(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConfig.pickupDelivery(id));

      _isLoading = false;

      if (response.isSuccess) {
        await fetchDeliveries();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to mark pickup';
      notifyListeners();
      return false;
    }
  }

  /// Complete delivery
  Future<bool> completeDelivery(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConfig.completeDelivery(id));

      _isLoading = false;

      if (response.isSuccess) {
        await fetchDeliveries();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to complete delivery';
      notifyListeners();
      return false;
    }
  }

  /// Fetch transactions/earnings
  Future<void> fetchTransactions() async {
    try {
      final response = await _apiService.get(ApiConfig.myTransactions);

      if (response.isSuccess && response.rawData != null) {
        final data = response.rawData as List<dynamic>;
        _transactions = data.map((t) => TransactionModel.fromJson(t)).toList();
        _filteredTransactions = _transactions; // Initialize filtered with all
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Fetch transactions error: $e');
    }
  }

  /// Fetch transactions filtered by date range
  Future<void> fetchTransactionsByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      final response = await _apiService.get(
        ApiConfig.transactionsByDate(startStr, endStr),
      );

      if (response.isSuccess && response.rawData != null) {
        final data = response.rawData as List<dynamic>;
        _filteredTransactions = data
            .map((t) => TransactionModel.fromJson(t))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) print('Fetch filtered transactions error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear date filter and show all transactions
  void clearTransactionFilter() {
    _filteredTransactions = _transactions;
    notifyListeners();
  }

  /// Fetch weekly summary
  Future<void> fetchWeeklySummary() async {
    try {
      final response = await _apiService.get(ApiConfig.weeklySummary);

      if (response.isSuccess && response.rawData != null) {
        _weeklySummary = WeeklySummaryModel.fromJson(
          response.rawData as Map<String, dynamic>,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Fetch weekly summary error: $e');
    }
  }

  /// Fetch e-way bill for a delivery
  Future<void> fetchEwayBill(String deliveryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConfig.getEwayBill(deliveryId));

      if (response.isSuccess && response.rawData != null) {
        _currentEwayBill = EwayBillModel.fromJson(
          response.rawData as Map<String, dynamic>,
        );
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch e-way bill';
      if (kDebugMode) print('Fetch e-way bill error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get e-way bill PDF download URL
  String getEwayBillPdfUrl(String ewbId) {
    return '${ApiConfig.baseUrl}${ApiConfig.downloadEwayBillPdf(ewbId)}';
  }

  /// Select a delivery for details view
  void selectDelivery(DeliveryModel delivery) {
    _selectedDelivery = delivery;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedDelivery = null;
    _currentEwayBill = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchDeliveries(),
      fetchTransactions(),
      fetchWeeklySummary(),
      loadReturnLoads(),
    ]);
  }
}
