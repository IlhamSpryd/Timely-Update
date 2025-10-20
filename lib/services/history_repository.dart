// File: lib/data/repositories/history_absen_repository.dart (Interface)

import '../../models/historyabsen_model.dart';

abstract class HistoryAbsenRepository {
  /// Mendapatkan daftar riwayat absen.
  Future<HistoryAbsenModel> getHistoryAbsen();
}
