import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  String? _currentUserId;

  DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    // If user changed, close old database
    if (_currentUserId != null && _currentUserId != userId) {
      await _closeDatabase();
    }

    if (_database != null && _currentUserId == userId) {
      return _database!;
    }

    _currentUserId = userId;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    // Create unique database per user
    final userId = _currentUserId ?? 'default';
    final path = join(dbPath, 'attendance_$userId.db');

    return await openDatabase(
      path,
      version: 5, // Increased version for sync
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createUserTable);
    await db.execute(_createAttendanceTable);
    await db.execute(_createGraceSummaryTable);
    await _insertDefaultUser(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE attendance ADD COLUMN attendance_type TEXT",
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE attendance ADD COLUMN is_active INTEGER DEFAULT 0",
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE attendance ADD COLUMN sync_status INTEGER DEFAULT 0",
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE attendance ADD COLUMN user_id TEXT",
      );
      // Update existing records with current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await db.update(
          'attendance',
          {'user_id': user.uid},
          where: 'user_id IS NULL',
        );
      }
    }
  }

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
      user_id TEXT,
      date TEXT NOT NULL,
      punch_in TEXT,
      punch_out TEXT,
      duration_minutes INTEGER,
      used_grace_minutes INTEGER DEFAULT 0,
      attendance_type TEXT DEFAULT 'FULL',
      punch_type TEXT,
      edited INTEGER DEFAULT 0,
      is_active INTEGER DEFAULT 0,
      sync_status INTEGER DEFAULT 0,
      UNIQUE(user_id, date)
    )
  ''';

  static const String _createGraceSummaryTable = '''
    CREATE TABLE grace_summary (
      user_id TEXT,
      month TEXT,
      total_used_minutes INTEGER,
      remaining_minutes INTEGER,
      PRIMARY KEY (user_id, month)
    )
  ''';

  Future<void> _insertDefaultUser(Database db) async {
    await db.insert('user', {
      'id': 1,
      'name': 'User',
      'monthly_grace_limit': 250,
    });
  }

  // 1. PUNCH IN/OUT METHODS
  Future<int> insertPunchIn({
    required String date,
    required String punchInTime,
    required String punchType,
  }) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    return await db.insert('attendance', {
      'user_id': user?.uid,
      'date': date,
      'punch_in': punchInTime,
      'punch_type': punchType,
      'is_active': 1,
      'edited': punchType == 'manual' ? 1 : 0,
      'sync_status': 0, // Not synced yet
    });
  }

  Future<int> updatePunchOut({
    required int attendanceId,
    required String punchOutTime,
    required int durationMinutes,
    required int usedGraceMinutes,
    required String attendanceType,
    String? punchInTime,
  }) async {
    final db = await database;

    final Map<String, dynamic> updateData = {
      'punch_out': punchOutTime,
      'duration_minutes': durationMinutes,
      'used_grace_minutes': usedGraceMinutes,
      'attendance_type': attendanceType,
      'is_active': 0,
      'sync_status': 0, // Mark as unsynced
    };

    if (punchInTime != null) {
      updateData['punch_in'] = punchInTime;
    }

    return await db.update(
      'attendance',
      updateData,
      where: 'id = ?',
      whereArgs: [attendanceId],
    );
  }

  // 2. MANUAL OVERRIDE METHODS
  Future<int> insertManualOverride({
    required String date,
    required String punchIn,
    required String punchOut,
    required int grace,
    required String type,
  }) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    return await db.insert(
        'attendance',
        {
          'user_id': user?.uid,
          'date': date,
          'punch_in': punchIn,
          'punch_out': punchOut,
          'used_grace_minutes': grace,
          'attendance_type': type,
          'is_active': 0,
          'punch_type': 'manual_override',
          'edited': 1,
          'sync_status': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 3. SYNC METHODS
  Future<int> markAttendanceSynced(int id) async {
    final db = await database;
    return await db.update(
      'attendance',
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAttendance() async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    return await db.query(
      'attendance',
      where: 'sync_status = 0 AND user_id = ?',
      whereArgs: [user?.uid],
    );
  }

  Future<void> updateFromCloud(Map<String, dynamic> data) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await db.insert(
        'attendance',
        {
          'user_id': user.uid,
          'date': data['date'],
          'punch_in': data['punch_in'],
          'punch_out': data['punch_out'],
          'used_grace_minutes': data['used_grace_minutes'] ?? 0,
          'attendance_type': data['attendance_type'] ?? 'FULL',
          'punch_type': data['punch_type'] ?? 'auto',
          'edited': data['edited'] ?? 0,
          'is_active': data['is_active'] ?? 0,
          'sync_status': 1, // Mark as synced from cloud
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 4. USER-SPECIFIC QUERIES
  Future<List<Map<String, dynamic>>> getAttendanceLogsByDate(
      String date) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    return await db.query(
      'attendance',
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, user?.uid],
      orderBy: 'id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllAttendance() async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    return await db.query(
      'attendance',
      where: 'user_id = ?',
      whereArgs: [user?.uid],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<int> getMonthlyGraceTotal(String yearMonth) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    final result = await db.rawQuery(
      "SELECT SUM(used_grace_minutes) as total FROM attendance WHERE date LIKE ? AND user_id = ?",
      ['$yearMonth%', user?.uid],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>?> getAttendanceByDate(String date) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    final result = await db.query(
      'attendance',
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, user?.uid],
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // 5. CLEANUP METHODS
  Future<void> clearUserData() async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await db.delete(
        'attendance',
        where: 'user_id = ?',
        whereArgs: [user.uid],
      );
    }
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('attendance');
    await db.delete('grace_summary');
  }

  // 6. UTILITY METHODS
  Future<int> updateAttendanceStatus(int id, int isActive) async {
    final db = await database;
    return await db.update(
      'attendance',
      {'is_active': isActive, 'sync_status': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAttendanceByDate(String date) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    return await db.delete(
      'attendance',
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, user?.uid],
    );
  }

  Future<Map<String, dynamic>?> getActivePunch(String date) async {
    final db = await database;
    final user = FirebaseAuth.instance.currentUser;

    final result = await db.query(
      'attendance',
      where: 'date = ? AND is_active = 1 AND user_id = ?',
      whereArgs: [date, user?.uid],
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> close() async {
    await _closeDatabase();
    _currentUserId = null;
  }
}
