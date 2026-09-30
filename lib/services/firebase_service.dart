import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/company.dart';
import '../models/ticket.dart';
import '../models/printer_profile.dart';

/// Firestore layout (this is the whole multi-company data model):
///
///   companies/{companyId}
///       name, nameArabic, address, crNumber, vatNumber, phone
///
///   companies/{companyId}/tickets/{ticketId}
///       every field on the physical ticket + serialNumber + date
///
///   companies/{companyId}/settings/printerProfile
///       calibration offsets for that company's ticket book
///
/// Every query below takes a companyId and only ever touches that
/// company's subcollections — this is what guarantees companies never
/// get mixed together, on screen or in a report.
class FirebaseService {
  final _db = FirebaseFirestore.instance;

  // ---------------- Companies ----------------

  Stream<List<Company>> watchCompanies() {
    return _db
        .collection('companies')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Company.fromDoc(d)).toList());
  }

  Future<void> saveCompany(Company company) async {
    if (company.id.isEmpty) {
      await _db.collection('companies').add(company.toMap());
    } else {
      await _db
          .collection('companies')
          .doc(company.id)
          .set(company.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteCompany(String companyId) async {
    await _db.collection('companies').doc(companyId).delete();
    // Note: this does not cascade-delete the tickets subcollection.
    // Deleting a company with ticket history is intentionally left as a
    // manual/careful operation — do it from the Firebase console.
  }

  // ---------------- Tickets ----------------

  CollectionReference<Map<String, dynamic>> _ticketsRef(String companyId) =>
      _db.collection('companies').doc(companyId).collection('tickets');

  Future<void> addTicket(Ticket ticket) async {
    final uid = FirebaseAuth.instance.currentUser?.email ??
        FirebaseAuth.instance.currentUser?.uid ??
        'unknown';
    final data = ticket.toMap();
    data['createdBy'] = uid;
    await _ticketsRef(ticket.companyId).add(data);
  }

  Stream<List<Ticket>> watchTicketsForDay(String companyId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _ticketsRef(companyId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ticket.fromDoc(d)).toList());
  }

  Future<List<Ticket>> getTicketsInRange(
      String companyId, DateTime start, DateTime end) async {
    final snap = await _ticketsRef(companyId)
        .where('date',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(start.year, start.month, start.day)))
        .where('date',
            isLessThan: Timestamp.fromDate(
                DateTime(end.year, end.month, end.day).add(const Duration(days: 1))))
        .orderBy('date')
        .get();
    return snap.docs.map((d) => Ticket.fromDoc(d)).toList();
  }

  Future<void> deleteTicket(String companyId, String ticketId) async {
    await _ticketsRef(companyId).doc(ticketId).delete();
  }

  // ---------------- Printer calibration ----------------

  DocumentReference<Map<String, dynamic>> _printerProfileRef(
          String companyId) =>
      _db
          .collection('companies')
          .doc(companyId)
          .collection('settings')
          .doc('printerProfile');

  Future<PrinterProfile> getPrinterProfile(String companyId) async {
    final doc = await _printerProfileRef(companyId).get();
    if (!doc.exists) return PrinterProfile.defaultProfile();
    return PrinterProfile.fromDoc(doc);
  }

  Future<void> savePrinterProfile(
      String companyId, PrinterProfile profile) async {
    await _printerProfileRef(companyId).set(profile.toMap());
  }
}
