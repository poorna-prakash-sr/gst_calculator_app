import 'dart:io';

import 'package:gst_calculator/model/CalculationHistory.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "CalculatorHistory.db";
  static const _databaseVersion = 1;

  static const table = 'history';

  static const columnId = 'id';
  static const columnExpression = 'expression';
  static const columnResult = 'result';
  static const columnDate = 'date';

  // Singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    // Get the directory for the app's documents using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnExpression TEXT NOT NULL,
        $columnResult TEXT NOT NULL,
        $columnDate TEXT NOT NULL
      )
      ''');
  }

  Future<int> insert(CalculationHistory history) async {
    Database db = await database;
    var res = await db.insert(table, {
      columnExpression: history.expression,
      columnResult: history.result,
      columnDate: history.date.toIso8601String()
    });
    return res;
  }

  Future<List<CalculationHistory>> getAllHistories() async {
    Database db = await database;
    var res = await db.query(table);
    List<CalculationHistory> list = res.isNotEmpty
        ? res
            .map((c) => CalculationHistory(
                id: c[columnId] as int,
                expression: c[columnExpression] as String,
                result: c[columnResult] as String,
                date: DateTime.parse(c[columnDate] as String)))
            .toList()
        : [];
    return list;
  }

  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    Database db = await database;
    await db.delete(table);
  }
}
