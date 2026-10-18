import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';
import '../models/expense_item.dart';

class DatabaseHelper {
  static const String _dbName = 'uangku.db';
  static const int _dbVersion = 1;

  static Database? _database;

  static const String tableExpenses = 'expenses';
  static const String tableBudget = 'budget';

  /// Getter Singleton Database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inisialisasi Database SQLite
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Migrasi data lama dari SharedPreferences ke SQLite jika database baru dibuat/kosong
    await _migrateLegacySharedPrefsData(db);

    return db;
  }

  /// Membuat Tabel Utama Database (onCreate)
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableExpenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableBudget (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        total_salary REAL NOT NULL,
        primary_allocation REAL NOT NULL,
        secondary_allocation REAL NOT NULL,
        tertiary_allocation REAL NOT NULL,
        primary_details TEXT,
        secondary_details TEXT,
        tertiary_details TEXT
      )
    ''');
  }

  /// Mekanisme Migrasi Skema Database Aman Tanpa Menghapus Data (onUpgrade)
  /// DILARANG KERAS: DROP TABLE atau deleteDatabase()
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Penanganan migrasi skema di masa depan secara aman:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $tableExpenses ADD COLUMN notes TEXT;');
    // }
  }

  /// Migrasi Data Eksisting dari SharedPreferences ke SQLite (Zero Data Loss)
  static Future<void> _migrateLegacySharedPrefsData(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if expenses exist in SQLite
      final expensesCountResult = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableExpenses'),
      ) ?? 0;

      if (expensesCountResult == 0) {
        final legacyExpensesStr = prefs.getString('uangku_expenses_v1');
        if (legacyExpensesStr != null && legacyExpensesStr.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(legacyExpensesStr);
          for (final itemMap in decoded) {
            final item = ExpenseItem.fromJson(itemMap as Map<String, dynamic>);
            await db.insert(
              tableExpenses,
              {
                'id': item.id,
                'title': item.title,
                'amount': item.amount,
                'category': item.category,
                'timestamp': item.timestamp.toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }

      // Check if budget exists in SQLite
      final budgetCountResult = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableBudget'),
      ) ?? 0;

      if (budgetCountResult == 0) {
        final legacyBudgetStr = prefs.getString('uangku_budget_v1');
        BudgetModel budget;
        if (legacyBudgetStr != null && legacyBudgetStr.isNotEmpty) {
          try {
            final Map<String, dynamic> map = jsonDecode(legacyBudgetStr);
            budget = BudgetModel.fromJson(map);
          } catch (_) {
            budget = BudgetModel.initial();
          }
        } else {
          budget = BudgetModel.initial();
        }

        await db.insert(
          tableBudget,
          {
            'id': 1,
            'total_salary': budget.totalSalary,
            'primary_allocation': budget.primaryAllocation,
            'secondary_allocation': budget.secondaryAllocation,
            'tertiary_allocation': budget.tertiaryAllocation,
            'primary_details': jsonEncode(budget.primaryDetails.map((e) => e.toJson()).toList()),
            'secondary_details': jsonEncode(budget.secondaryDetails.map((e) => e.toJson()).toList()),
            'tertiary_details': jsonEncode(budget.tertiaryDetails.map((e) => e.toJson()).toList()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      // Silently handle migration errors to avoid crashing app launch
    }
  }

  // --- QUERY METHOD EXPENSES ---

  static Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExpenses,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) {
      return ExpenseItem(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
    }).toList();
  }

  static Future<void> insertExpense(ExpenseItem item) async {
    final db = await database;
    await db.insert(
      tableExpenses,
      {
        'id': item.id,
        'title': item.title,
        'amount': item.amount,
        'category': item.category,
        'timestamp': item.timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete(
      tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- QUERY METHOD BUDGET ---

  static Future<BudgetModel> getBudget() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableBudget,
      where: 'id = 1',
    );

    if (maps.isEmpty) {
      final initial = BudgetModel.initial();
      await saveBudget(initial);
      return initial;
    }

    final map = maps.first;
    final primaryDetailsRaw = map['primary_details'] as String?;
    final secondaryDetailsRaw = map['secondary_details'] as String?;
    final tertiaryDetailsRaw = map['tertiary_details'] as String?;

    List<BudgetDetailItem> parseDetails(String? raw) {
      if (raw == null || raw.isEmpty) return [];
      try {
        final List<dynamic> list = jsonDecode(raw);
        return list.map((e) => BudgetDetailItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        return [];
      }
    }

    return BudgetModel(
      totalSalary: (map['total_salary'] as num).toDouble(),
      primaryAllocation: (map['primary_allocation'] as num).toDouble(),
      secondaryAllocation: (map['secondary_allocation'] as num).toDouble(),
      tertiaryAllocation: (map['tertiary_allocation'] as num).toDouble(),
      primaryDetails: parseDetails(primaryDetailsRaw),
      secondaryDetails: parseDetails(secondaryDetailsRaw),
      tertiaryDetails: parseDetails(tertiaryDetailsRaw),
    );
  }

  static Future<void> saveBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert(
      tableBudget,
      {
        'id': 1,
        'total_salary': budget.totalSalary,
        'primary_allocation': budget.primaryAllocation,
        'secondary_allocation': budget.secondaryAllocation,
        'tertiary_allocation': budget.tertiaryAllocation,
        'primary_details': jsonEncode(budget.primaryDetails.map((e) => e.toJson()).toList()),
        'secondary_details': jsonEncode(budget.secondaryDetails.map((e) => e.toJson()).toList()),
        'tertiary_details': jsonEncode(budget.tertiaryDetails.map((e) => e.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
