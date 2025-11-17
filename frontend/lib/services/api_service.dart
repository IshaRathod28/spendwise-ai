import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/transaction.dart';

class ApiService {
  // Get all transactions with pagination
  Future<Map<String, dynamic>> getTransactions({int page = 1, int perPage = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.transactionsEndpoint}?page=$page&per_page=$perPage'),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Transaction> transactions = (data['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
        
        return {
          'transactions': transactions,
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  // Upload payment screenshot
  Future<Transaction> uploadPaymentImage(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadEndpoint),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      var response = await request.send().timeout(ApiConfig.timeout);
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = json.decode(responseData);
        return Transaction.fromJson(data['transaction']);
      } else {
        final error = json.decode(responseData);
        throw Exception(error['error'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Create transaction manually
  Future<Transaction> createTransaction(String note, double amount) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.transactionsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'note': note,
          'amount': amount,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        return Transaction.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.transactionsEndpoint}/$id'),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete transaction');
      }
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }
}
