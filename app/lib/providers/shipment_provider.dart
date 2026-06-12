import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/shipment_model.dart';
import '../services/api_service.dart';

/// Shipment Provider for shipper's shipments
class ShipmentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<ShipmentModel> _shipments = [];
  ShipmentModel? _selectedShipment;
  bool _isLoading = false;
  String? _error;

  // Create shipment form state
  int _createStep = 0;
  Map<String, dynamic> _createFormData = {};

  // Getters
  List<ShipmentModel> get shipments => _shipments;
  List<ShipmentModel> get pendingShipments =>
      _shipments.where((s) => s.isPending).toList();
  List<ShipmentModel> get inTransitShipments =>
      _shipments.where((s) => s.isInTransit).toList();
  List<ShipmentModel> get completedShipments =>
      _shipments.where((s) => s.isCompleted).toList();

  ShipmentModel? get selectedShipment => _selectedShipment;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get createStep => _createStep;
  Map<String, dynamic> get createFormData => _createFormData;

  /// Fetch shipper's shipments
  Future<void> fetchShipments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConfig.myShipments);

      if (response.isSuccess && response.rawData != null) {
        final data = response.rawData as List<dynamic>;
        _shipments = data.map((s) => ShipmentModel.fromJson(s)).toList();
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch shipments';
      if (kDebugMode) print('Fetch shipments error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get single shipment details
  Future<ShipmentModel?> getShipment(String id) async {
    try {
      final response = await _apiService.get(ApiConfig.getShipment(id));

      if (response.isSuccess && response.rawData != null) {
        return ShipmentModel.fromJson(response.rawData as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) print('Get shipment error: $e');
    }
    return null;
  }

  /// Create a new shipment
  Future<ShipmentModel?> createShipment({
    required double pickupLat,
    required double pickupLng,
    required String pickupLocation,
    required double dropLat,
    required double dropLng,
    required String dropLocation,
    required String cargoType,
    required double cargoWeight,
    String? specialInstructions,
    String priority = 'LOW',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConfig.createShipment,
        data: {
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
          'pickupLocation': pickupLocation,
          'dropLat': dropLat,
          'dropLng': dropLng,
          'dropLocation': dropLocation,
          'cargoType': cargoType,
          'cargoWeight': cargoWeight,
          'specialInstructions': specialInstructions,
          'priority': priority,
        },
      );

      _isLoading = false;

      if (response.isSuccess && response.rawData != null) {
        final data = response.rawData as Map<String, dynamic>;
        final shipment = data['shipment'] != null
            ? ShipmentModel.fromJson(data['shipment'] as Map<String, dynamic>)
            : null;

        if (shipment != null) {
          _shipments.insert(0, shipment);
          notifyListeners();
        }

        // Reset form
        resetCreateForm();

        return shipment;
      } else {
        _error = response.message ?? 'Failed to create shipment';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to create shipment';
      notifyListeners();
      if (kDebugMode) print('Create shipment error: $e');
      return null;
    }
  }

  /// Cancel a shipment
  Future<bool> cancelShipment(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.put(ApiConfig.cancelShipment(id));

      _isLoading = false;

      if (response.isSuccess) {
        // Update local state
        final index = _shipments.indexWhere((s) => s.id == id);
        if (index != -1) {
          await fetchShipments(); // Refresh to get updated status
        }
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to cancel shipment';
      notifyListeners();
      return false;
    }
  }

  /// Select shipment for details/tracking
  void selectShipment(ShipmentModel shipment) {
    _selectedShipment = shipment;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedShipment = null;
    notifyListeners();
  }

  // ==================== Create Form Methods ====================

  /// Set create form step
  void setCreateStep(int step) {
    _createStep = step;
    notifyListeners();
  }

  /// Update create form data
  void updateCreateFormData(Map<String, dynamic> data) {
    _createFormData.addAll(data);
    notifyListeners();
  }

  /// Next step in create form
  void nextCreateStep() {
    if (_createStep < 3) {
      _createStep++;
      notifyListeners();
    }
  }

  /// Previous step in create form
  void previousCreateStep() {
    if (_createStep > 0) {
      _createStep--;
      notifyListeners();
    }
  }

  /// Reset create form
  void resetCreateForm() {
    _createStep = 0;
    _createFormData = {};
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh shipments
  Future<void> refresh() async {
    await fetchShipments();
  }
}
