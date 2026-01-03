import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/database_helper.dart';

class PdfExportService {
  static Future<void> generateAttendancePdf() async {
    final pdf = pw.Document();

    try {
      // 1. Fetch data using your existing method name: getAllAttendance()
      final List<Map<String, dynamic>> localData =
          await DatabaseHelper.instance.getAllAttendance();

      if (localData.isEmpty) {
        throw Exception("No attendance records found.");
      }

      // 2. Build the PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Professional Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("OFFLINE ATTENDANCE REPORT",
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800)),
                    pw.Text(
                        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
                  ],
                ),
                pw.Divider(thickness: 2, color: PdfColors.blue800),
              ],
            ),

            pw.SizedBox(height: 20),

            // Attendance Table using your exact SQLite column names
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Punch In', 'Punch Out', 'Type', 'Grace'],
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.center,
              data: localData.map((row) {
                return [
                  row['date']?.toString() ?? '-',
                  row['punch_in']?.toString() ?? '-',
                  row['punch_out']?.toString() ?? 'Pending',
                  row['attendance_type']?.toString() ??
                      row['punch_type'] ??
                      '-',
                  "${row['used_grace_minutes'] ?? 0}m",
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Total Records: ${localData.length}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      );

      // 3. Open Preview (Works 100% Offline)
      await Printing.layoutPdf(
          name: 'Attendance_Report.pdf',
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      rethrow;
    }
  }
}
