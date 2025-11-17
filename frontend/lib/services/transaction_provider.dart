import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import 'api_service.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get totalSpent {
    return _transactions.fold(0, (sum, transaction) => sum + transaction.amount);
  }
  
  Map<TransactionCategory, double> get categoryTotals {
    final Map<TransactionCategory, double> totals = {};
    for (var transaction in _transactions) {
      totals[transaction.category] = (totals[transaction.category] ?? 0) + transaction.amount;
    }
    return totals;
  }
  
  // Fetch all transactions
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _apiService.getTransactions();
      _transactions = result['transactions'];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Upload payment screenshot
  Future<Transaction?> uploadPaymentImage(File image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final transaction = await _apiService.uploadPaymentImage(image);
      _transactions.insert(0, transaction);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return transaction;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Create manual transaction
  Future<Transaction?> createTransaction(String note, double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final transaction = await _apiService.createTransaction(note, amount);
      _transactions.insert(0, transaction);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return transaction;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Delete transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      await _apiService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
