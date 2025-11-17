class ApiConfig {
  // Base URL for API - Use localhost for Linux/Web, 10.0.2.2 for Android emulator
  // For real Android device - using computer's IP address
  static const String baseUrl = 'http://192.168.1.12:3000/api/v1';
  
  // For Android emulator
  static const String androidBaseUrl = 'http://10.0.2.2:3000/api/v1';
  
  // For Linux/Web development (localhost)
  // static const String baseUrl = 'http://192.168.1.12:3000/api/v1';
  
  // Endpoints
  static const String transactionsEndpoint = '$baseUrl/transactions';
  static const String uploadEndpoint = '$baseUrl/transactions/create_from_image';
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
}
