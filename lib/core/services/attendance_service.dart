import 'package:flutter/foundation.dart';

class AttendanceService extends ChangeNotifier {
  DateTime? punchIn;
  DateTime? finalPunchOut;
  bool isInside = false;

  void onEnter(DateTime time) {
    punchIn ??= time; // first punch in only
    isInside = true;
    notifyListeners(); // 🔹 notify UI
  }

  void onExit(DateTime time) {
    finalPunchOut = time; // always overwrite
    isInside = false;
    notifyListeners(); // 🔹 notify UI
  }
}
