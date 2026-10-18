class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime timestamp;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
    id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] as String? ?? 'Jajan',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    category: json['category'] as String? ?? 'Makan & Minum',
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}
