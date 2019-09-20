import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

// import '../models/place.dart';


class DbAccess {

  static List<String> _initializers = [];

  static void addOnCreateCommand(String command) {
    _initializers.add(command);
  }

  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(path.join(dbPath, 'main.db'), onCreate: (db, version) async {
      _initializers.forEach((command) async { await db.execute(command);});
    }, version: 1);
  }

  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await database();
    await db.insert(table, data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<void> update(String table, Map<String, Object> data, String where, List<dynamic> whereArgs) async {
    final db = await database();
    await db.update(table, data, conflictAlgorithm: sql.ConflictAlgorithm.replace, where: where, whereArgs: whereArgs);
  }

  static Future<void> delete(String table, String where) async {
    final db = await database();
    await db.delete(table, where: where);
  }

  static Future<List<Map<String, dynamic>>> getData(String table, {String orderBy}) async {
    final db = await database();
    return db.query(table, orderBy: orderBy);
  }

}