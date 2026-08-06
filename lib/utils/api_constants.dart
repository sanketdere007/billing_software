class ApiConstants {
  // Base API URL
  static const String baseUrl = 'http://billingapi.local:3032';

  // Auth Endpoints
  static const String loginEndpoint = '/api/Auth/Login';

  // City Endpoints
  static const String getAllCitiesEndpoint = '/api/City/GetAllCities';
  static const String insertOrUpdateCityEndpoint = '/api/City/InsertorUpdateCity';

  // State Endpoints
  static const String getAllStatesEndpoint = '/api/State/GetAllStates';

  // Default JSON Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Authenticated Headers with JWT Bearer Token
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  // Network Timeout Duration
  static const Duration timeoutDuration = Duration(seconds: 15);
}
