import 'package:flutter/material.dart';
import '../../data/database_helper.dart';

class AttendanceService extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ======================
  // OFFICE RULES
  // ======================
  static const int officeStartHour = 9;
  static const int officeStartMinute = 30;

  static const int officeEndHour = 15;
  static const int officeEndMinute = 30;

  static const int halfDayHour = 12;
  static const int halfDayMinute = 0;

  // ======================
  // INTERNAL STATE
  // ======================
  DateTime? punchIn;
  DateTime? finalPunchOut;

  bool _isPunchedIn = false;
  bool isInside = false;

  String? _dayType; // FULL / HALF
  int _graceMinutes = 0;

  // ======================
  // PUBLIC GETTERS
  // ======================
  bool get isPunchedIn => _isPunchedIn;
  String? get dayType => _dayType;
  int get graceMinutes => _graceMinutes;

  // ======================
  // AUTO (GEOFENCE)
  // ======================
  Future<void> handleGeofenceEnter() async {
    isInside = true;
    if (!_isPunchedIn) {
      await _handlePunch(DateTime.now(), 'auto');
    }
  }

  Future<void> handleGeofenceExit() async {
    isInside = false;
    if (_isPunchedIn) {
      await _handlePunch(DateTime.now(), 'auto');
    }
  }

  // ======================
  // LOAD TODAY
  // ======================
  Future<void> loadTodayAttendance() async {
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final attendance = await _db.getAttendanceByDate(date);

    if (attendance == null) {
      punchIn = null;
      finalPunchOut = null;
      _dayType = null;
      _graceMinutes = 0;
      _isPunchedIn = false;
    } else {
      punchIn = attendance['punch_in'] != null
          ? DateTime.parse(attendance['punch_in'])
          : null;

      finalPunchOut = attendance['punch_out'] != null
          ? DateTime.parse(attendance['punch_out'])
          : null;

      _dayType = attendance['attendance_type'];
      _graceMinutes = attendance['used_grace_minutes'] ?? 0;
      _isPunchedIn = finalPunchOut == null;
    }

    notifyListeners();
  }

  // ======================
  // MANUAL / AUTO ENTRY
  // ======================
  Future<void> handlePunch({
    required String punchType,
    DateTime? customDateTime,
  }) async {
    final time = customDateTime ?? DateTime.now();
    await _handlePunch(time, punchType);
  }

  // ======================
  // CORE LOGIC
  // ======================
  Future<void> _handlePunch(DateTime time, String punchType) async {
    final date =
        "${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}";
    final dateTimeStr = time.toString().substring(0, 19);

    final attendance = await _db.getAttendanceByDate(date);

    // ----------------------
    // PUNCH IN
    // ----------------------
    if (attendance == null) {
      await _db.insertPunchIn(
        date: date,
        punchInTime: dateTimeStr,
        punchType: punchType,
      );

      punchIn = time;
      finalPunchOut = null;
      _dayType = null;
      _graceMinutes = 0;
      _isPunchedIn = true;

      notifyListeners();
      return;
    }

    // ----------------------
    // PUNCH OUT
    // ----------------------
    final existingPunchIn = DateTime.parse(attendance['punch_in']);
    if (time.isBefore(existingPunchIn)) return;

    final durationMinutes = time.difference(existingPunchIn).inMinutes;
    final isHalfDay = _isHalfDay(existingPunchIn, time);

    int grace = 0;
    if (!isHalfDay) {
      grace = _lateEntryGrace(existingPunchIn) + _earlyExitGrace(time);
    }

    final type = isHalfDay ? 'HALF' : 'FULL';

    await _db.updatePunchOut(
      attendanceId: attendance['id'],
      punchOutTime: dateTimeStr,
      durationMinutes: durationMinutes,
      usedGraceMinutes: grace,
      attendanceType: type,
    );

    punchIn = existingPunchIn;
    finalPunchOut = time;
    _dayType = type;
    _graceMinutes = grace;
    _isPunchedIn = false;

    notifyListeners();
  }

  // ======================
  // HELPERS
  // ======================
  bool _isHalfDay(DateTime punchIn, DateTime punchOut) {
    final noon = DateTime(
      punchIn.year,
      punchIn.month,
      punchIn.day,
      halfDayHour,
      halfDayMinute,
    );
    return punchIn.isAfter(noon) || punchOut.isBefore(noon);
  }

  int _lateEntryGrace(DateTime punchIn) {
    final officeStart = DateTime(
      punchIn.year,
      punchIn.month,
      punchIn.day,
      officeStartHour,
      officeStartMinute,
    );
    final minutes = punchIn.difference(officeStart).inMinutes;
    return minutes > 0 ? minutes : 0;
  }

  int _earlyExitGrace(DateTime punchOut) {
    final officeEnd = DateTime(
      punchOut.year,
      punchOut.month,
      punchOut.day,
      officeEndHour,
      officeEndMinute,
    );
    final minutes = officeEnd.difference(punchOut).inMinutes;
    return minutes > 0 ? minutes : 0;
  }
}
