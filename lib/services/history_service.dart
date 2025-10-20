// File: lib/data/repositories/history_absen_repository_impl.dart (Implementation)

import 'package:timely/api/history_api.dart';
import 'package:timely/services/history_repository.dart';

import '../../models/historyabsen_model.dart';

class HistoryService implements HistoryAbsenRepository {
  // Dependency Injection: Gunakan HistoryAbsenApiClient
  final HistoryAbsenApiClient _apiClient;

  HistoryService(this._apiClient);

  @override
  Future<HistoryAbsenModel> getHistoryAbsen() async {
    try {
      // Panggilan ke API Client yang terpisah
      return await _apiClient.getHistoryAbsen();
    } catch (e) {
      // Melempar error ke lapisan di atas (misalnya ke Cubit/Bloc/Provider)
      throw Exception('Repository Error: Failed to retrieve history. $e');
    }
  }
}
