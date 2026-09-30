import 'package:cloud_firestore/cloud_firestore.dart';

/// Position (in millimetres from the top-left of the page) where one
/// field's value gets printed. Millimetres are used (not pixels) so the
/// same profile behaves consistently regardless of screen/printer DPI.
class FieldPos {
  final double xMm;
  final double yMm;
  const FieldPos(this.xMm, this.yMm);

  Map<String, dynamic> toMap() => {'x': xMm, 'y': yMm};
  factory FieldPos.fromMap(Map<String, dynamic> m) =>
      FieldPos((m['x'] as num).toDouble(), (m['y'] as num).toDouble());
}

/// Every printable field on the ticket. `serialNumber` is deliberately
/// excluded — per your note, it must never be printed, only saved.
const List<String> kPrintableFields = [
  'date',
  'timeLoaded',
  'typeOfMix',
  'quantityTon',
  'temp',
  'customerName',
  'projectJoNo',
  'others',
  'truckNumber',
  'truckDriver',
  'siteTemp',
  'projectSupvr',
  'arrJob',
  'receivedBy',
  'depJob',
  'jobSiteNameNumber',
];

/// A calibration profile: the physical page size of the pre-printed
/// ticket stock, plus where on that page each value must land so it
/// sits on top of the correct blank line.
///
/// IMPORTANT — the starting numbers below are a REASONABLE GUESS based
/// on the photo you sent (a common 9.5in x 5.5in continuous ticket,
/// 241mm x 140mm landscape). A phone photo cannot give exact millimetre
/// positions, so treat these as a starting point only. Open
/// Calibration screen in the app, load a blank ticket into the LQ-690II,
/// tap "Test print", and nudge each field with the arrow buttons until
/// everything lands on the pre-printed lines — then hit Save. You only
/// need to do this once per ticket-book design.
class PrinterProfile {
  final double pageWidthMm;
  final double pageHeightMm;
  final double fontSize;
  final Map<String, FieldPos> positions;

  PrinterProfile({
    required this.pageWidthMm,
    required this.pageHeightMm,
    required this.fontSize,
    required this.positions,
  });

  factory PrinterProfile.defaultProfile() {
    return PrinterProfile(
      pageWidthMm: 241, // 9.5in continuous form, landscape
      pageHeightMm: 140, // 5.5in
      fontSize: 10,
      positions: const {
        'date': FieldPos(30, 26),
        'timeLoaded': FieldPos(160, 26),
        'typeOfMix': FieldPos(30, 34),
        'quantityTon': FieldPos(30, 42),
        'temp': FieldPos(150, 42),
        'customerName': FieldPos(35, 50),
        'projectJoNo': FieldPos(40, 58),
        'others': FieldPos(25, 66),
        'truckNumber': FieldPos(35, 82),
        'truckDriver': FieldPos(35, 90),
        'siteTemp': FieldPos(165, 90),
        'projectSupvr': FieldPos(35, 98),
        'arrJob': FieldPos(155, 98),
        'receivedBy': FieldPos(35, 106),
        'depJob': FieldPos(155, 106),
        'jobSiteNameNumber': FieldPos(20, 122),
      },
    );
  }

  factory PrinterProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return PrinterProfile.defaultProfile();
    final rawPositions = (d['positions'] as Map<String, dynamic>?) ?? {};
    final positions = <String, FieldPos>{};
    for (final key in kPrintableFields) {
      if (rawPositions[key] != null) {
        positions[key] =
            FieldPos.fromMap(Map<String, dynamic>.from(rawPositions[key]));
      } else {
        positions[key] = PrinterProfile.defaultProfile().positions[key]!;
      }
    }
    return PrinterProfile(
      pageWidthMm: (d['pageWidthMm'] ?? 241).toDouble(),
      pageHeightMm: (d['pageHeightMm'] ?? 140).toDouble(),
      fontSize: (d['fontSize'] ?? 10).toDouble(),
      positions: positions,
    );
  }

  Map<String, dynamic> toMap() => {
        'pageWidthMm': pageWidthMm,
        'pageHeightMm': pageHeightMm,
        'fontSize': fontSize,
        'positions': positions.map((k, v) => MapEntry(k, v.toMap())),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  PrinterProfile copyWith({
    double? pageWidthMm,
    double? pageHeightMm,
    double? fontSize,
    Map<String, FieldPos>? positions,
  }) {
    return PrinterProfile(
      pageWidthMm: pageWidthMm ?? this.pageWidthMm,
      pageHeightMm: pageHeightMm ?? this.pageHeightMm,
      fontSize: fontSize ?? this.fontSize,
      positions: positions ?? this.positions,
    );
  }

  PrinterProfile nudge(String field, double dxMm, double dyMm) {
    final current = positions[field]!;
    final updated = Map<String, FieldPos>.from(positions);
    updated[field] = FieldPos(current.xMm + dxMm, current.yMm + dyMm);
    return copyWith(positions: updated);
  }
}
