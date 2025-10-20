// training_repository.dart
import 'package:timely/api/training_api.dart';
import 'package:timely/models/detailtraining_model.dart';
import 'package:timely/models/listallbatches_model.dart';
import 'package:timely/models/traininglist_model.dart';

class TrainingRepository {
  // Hanya simpan instance dari lapisan API
  final TrainingApi _api = TrainingApi();

  // Metode untuk mengambil daftar training
  Future<ListTrainingModel> getTrainings() async {
    try {
      return await _api.getTrainings();
    } catch (e) {
      rethrow;
    }
  }

  // Metode untuk mengambil daftar batches
  Future<AllbatchesModel> getBatches() async {
    try {
      return await _api.getBatches();
    } catch (e) {
      rethrow;
    }
  }

  // Metode untuk mengambil detail training
  Future<DetailTrainingModel> getTrainingDetail(int trainingId) async {
    try {
      return await _api.getTrainingDetail(trainingId);
    } catch (e) {
      rethrow;
    }
  }
}
