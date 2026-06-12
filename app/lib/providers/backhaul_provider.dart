import 'package:flutter/foundation.dart';
import '../models/backhaul_model.dart';
import '../services/api_service.dart';

/// Provider for backhaul opportunities
class BackhaulProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<BackhaulModel> _opportunities = [];
  bool _isLoading = false;
  String? _error;

  List<BackhaulModel> get opportunities => _opportunities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered opportunities
  List<BackhaulModel> get proposedOpportunities =>
      _opportunities.where((o) => o.isProposed).toList();
  List<BackhaulModel> get acceptedOpportunities =>
      _opportunities.where((o) => o.isAccepted || o.isEnRouteToPickup).toList();

  /// Fetch backhaul opportunities
  Future<void> fetchOpportunities(String truckId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getBackhaulOpportunities(truckId);

      if (response.isSuccess && response.rawData != null) {
        final List<dynamic> data = response.rawData as List<dynamic>;
        _opportunities = data
            .map((json) => BackhaulModel.fromJson(json))
            .toList();
        _error = null;
      } else {
        _error = response.message ?? 'Failed to fetch backhaul opportunities';
      }
    } catch (e) {
      _error = 'Error fetching opportunities: $e';
      if (kDebugMode) print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accept a backhaul opportunity
  Future<bool> acceptOpportunity(String backhaulId, String truckId) async {
    try {
      final response = await _apiService.acceptBackhaul(backhaulId);

      if (response.isSuccess) {
        // Refresh opportunities
        await fetchOpportunities(truckId);
        return true;
      } else {
        _error = response.message ?? 'Failed to accept opportunity';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error accepting opportunity: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
