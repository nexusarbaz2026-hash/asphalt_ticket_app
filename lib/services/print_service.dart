import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/ticket.dart';
import '../models/printer_profile.dart';

/// Prints ONE ticket = ONE physical page = ONE print job.
///
/// Why this approach instead of raw ESC/P text commands: the `printing`
/// package renders a PDF and hands it to whatever printer the OS print
/// dialog shows — including the Epson LQ-690 II once it's installed as
/// a Windows/Mac printer with a custom paper size matching your ticket
/// stock (Windows: Settings -> Printers -> LQ-690II -> Printing
/// Preferences -> Paper size -> Custom / User Defined, width/height
/// from the Calibration screen). That single mechanism works the same
/// way on Windows, Mac, Web and Android, which is what keeps this app
/// as one shared codebase across all four.
///
/// Because you feed the pre-printed ticket by hand and this only ever
/// sends one page per call, the printer naturally stops after each
/// ticket — there is nothing left in the job queue to keep feeding —
/// and pressing "Print" again on the next entry starts the next job.
///
/// NOTE: this overlay only draws the entered VALUES, not the ticket's
/// own borders/labels — those are already pre-printed on your paper.
class PrintService {
  /// Builds the overlay PDF bytes for one ticket using the given
  /// calibration profile. `mm` -> PDF points conversion uses
  /// PdfPageFormat.mm.
  static Future<Uint8List> buildTicketPdf(
      Ticket ticket, PrinterProfile profile) async {
    final doc = pw.Document();
    final format = PdfPageFormat(
      profile.pageWidthMm * PdfPageFormat.mm,
      profile.pageHeightMm * PdfPageFormat.mm,
      marginAll: 0,
    );

    final values = _valuesForTicket(ticket);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              for (final key in kPrintableFields)
                if ((values[key] ?? '').isNotEmpty)
                  _positioned(
                    profile.positions[key]!,
                    pw.Text(
                      values[key]!,
                      style: pw.TextStyle(fontSize: profile.fontSize),
                    ),
                  ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Sends the ticket straight to the OS print dialog so you can pick
  /// the LQ-690 II and confirm. One call = one ticket = one page.
  static Future<void> printTicket(Ticket ticket, PrinterProfile profile) async {
    final bytes = await buildTicketPdf(ticket, profile);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      format: PdfPageFormat(
        profile.pageWidthMm * PdfPageFormat.mm,
        profile.pageHeightMm * PdfPageFormat.mm,
      ),
    );
  }

  /// Prints a labelled test sheet — each field name printed at its
  /// current calibrated position — so you can lay it over (or under, on
  /// a lightbox / window) a blank physical ticket and see exactly how
  /// far to nudge each field in the Calibration screen.
  static Future<void> printCalibrationTest(PrinterProfile profile) async {
    final sample = Ticket(
      id: '',
      companyId: '',
      serialNumber: '',
      date: DateTime.now(),
      timeLoaded: '07:30 AM',
      typeOfMix: 'HMA Type III',
      quantityTon: 18.5,
      temp: '155C',
      customerName: 'Sample Customer',
      projectJoNo: 'JO-1234',
      others: 'Test line',
      truckNumber: 'TRK-01',
      truckDriver: 'Sample Driver',
      siteTemp: '150C',
      projectSupvr: 'Sample Supervisor',
      arrJob: '08:10 AM',
      receivedBy: 'Sample Receiver',
      depJob: '08:25 AM',
      jobSiteNameNumber: 'Sample Site / 12',
    );
    await printTicket(sample, profile);
  }

  static pw.Widget _positioned(FieldPos pos, pw.Widget child) {
    return pw.Positioned(
      left: pos.xMm * PdfPageFormat.mm,
      top: pos.yMm * PdfPageFormat.mm,
      child: child,
    );
  }

  static Map<String, String> _valuesForTicket(Ticket t) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return {
      'date': dateFmt.format(t.date),
      'timeLoaded': t.timeLoaded,
      'typeOfMix': t.typeOfMix,
      'quantityTon': t.quantityTon == 0 ? '' : t.quantityTon.toString(),
      'temp': t.temp,
      'customerName': t.customerName,
      'projectJoNo': t.projectJoNo,
      'others': t.others,
      'truckNumber': t.truckNumber,
      'truckDriver': t.truckDriver,
      'siteTemp': t.siteTemp,
      'projectSupvr': t.projectSupvr,
      'arrJob': t.arrJob,
      'receivedBy': t.receivedBy,
      'depJob': t.depJob,
      'jobSiteNameNumber': t.jobSiteNameNumber,
    };
  }
}
