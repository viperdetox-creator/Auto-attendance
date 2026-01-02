import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // ===============================
  // SINGLETON
  // ===============================
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  // ===============================
  // DATABASE GETTER
  // ===============================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ===============================
  // INIT DATABASE
  // ===============================
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'attendance.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ===============================
  // ON CREATE
  // ===============================
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createUserTable);
    await db.execute(_createAttendanceTable);
    await db.execute(_createGraceSummaryTable);
    await _insertDefaultUser(db);
  }

  // ===============================
  // ON UPGRADE
  // ===============================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE attendance ADD COLUMN attendance_type TEXT",
      );
    }
  }

  // ===============================
  // TABLE DEFINITIONS
  // ===============================
  static const String _createUserTable = '''
    CREATE TABLE user (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      monthly_grace_limit INTEGER NOT NULL
    )
  ''';

  static const String _createAttendanceTable = '''
    CREATE TABLE attendance (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      punch_in TEXT,
      punch_out TEXT,
      duration_minutes INTEGER,
      used_grace_minutes INTEGER,
      attendance_type TEXT,
      punch_type TEXT,
      edited INTEGER DEFAULT 0
    )
  ''';

  static const String _createGraceSummaryTable = '''
    CREATE TABLE grace_summary (
      month TEXT PRIMARY KEY,
      total_used_minutes INTEGER,
      remaining_minutes INTEGER
    )
  ''';

  // ===============================
  // DEFAULT USER
  // ===============================
  Future<void> _insertDefaultUser(Database db) async {
    await db.insert('user', {
      'id': 1,
      'name': 'User',
      'monthly_grace_limit': 250,
    });
  }

  // ======================================================
  // ATTENDANCE OPERATIONS
  // ======================================================

  /// Punch In (auto / manual)
  Future<int> insertPunchIn({
    required String date,
    required String punchInTime,
    required String punchType,
  }) async {
    final db = await database;

    return await db.insert('attendance', {
      'date': date,
      'punch_in': punchInTime,
      'punch_type': punchType,
      'edited': punchType == 'manual' ? 1 : 0,
    });
  }

  /// Punch Out (FINAL, STABLE SIGNATURE)
  Future<int> updatePunchOut({
    required int attendanceId,
    required String punchOutTime,
    required int durationMinutes,
    required int usedGraceMinutes,
    required String attendanceType,
  }) async {
    final db = await database;

    return await db.update(
      'attendance',
      {
        'punch_out': punchOutTime,
        'duration_minutes': durationMinutes,
        'used_grace_minutes': usedGraceMinutes,
        'attendance_type': attendanceType,
      },
      where: 'id = ?',
      whereArgs: [attendanceId],
    );
  }

  /// Get attendance for a date
  Future<Map<String, dynamic>?> getAttendanceByDate(String date) async {
    final db = await database;

    final result = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// Get all attendance records
  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final db = await database;
    return await db.query('attendance', orderBy: 'date DESC');
  }

  /// Clear database (debug only)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('attendance');
    await db.delete('grace_summary');
  }
}
