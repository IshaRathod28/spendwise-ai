enum TransactionCategory {
  food('Food & Dining', '🍔'),
  transportation('Transportation', '🚗'),
  shopping('Shopping', '🛍️'),
  groceries('Groceries', '🛒'),
  utilities('Utilities', '💡'),
  entertainment('Entertainment', '🎬'),
  healthcare('Healthcare', '🏥'),
  education('Education', '📚'),
  rent('Rent', '🏠'),
  personal('Personal Care', '💅'),
  other('Other', '📦');

  const TransactionCategory(this.label, this.icon);
  final String label;
  final String icon;
  
  static TransactionCategory fromString(String category) {
    switch (category.toLowerCase()) {
      case 'food & dining':
      case 'food':
        return TransactionCategory.food;
      case 'transportation':
      case 'travel':
        return TransactionCategory.transportation;
      case 'shopping':
        return TransactionCategory.shopping;
      case 'groceries':
        return TransactionCategory.groceries;
      case 'utilities':
        return TransactionCategory.utilities;
      case 'entertainment':
        return TransactionCategory.entertainment;
      case 'healthcare':
        return TransactionCategory.healthcare;
      case 'education':
        return TransactionCategory.education;
      case 'rent':
        return TransactionCategory.rent;
      case 'personal care':
      case 'personal':
        return TransactionCategory.personal;
      default:
        return TransactionCategory.other;
    }
  }
}

class Transaction {
  final int id;
  final String note;
  final double amount;
  final TransactionCategory category;
  final String? merchant;
  final DateTime createdAt;
  final String? paymentScreenshotUrl;

  Transaction({
    required this.id,
    required this.note,
    required this.amount,
    required this.category,
    this.merchant,
    required this.createdAt,
    this.paymentScreenshotUrl,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      note: json['note'] ?? '',
      amount: double.parse(json['amount'].toString()),
      category: TransactionCategory.fromString(json['category'] ?? 'other'),
      merchant: json['merchant'],
      createdAt: DateTime.parse(json['created_at']),
      paymentScreenshotUrl: json['payment_screenshot_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'amount': amount,
      'category': category.label,
      'merchant': merchant,
      'created_at': createdAt.toIso8601String(),
      'payment_screenshot_url': paymentScreenshotUrl,
    };
  }
}
