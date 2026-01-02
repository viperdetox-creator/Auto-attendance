import 'package:flutter/material.dart';
import '../../data/database_helper.dart';

class AttendanceService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  static const int officeStartHour = 9;
  static const int officeStartMinute = 30;
  static const int officeEndHour = 15;
  static const int officeEndMinute = 30;
  static const int halfDayHour = 12;
  static const int halfDayMinute = 0;

  DateTime? punchIn;
  DateTime? finalPunchOut;
  bool _isPunchedIn = false;
  bool isInside = false;
  String? _dayType;
  int _graceMinutes = 0;

  List<Map<String, dynamic>> _history = [];
  int _monthlyGraceTotal = 0;

  bool get isPunchedIn => _isPunchedIn;
  String? get dayType => _dayType;
  int get graceMinutes => _graceMinutes;
  List<Map<String, dynamic>> get history => _history;
  int get monthlyGraceTotal => _monthlyGraceTotal;

  Future<void> loadTodayAttendance() async {
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final attendance = await _db.getAttendanceByDate(date);

    if (attendance == null) {
      _resetLocalState();
    } else {
      punchIn = attendance['punch_in'] != null
          ? DateTime.parse(attendance['punch_in'])
          : null;
      finalPunchOut = attendance['punch_out'] != null
          ? DateTime.parse(attendance['punch_out'])
          : null;
      _dayType = attendance['attendance_type'];
      _graceMinutes = attendance['used_grace_minutes'] ?? 0;
      _isPunchedIn = (attendance['is_active'] == 1);
    }
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    _history = await _db.getAllAttendance();
    final now = DateTime.now();
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    _monthlyGraceTotal = await _db.getMonthlyGraceTotal(monthKey);
    notifyListeners();
  }

  Future<void> handlePunch({
    required String punchType,
    DateTime? customDateTime,
  }) async {
    final time = customDateTime ?? DateTime.now();
    await _handlePunch(time, punchType);
    await fetchHistory();
  }

  Future<void> _handlePunch(DateTime time, String punchType) async {
    final date =
        "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}";
    final dateTimeStr = time.toString().substring(0, 19);
    final attendance = await _db.getAttendanceByDate(date);

    if (!_isPunchedIn) {
      if (attendance == null) {
        await _db.insertPunchIn(
          date: date,
          punchInTime: dateTimeStr,
          punchType: punchType,
        );
        punchIn = time;
      } else {
        await _db.updateAttendanceStatus(attendance['id'], 1);
        punchIn = DateTime.parse(attendance['punch_in']);
      }
      _isPunchedIn = true;
    } else {
      final firstIn = DateTime.parse(attendance!['punch_in']);

      // LOGIC FIX START
      final isHalfDay = _isHalfDay(firstIn, time);
      int grace = 0;

      if (!isHalfDay) {
        // Only calculate grace if it's a FULL day
        grace = _lateEntryGrace(firstIn) + _earlyExitGrace(time);
      }

      final type = isHalfDay ? 'HALF' : 'FULL';
      // LOGIC FIX END

      await _db.updatePunchOut(
        attendanceId: attendance['id'],
        punchOutTime: dateTimeStr,
        durationMinutes: time.difference(firstIn).inMinutes,
        usedGraceMinutes: grace,
        attendanceType: type,
      );
      _isPunchedIn = false;
      punchIn = firstIn;
      finalPunchOut = time;
      _dayType = type;
      _graceMinutes = grace;
    }
    notifyListeners();
  }

  Future<void> manualOverridePunch({
    required DateTime selectedDate,
    required TimeOfDay inTime,
    required TimeOfDay outTime,
  }) async {
    final dateStr =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
    final fullIn = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      inTime.hour,
      inTime.minute,
    );
    final fullOut = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      outTime.hour,
      outTime.minute,
    );

    // LOGIC FIX START
    final isHalfDay = _isHalfDay(fullIn, fullOut);
    int grace = 0;

    if (!isHalfDay) {
      grace = _lateEntryGrace(fullIn) + _earlyExitGrace(fullOut);
    }

    final type = isHalfDay ? 'HALF' : 'FULL';
    // LOGIC FIX END

    await _db.insertManualOverride(
      date: dateStr,
      punchIn: fullIn.toString().substring(0, 19),
      punchOut: fullOut.toString().substring(0, 19),
      grace: grace,
      type: type,
    );

    await fetchHistory();
    final today = DateTime.now();
    if (selectedDate.day == today.day && selectedDate.month == today.month) {
      await loadTodayAttendance();
    }
  }

  void _resetLocalState() {
    punchIn = null;
    finalPunchOut = null;
    _dayType = null;
    _graceMinutes = 0;
    _isPunchedIn = false;
  }

  // UPDATED HALF DAY LOGIC: Based on working hours
  bool _isHalfDay(DateTime inT, DateTime outT) {
    final durationMinutes = outT.difference(inT).inMinutes;
    // If worked less than 5 hours (300 minutes), it's a Half Day
    return durationMinutes < 300;
  }

  int _lateEntryGrace(DateTime inT) {
    final s = DateTime(
      inT.year,
      inT.month,
      inT.day,
      officeStartHour,
      officeStartMinute,
    );
    return inT.isAfter(s) ? inT.difference(s).inMinutes : 0;
  }

  int _earlyExitGrace(DateTime outT) {
    final e = DateTime(
      outT.year,
      outT.month,
      outT.day,
      officeEndHour,
      officeEndMinute,
    );
    return outT.isBefore(e) ? e.difference(outT).inMinutes : 0;
  }
}
