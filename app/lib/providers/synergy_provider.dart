import 'package:flutter/foundation.dart';
import '../models/synergy_model.dart';
import '../services/api_service.dart';

/// Provider for synergy/absorption opportunities
class SynergyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<SynergyModel> _opportunities = [];
  bool _isLoading = false;
  String? _error;

  List<SynergyModel> get opportunities => _opportunities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered opportunities
  List<SynergyModel> get pendingOpportunities =>
      _opportunities.where((o) => o.isPending).toList();
  List<SynergyModel> get activeOpportunities =>
      _opportunities.where((o) => o.isActive).toList();

  /// Search for synergy opportunities
  Future<void> searchOpportunities(String truckId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.searchSynergy(truckId);

      if (response.isSuccess && response.rawData != null) {
        // Backend returns single opportunity or null
        if (response.rawData != null) {
          _opportunities = [SynergyModel.fromJson(response.rawData)];
        } else {
          _opportunities = [];
        }
        _error = null;
      } else {
        _error = response.message ?? 'Failed to search synergy opportunities';
        _opportunities = [];
      }
    } catch (e) {
      _error = 'Error searching opportunities: $e';
      if (kDebugMode) print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accept a synergy opportunity
  Future<bool> acceptOpportunity({
    required String opportunityId,
    required String routeId,
    required String truckId,
  }) async {
    try {
      final response = await _apiService.acceptSynergy(
        opportunityId: opportunityId,
        routeId: routeId,
      );

      if (response.isSuccess) {
        // Refresh opportunities
        await searchOpportunities(truckId);
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

  /// Handle QR code handshake
  Future<bool> handleHandshake({
    required String opportunityId,
    required String qrData,
  }) async {
    try {
      final response = await _apiService.handleSynergyHandshake(
        opportunityId: opportunityId,
        qrData: qrData,
      );

      if (response.isSuccess) {
        return true;
      } else {
        _error = response.message ?? 'Failed to complete handshake';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error during handshake: $e';
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
