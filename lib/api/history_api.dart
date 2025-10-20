// File: lib/data/data_sources/history_absen_api_client.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';

import '../../models/historyabsen_model.dart';
import '../../services/auth_services.dart'; // Digunakan untuk mengambil token

class HistoryAbsenApiClient {
  final http.Client _client;
  final AuthService _authService; // Menggunakan AuthService untuk dependency

  HistoryAbsenApiClient({http.Client? client, AuthService? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? AuthService();

  /// Mengambil data histori absen
  Future<HistoryAbsenModel> getHistoryAbsen() async {
    final token = await _authService.getToken(); // Ambil token dari AuthService

    final response = await _client.get(
      Uri.parse(Endpoint.history),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      // Menggunakan fungsi deserialisasi historyAbsenModelFromJson
      return historyAbsenModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      String errorMessage =
          errorData['message'] ?? 'Failed to get history data.';

      throw Exception(errorMessage);
    }
  }
}
