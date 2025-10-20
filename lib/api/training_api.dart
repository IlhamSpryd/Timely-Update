// training_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/detailtraining_model.dart';
import 'package:timely/models/listallbatches_model.dart';
import 'package:timely/models/traininglist_model.dart';
import 'package:timely/services/auth_services.dart';

// UBAH NAMA KELAS dari TrainingService menjadi TrainingApi
class TrainingApi {
  final AuthService _authService = AuthService();

  // 1. Ambil Semua Training
  Future<ListTrainingModel> getTrainings() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.trainingList),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return listTrainingModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to get trainings.');
    }
  }

  // 2. Ambil Semua Batches
  Future<AllbatchesModel> getBatches() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse(Endpoint.batches),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return allbatchesModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to get batches.');
    }
  }

  // 3. Ambil Detail Training berdasarkan ID
  Future<DetailTrainingModel> getTrainingDetail(int trainingId) async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('${Endpoint.trainingDetail}/$trainingId'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return detailTrainingModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to get training detail.');
    }
  }
}
