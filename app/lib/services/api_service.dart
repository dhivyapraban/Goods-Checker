import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

/// API Service with Dio HTTP client and JWT interceptor
class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  ApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(seconds: ApiConfig.timeout),
        receiveTimeout: Duration(seconds: ApiConfig.timeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// Attach JWT token to requests
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for auth endpoints
    if (!options.path.contains('/auth/register') &&
        !options.path.contains('/auth/login') &&
        !options.path.contains('/auth/verify-otp') &&
        !options.path.contains('/auth/refresh-token')) {
      final token = await _storageService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (kDebugMode) {
      print('🌐 ${options.method} ${options.uri}');
      if (options.data != null) print('📦 Body: ${options.data}');
    }

    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('✅ ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      print('❌ ${e.response?.statusCode} ${e.requestOptions.uri}');
      print('Error: ${e.message}');
    }

    // Handle 401 - Token expired
    if (e.response?.statusCode == 401) {
      // Could implement refresh token logic here
      // For now, just reject and let the app handle logout
    }

    handler.next(e);
  }

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _parseResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return _parseResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return _parseResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path);
      return _parseResponse(response, fromJson);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Parse API response
  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final body = response.data;

    if (body is Map<String, dynamic>) {
      final success = body['success'] ?? true;
      final message = body['message'] as String?;
      final data = body['data'];

      if (success) {
        return ApiResponse<T>(
          success: true,
          message: message,
          data: fromJson != null && data != null ? fromJson(data) : data as T?,
          rawData: data,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          message: message ?? 'Request failed',
          error: message,
        );
      }
    }

    return ApiResponse<T>(success: true, data: body as T?);
  }

  /// Handle Dio errors
  ApiResponse<T> _handleError<T>(DioException e) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final body = e.response?.data;

        if (body is Map<String, dynamic> && body['message'] != null) {
          message = body['message'];
        } else if (statusCode == 401) {
          message = 'Session expired. Please login again.';
        } else if (statusCode == 403) {
          message = 'Access denied.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Request failed with status $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      default:
        message = e.message ?? 'Unknown error occurred.';
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      error: message,
      statusCode: e.response?.statusCode,
    );
  }

  // ========== AUTH ENDPOINTS ==========

  /// Send OTP to phone number
  Future<ApiResponse<Map<String, dynamic>>> sendOTP({
    required String phone,
    String? role,
  }) async {
    return post(
      ApiConfig.login, // Backend uses same endpoint for both
      data: {'phone': phone, if (role != null) 'role': role},
    );
  }

  /// Verify OTP and get JWT token
  Future<ApiResponse<Map<String, dynamic>>> verifyOTP({
    required String phone,
    required String otp,
    String? role,
  }) async {
    return post(
      ApiConfig.verifyOtp,
      data: {'phone': phone, 'otp': otp, if (role != null) 'role': role},
    );
  }

  /// Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    return get(ApiConfig.profile);
  }

  /// Refresh access token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken(
    String refreshToken,
  ) async {
    return post(ApiConfig.refreshToken, data: {'refreshToken': refreshToken});
  }

  // ========== DELIVERY ENDPOINTS (DRIVER) ==========

  /// Get driver's assigned deliveries
  Future<ApiResponse<List<dynamic>>> getAssignedDeliveries() async {
    return get(ApiConfig.assignedDeliveries);
  }

  /// Accept delivery
  Future<ApiResponse<Map<String, dynamic>>> acceptDelivery(String id) async {
    return post(ApiConfig.acceptDelivery(id));
  }

  /// Reject delivery
  Future<ApiResponse<Map<String, dynamic>>> rejectDelivery(String id) async {
    return post(ApiConfig.rejectDelivery(id));
  }

  /// Start delivery (navigate to pickup)
  Future<ApiResponse<Map<String, dynamic>>> startDelivery(String id) async {
    return post(ApiConfig.startDelivery(id));
  }

  /// Mark cargo as picked up
  Future<ApiResponse<Map<String, dynamic>>> pickupDelivery(String id) async {
    return post(ApiConfig.pickupDelivery(id));
  }

  /// Complete delivery
  Future<ApiResponse<Map<String, dynamic>>> completeDelivery(String id) async {
    return post(ApiConfig.completeDelivery(id));
  }

  /// Upload delivery photos
  Future<ApiResponse<Map<String, dynamic>>> uploadDeliveryPhotos({
    required String id,
    required List<String> photos,
  }) async {
    return post(ApiConfig.uploadPhotos(id), data: {'photos': photos});
  }

  // ========== SHIPMENT ENDPOINTS (SHIPPER) ==========

  /// Create new shipment
  Future<ApiResponse<Map<String, dynamic>>> createShipment({
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
    return post(
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
        if (specialInstructions != null)
          'specialInstructions': specialInstructions,
        'priority': priority,
      },
    );
  }

  /// Get shipper's shipments
  Future<ApiResponse<List<dynamic>>> getMyShipments() async {
    return get(ApiConfig.myShipments);
  }

  /// Get single shipment details
  Future<ApiResponse<Map<String, dynamic>>> getShipment(String id) async {
    return get(ApiConfig.getShipment(id));
  }

  /// Cancel shipment
  Future<ApiResponse<Map<String, dynamic>>> cancelShipment(String id) async {
    return put(ApiConfig.cancelShipment(id));
  }

  // ========== TRANSACTION ENDPOINTS (DRIVER) ==========

  /// Get driver's transaction history
  Future<ApiResponse<List<dynamic>>> getMyTransactions() async {
    return get(ApiConfig.myTransactions);
  }

  /// Get weekly earnings summary
  Future<ApiResponse<Map<String, dynamic>>> getWeeklySummary() async {
    return get(ApiConfig.weeklySummary);
  }

  /// Get single transaction
  Future<ApiResponse<Map<String, dynamic>>> getTransaction(String id) async {
    return get(ApiConfig.getTransaction(id));
  }

  // ========== BACKHAUL ENDPOINTS (DRIVER) ==========

  /// Get backhaul opportunities
  Future<ApiResponse<List<dynamic>>> getBackhaulOpportunities(
    String truckId,
  ) async {
    return get(
      ApiConfig.backhaulOpportunities,
      queryParameters: {'truckId': truckId},
    );
  }

  // ========== SYNERGY ENDPOINTS (DRIVER) ==========

  /// Search for synergy opportunities
  Future<ApiResponse<Map<String, dynamic>>> searchSynergy(
    String truckId,
  ) async {
    return post(ApiConfig.synergySearch, data: {'truckId': truckId});
  }

  /// Accept synergy opportunity
  Future<ApiResponse<Map<String, dynamic>>> acceptSynergy({
    required String opportunityId,
    required String routeId,
  }) async {
    return post(
      ApiConfig.synergyAccept,
      data: {'opportunityId': opportunityId, 'routeId': routeId},
    );
  }

  /// Handle synergy handshake (QR scan)
  Future<ApiResponse<Map<String, dynamic>>> handleSynergyHandshake({
    required String opportunityId,
    required String qrData,
  }) async {
    return post(
      ApiConfig.synergyHandshake,
      data: {'opportunityId': opportunityId, 'qrData': qrData},
    );
  }

  // ========== TRUCK ENDPOINTS ==========

  /// Update truck location
  Future<ApiResponse<Map<String, dynamic>>> updateTruckLocation({
    required String truckId,
    required double lat,
    required double lng,
    double? speed,
    double? heading,
  }) async {
    return post(
      ApiConfig.updateTruckLocation,
      data: {
        'truckId': truckId,
        'lat': lat,
        'lng': lng,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
      },
    );
  }

  /// Accept backhaul opportunity
  Future<ApiResponse<Map<String, dynamic>>> acceptBackhaul(
    String backhaulId,
  ) async {
    return post('/api/backhaul/accept', data: {'backhaulId': backhaulId});
  }

  /// Get driver's earnings/transactions
  Future<ApiResponse<Map<String, dynamic>>> getMyEarnings({
    String? period, // 'daily', 'weekly', 'monthly'
  }) async {
    return get(
      '/api/transactions/my-earnings',
      queryParameters: period != null ? {'period': period} : null,
    );
  }

  /// Get transaction history
  Future<ApiResponse<List<dynamic>>> getTransactionHistory({
    int? limit,
    int? offset,
  }) async {
    return get(
      '/api/transactions/history',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
  }

  // ========== SHIPPER ENDPOINTS (UPDATED) ==========

  /// Get driver location for shipment tracking
  Future<ApiResponse<Map<String, dynamic>>> getDriverLocation(
    String shipmentId,
  ) async {
    return get('/api/shipments/$shipmentId/driver-location');
  }

  // ========== PACKAGE ENDPOINTS ==========

  /// Get package history
  Future<ApiResponse<List<dynamic>>> getPackageHistory({
    int? limit,
    int? offset,
  }) async {
    return get(
      ApiConfig.packageHistory,
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
  }

  // ========== VIRTUAL HUB ENDPOINTS ==========

  /// Get all virtual hubs
  Future<ApiResponse<List<dynamic>>> getVirtualHubs() async {
    return get(ApiConfig.virtualHubs);
  }

  /// Get virtual hub by ID
  Future<ApiResponse<Map<String, dynamic>>> getVirtualHub(String id) async {
    return get(ApiConfig.getVirtualHub(id));
  }

  // ========== DASHBOARD ENDPOINTS ==========

  /// Get dashboard activity
  Future<ApiResponse<List<dynamic>>> getDashboardActivity() async {
    return get(ApiConfig.dashboardActivity);
  }

  /// Get recent absorptions
  Future<ApiResponse<List<dynamic>>> getRecentAbsorptions() async {
    return get(ApiConfig.recentAbsorptions);
  }

  /// Get dashboard stats
  Future<ApiResponse<Map<String, dynamic>>> getDashboardStats() async {
    return get(ApiConfig.dashboardStats);
  }

  /// Get live tracking data
  Future<ApiResponse<List<dynamic>>> getLiveTracking() async {
    return get(ApiConfig.liveTracking);
  }
}

/// Generic API Response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic rawData;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.rawData,
    this.error,
    this.statusCode,
  });

  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;
}
