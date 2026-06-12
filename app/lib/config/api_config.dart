/// API Configuration for EcoLogiq Backend
class ApiConfig {
  // Base URL - Use your computer's IP for real devices, 10.0.2.2 for emulator
  static const String baseUrl =
      'https://backend-dm-production.up.railway.app/api';

  // Request timeout in seconds
  static const int timeout = 30;

  // Razorpay Configuration
  static const String razorpayKeyId = 'rzp_test_placeholder';

  // Auth Endpoints
  static const String register = '/auth/register'; // Send OTP for new users
  static const String login = '/auth/login'; // Send OTP for existing users
  static const String verifyOtp = '/auth/verify-otp';
  static const String profile = '/auth/profile';
  static const String refreshToken = '/auth/refresh-token';

  // Delivery Endpoints (Driver)
  static const String assignedDeliveries = '/deliveries/assigned';
  static String acceptDelivery(String id) => '/deliveries/$id/accept';
  static String rejectDelivery(String id) => '/deliveries/$id/reject';
  static String startDelivery(String id) => '/deliveries/$id/start';
  static String pickupDelivery(String id) => '/deliveries/$id/pickup';
  static String completeDelivery(String id) => '/deliveries/$id/complete';
  static String uploadPhotos(String id) => '/deliveries/$id/upload-photos';

  // Return Load Endpoints (Driver)
  static const String returnLoads = '/deliveries/return-loads';
  static const String availableReturnLoads =
      '/deliveries/return-loads/available';
  static String acceptReturnLoad(String id) =>
      '/deliveries/return-loads/$id/accept';
  static String scanShipperQR(String id) =>
      '/deliveries/return-loads/$id/scan-qr';

  // Shipment Endpoints (Shipper)
  static const String createShipment = '/shipments/create';
  static const String myShipments = '/shipments/my-shipments';
  static String getShipment(String id) => '/shipments/$id';
  static String cancelShipment(String id) => '/shipments/$id/cancel';
  static String generatePickupQR(String id) => '/shipments/$id/qr/generate';
  static String verifyPickupQR(String id) => '/shipments/$id/qr/verify';

  // Payment Endpoints
  static const String createPaymentOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify';
  static String getPaymentStatus(String orderId) => '/payments/$orderId/status';
  static String shipmentPayments(String shipmentId) =>
      '/payments/shipment/$shipmentId';

  // E-Way Bill Endpoints
  static String getEwayBill(String deliveryId) => '/ewb/delivery/$deliveryId';
  static String downloadEwayBillPdf(String ewbId) => '/ewb/$ewbId/download';
  static String getEwayBillByShipment(String shipmentId) =>
      '/ewb/shipment/$shipmentId';

  // Transaction Endpoints (Driver)
  static const String myTransactions = '/transactions/my-transactions';
  static const String weeklySummary = '/transactions/weekly-summary';
  static String getTransaction(String id) => '/transactions/$id';
  static String transactionsByDate(String startDate, String endDate) =>
      '/transactions?startDate=$startDate&endDate=$endDate';

  // Backhaul Endpoints (Driver)
  static const String backhaulOpportunities = '/backhaul/opportunities';

  // Synergy Endpoints (Driver)
  static const String synergySearch = '/synergy/search';
  static const String synergyAccept = '/synergy/accept';
  static const String synergyHandshake = '/synergy/handshake';
  static String generateTransferQR(String opportunityId) =>
      '/synergy/$opportunityId/qr/generate';

  // Route Optimization
  static const String optimizeRoute = '/routes/optimize';
  static const String allocateRoutes = '/routes/allocate';

  // Truck Endpoints
  static const String updateTruckLocation = '/trucks/location';
  static String getTruckLocation(String id) => '/trucks/$id/location';

  // Package Endpoints
  static const String packageHistory = '/packages/history';

  // Box Damage Audit (Embeddings-based policy)
  static const String boxDamageAudit = '/audits/box-damage';

  // Box Damage Audit (Cloud Vision LLM via backend)
  static const String auditDamage = '/audit-damage';

  // Virtual Hub Endpoints
  static const String virtualHubs = '/virtual-hubs';
  static String getVirtualHub(String id) => '/virtual-hubs/$id';

  // Dashboard (Admin/Global)
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardActivity = '/dashboard/activity';
  static const String liveTracking = '/dashboard/live-tracking';
  static const String recentAbsorptions = '/dashboard/recent-absorptions';

  // Driver Location (for shipper tracking)
  static String getDriverLocation(String shipmentId) =>
      '/shipments/$shipmentId/driver-location';
}
