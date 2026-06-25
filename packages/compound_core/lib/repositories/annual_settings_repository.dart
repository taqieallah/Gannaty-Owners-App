import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/annual_settings.dart';

class AnnualSettingsRepository {
  final _col = FirebaseFirestore.instance.collection('annualSettings');

  Stream<AnnualSettings?> watch(int year) {
    return _col.doc(year.toString()).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AnnualSettings.fromFirestore(doc);
    });
  }

  Future<AnnualSettings?> get(int year) async {
    final doc = await _col.doc(year.toString()).get();
    if (!doc.exists) return null;
    return AnnualSettings.fromFirestore(doc);
  }

  Future<void> save(AnnualSettings settings) async {
    await _col.doc(settings.year.toString()).set(settings.toFirestore());
  }
}
