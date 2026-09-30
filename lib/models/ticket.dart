import 'package:cloud_firestore/cloud_firestore.dart';

/// One Asphalt Mix Ticket entry.
///
/// Field names mirror the labels printed on the physical pre-printed
/// ticket (No. 08470, "Abu Hadriyah" ticket book) so the print overlay
/// in PrintService can map each value onto the matching blank line.
///
/// `serialNumber` is the one field that is NOT printed — the physical
/// ticket already has its own pre-printed "No." — this is only for your
/// own internal record-keeping / search inside the app.
class Ticket {
  final String id;
  final String companyId;
  final String serialNumber; // internal only, never printed

  final DateTime date;
  final String timeLoaded; // e.g. "07:30 AM" — already includes AM/PM
  final String typeOfMix;
  final double quantityTon;
  final String temp;
  final String customerName;
  final String projectJoNo;
  final String others;

  final String truckNumber;
  final String truckDriver;
  final String siteTemp;
  final String projectSupvr;
  final String arrJob; // e.g. "08:10 AM"
  final String receivedBy;
  final String depJob; // e.g. "08:25 AM"
  final String jobSiteNameNumber;

  final Timestamp? createdAt;
  final String? createdBy;

  Ticket({
    required this.id,
    required this.companyId,
    required this.serialNumber,
    required this.date,
    required this.timeLoaded,
    required this.typeOfMix,
    required this.quantityTon,
    required this.temp,
    required this.customerName,
    required this.projectJoNo,
    required this.others,
    required this.truckNumber,
    required this.truckDriver,
    required this.siteTemp,
    required this.projectSupvr,
    required this.arrJob,
    required this.receivedBy,
    required this.depJob,
    required this.jobSiteNameNumber,
    this.createdAt,
    this.createdBy,
  });

  factory Ticket.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Ticket(
      id: doc.id,
      companyId: d['companyId'] ?? '',
      serialNumber: d['serialNumber'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      timeLoaded: d['timeLoaded'] ?? '',
      typeOfMix: d['typeOfMix'] ?? '',
      quantityTon: (d['quantityTon'] ?? 0).toDouble(),
      temp: d['temp'] ?? '',
      customerName: d['customerName'] ?? '',
      projectJoNo: d['projectJoNo'] ?? '',
      others: d['others'] ?? '',
      truckNumber: d['truckNumber'] ?? '',
      truckDriver: d['truckDriver'] ?? '',
      siteTemp: d['siteTemp'] ?? '',
      projectSupvr: d['projectSupvr'] ?? '',
      arrJob: d['arrJob'] ?? '',
      receivedBy: d['receivedBy'] ?? '',
      depJob: d['depJob'] ?? '',
      jobSiteNameNumber: d['jobSiteNameNumber'] ?? '',
      createdAt: d['createdAt'],
      createdBy: d['createdBy'],
    );
  }

  Map<String, dynamic> toMap() => {
        'companyId': companyId,
        'serialNumber': serialNumber,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'timeLoaded': timeLoaded,
        'typeOfMix': typeOfMix,
        'quantityTon': quantityTon,
        'temp': temp,
        'customerName': customerName,
        'projectJoNo': projectJoNo,
        'others': others,
        'truckNumber': truckNumber,
        'truckDriver': truckDriver,
        'siteTemp': siteTemp,
        'projectSupvr': projectSupvr,
        'arrJob': arrJob,
        'receivedBy': receivedBy,
        'depJob': depJob,
        'jobSiteNameNumber': jobSiteNameNumber,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
