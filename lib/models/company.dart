import 'package:cloud_firestore/cloud_firestore.dart';

/// A Company is a data silo. Every ticket, report and print-calibration
/// profile lives underneath one Company document in Firestore, so two
/// companies' data can never mix — even by accident — because every
/// query in the app is always scoped to companies/{companyId}/....
class Company {
  final String id;
  final String name;
  final String? nameArabic;
  final String? address;
  final String? crNumber; // Commercial Registration number
  final String? vatNumber;
  final String? phone;

  Company({
    required this.id,
    required this.name,
    this.nameArabic,
    this.address,
    this.crNumber,
    this.vatNumber,
    this.phone,
  });

  factory Company.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Company(
      id: doc.id,
      name: d['name'] ?? '',
      nameArabic: d['nameArabic'],
      address: d['address'],
      crNumber: d['crNumber'],
      vatNumber: d['vatNumber'],
      phone: d['phone'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameArabic': nameArabic,
        'address': address,
        'crNumber': crNumber,
        'vatNumber': vatNumber,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Company && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
