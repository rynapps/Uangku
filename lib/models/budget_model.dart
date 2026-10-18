class BudgetDetailItem {
  final String id;
  final String title;
  final double amount;

  const BudgetDetailItem({
    required this.id,
    required this.title,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
  };

  factory BudgetDetailItem.fromJson(Map<String, dynamic> json) => BudgetDetailItem(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
  );

  BudgetDetailItem copyWith({
    String? id,
    String? title,
    double? amount,
  }) {
    return BudgetDetailItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
    );
  }
}

class BudgetModel {
  final double totalSalary;
  final double primaryAllocation;
  final double secondaryAllocation;
  final double tertiaryAllocation;
  final List<BudgetDetailItem> primaryDetails;
  final List<BudgetDetailItem> secondaryDetails;
  final List<BudgetDetailItem> tertiaryDetails;

  const BudgetModel({
    required this.totalSalary,
    required this.primaryAllocation,
    required this.secondaryAllocation,
    required this.tertiaryAllocation,
    this.primaryDetails = const [],
    this.secondaryDetails = const [],
    this.tertiaryDetails = const [],
  });

  /// Helper untuk mendapatkan total kalkulasi dari daftar detail item
  static double sumDetails(List<BudgetDetailItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Sisa Tabungan: Otomatis dikalkulasi dari formula [Total Gaji - (Primer + Sekunder + Tersier)]
  double get savingsAllocation {
    return totalSalary - (primaryAllocation + secondaryAllocation + tertiaryAllocation);
  }

  /// Persentase Pos terhadap Gaji
  double get primaryPercent => totalSalary > 0 ? (primaryAllocation / totalSalary) * 100 : 0;
  double get secondaryPercent => totalSalary > 0 ? (secondaryAllocation / totalSalary) * 100 : 0;
  double get tertiaryPercent => totalSalary > 0 ? (tertiaryAllocation / totalSalary) * 100 : 0;
  double get savingsPercent => totalSalary > 0 ? (savingsAllocation / totalSalary) * 100 : 0;

  /// Default initial budget untuk pengguna baru lengkap dengan contoh detail
  factory BudgetModel.initial() {
    const defaultPrimaryDetails = [
      BudgetDetailItem(id: 'p1', title: 'Sewa Tempat Tinggal / Kos', amount: 2000000),
      BudgetDetailItem(id: 'p2', title: 'Listrik, Air & Gas', amount: 500000),
      BudgetDetailItem(id: 'p3', title: 'WiFi & Paket Data', amount: 300000),
      BudgetDetailItem(id: 'p4', title: 'Kebutuhan Dapur & Pokok', amount: 1200000),
    ];
    const defaultSecondaryDetails = [
      BudgetDetailItem(id: 's1', title: 'Jajan Kopi & Kuliner', amount: 1200000),
      BudgetDetailItem(id: 's2', title: 'Nongkrong & Hiburan', amount: 800000),
    ];
    const defaultTertiaryDetails = [
      BudgetDetailItem(id: 't1', title: 'Kado & Kondangan', amount: 200000),
      BudgetDetailItem(id: 't2', title: 'Servis Kendaraan / Tak Terduga', amount: 300000),
    ];

    return const BudgetModel(
      totalSalary: 8000000,
      primaryAllocation: 4000000, // 50%
      secondaryAllocation: 2000000, // 25%
      tertiaryAllocation: 500000,  // 6.25%
      primaryDetails: defaultPrimaryDetails,
      secondaryDetails: defaultSecondaryDetails,
      tertiaryDetails: defaultTertiaryDetails,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalSalary': totalSalary,
    'primaryAllocation': primaryAllocation,
    'secondaryAllocation': secondaryAllocation,
    'tertiaryAllocation': tertiaryAllocation,
    'primaryDetails': primaryDetails.map((e) => e.toJson()).toList(),
    'secondaryDetails': secondaryDetails.map((e) => e.toJson()).toList(),
    'tertiaryDetails': tertiaryDetails.map((e) => e.toJson()).toList(),
  };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    totalSalary: (json['totalSalary'] as num?)?.toDouble() ?? 0.0,
    primaryAllocation: (json['primaryAllocation'] as num?)?.toDouble() ?? 0.0,
    secondaryAllocation: (json['secondaryAllocation'] as num?)?.toDouble() ?? 0.0,
    tertiaryAllocation: (json['tertiaryAllocation'] as num?)?.toDouble() ?? 0.0,
    primaryDetails: (json['primaryDetails'] as List<dynamic>?)
        ?.map((e) => BudgetDetailItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
    secondaryDetails: (json['secondaryDetails'] as List<dynamic>?)
        ?.map((e) => BudgetDetailItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
    tertiaryDetails: (json['tertiaryDetails'] as List<dynamic>?)
        ?.map((e) => BudgetDetailItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? const [],
  );

  BudgetModel copyWith({
    double? totalSalary,
    double? primaryAllocation,
    double? secondaryAllocation,
    double? tertiaryAllocation,
    List<BudgetDetailItem>? primaryDetails,
    List<BudgetDetailItem>? secondaryDetails,
    List<BudgetDetailItem>? tertiaryDetails,
  }) {
    return BudgetModel(
      totalSalary: totalSalary ?? this.totalSalary,
      primaryAllocation: primaryAllocation ?? this.primaryAllocation,
      secondaryAllocation: secondaryAllocation ?? this.secondaryAllocation,
      tertiaryAllocation: tertiaryAllocation ?? this.tertiaryAllocation,
      primaryDetails: primaryDetails ?? this.primaryDetails,
      secondaryDetails: secondaryDetails ?? this.secondaryDetails,
      tertiaryDetails: tertiaryDetails ?? this.tertiaryDetails,
    );
  }
}

