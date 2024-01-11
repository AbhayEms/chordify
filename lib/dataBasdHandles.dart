// lib/database/database_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'marker_database.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute(
        'CREATE TABLE markers(lat REAL, lng REAL, PRIMARY KEY(lat, lng))');
  }

  Future<void> insertMarker(double lat, double lng) async {
    final Database db = await database;
    await db.insert(
      'markers',
      {'lat': lat, 'lng': lng},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMarker(double lat, double lng) async {
    final Database db = await database;
    await db.delete('markers', where: 'lat = ? AND lng = ?', whereArgs: [lat, lng]);
  }

  Future<List<Map<String, dynamic>>> getMarkers() async {
    final Database db = await database;
    return await db.query('markers');
  }
}
