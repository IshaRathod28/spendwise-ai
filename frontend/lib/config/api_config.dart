class ApiConfig {
  // Base URL for production API on EC2
  static const String baseUrl = 'http://0.0.0.0:3000/api/v1';  // Replace with your EC2 public IP
  
  // Optional: Android emulator (still points to EC2)
  static const String androidBaseUrl = 'http://0.0.0.0:3000/api/v1';
  
  // Endpoints
  static const String transactionsEndpoint = '$baseUrl/transactions';
  static const String uploadEndpoint = '$baseUrl/transactions/create_from_image';
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
}