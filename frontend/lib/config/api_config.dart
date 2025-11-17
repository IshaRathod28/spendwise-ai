class ApiConfig {
  // Base URL for production API on EC2
  static const String baseUrl = 'http://16.176.192.120:3000/api/v1';  // EC2 Public IP
  
  // Optional: Android emulator (still points to EC2)
  static const String androidBaseUrl = 'http://16.176.192.120:3000/api/v1';
  
  // Endpoints
  static const String transactionsEndpoint = '$baseUrl/transactions';
  static const String uploadEndpoint = '$baseUrl/transactions/create_from_image';
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
}