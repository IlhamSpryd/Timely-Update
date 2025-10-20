// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/absen_today.dart';
import 'package:timely/models/checkin_model.dart';
import 'package:timely/models/checkout_model.dart';
import 'package:timely/models/deleteabsen_model.dart';
import 'package:timely/models/izin_model.dart';
import 'package:timely/services/auth_services.dart';

class AttendanceApi {
  final AuthService _authService = AuthService();

  // 1. Check In
  Future<CheckinModel?> checkIn({
    required double lat,
    required double lng,
    required String address,
    required String checkInTime,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception("Token tidak tersedia");

    final body = {
      "attendance_date": DateTime.now().toIso8601String().split('T')[0],
      "check_in": checkInTime,
      "check_in_lat": lat,
      "check_in_lng": lng,
      "check_in_location": "$lat,$lng",
      "check_in_address": address,
    };

    print("=== CHECKIN REQUEST ===");
    print(body);
    print("Endpoint: ${Endpoint.checkIn}");

    try {
      final response = await http
          .post(
            Uri.parse(Endpoint.checkIn),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print("=== CHECKIN RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return checkinModelFromJson(jsonEncode(decoded));
      } else if (response.statusCode == 409) {
        // Conflict: user already checked in
        print("⚠️ Sudah absen hari ini: ${decoded['message']}");
        return checkinModelFromJson(jsonEncode(decoded['data']));
      } else {
        throw Exception(decoded['message'] ?? 'Failed to check-in.');
      }
    } catch (e) {
      print("Error during check-in: $e");
      rethrow;
    }
  }

  // 2. Check Out
  Future<CheckoutModel?> checkOut({
    required double lat,
    required double lng,
    required String address,
    required String checkOutTime,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception("Token tidak tersedia");

    final body = {
      "attendance_date": DateTime.now().toIso8601String().split('T')[0],
      "check_out": checkOutTime,
      "check_out_lat": lat,
      "check_out_lng": lng,
      "check_out_location": "$lat,$lng",
      "check_out_address": address,
    };

    print("=== CHECKOUT REQUEST ===");
    print(body);
    print("Endpoint: ${Endpoint.checkOut}");

    try {
      final response = await http
          .post(
            Uri.parse(Endpoint.checkOut),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print("=== CHECKOUT RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return checkoutModelFromJson(jsonEncode(decoded));
      } else if (response.statusCode == 409) {
        print("⚠️ Sudah checkout hari ini: ${decoded['message']}");
        return checkoutModelFromJson(jsonEncode(decoded['data']));
      } else {
        throw Exception(decoded['message'] ?? 'Failed to check-out.');
      }
    } catch (e) {
      print("Error during check-out: $e");
      rethrow;
    }
  }

  // 3. Absen Hari Ini
  Future<AbsenTodayModel?> getAbsenToday() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception("Token tidak tersedia");

    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final response = await http
          .get(
            Uri.parse("${Endpoint.absenToday}?attendance_date=$today"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));

      print("=== ABSEN TODAY RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return absenTodayModelFromJson(jsonEncode(decoded));
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['message'] ?? 'Failed to get today\'s absen.');
      }
    } catch (e) {
      print("Error during getAbsenToday: $e");
      rethrow;
    }
  }

  // 4. Statistik Absen
  Future<AbsenStatsModel?> getAbsenStats() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception("Token tidak tersedia");

    try {
      final response = await http
          .get(
            Uri.parse(Endpoint.absenStats),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));

      print("=== ABSEN STATS RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return absenStatsModelFromJson(jsonEncode(decoded));
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['message'] ?? 'Failed to get absen stats.');
      }
    } catch (e) {
      print("Error during getAbsenStats: $e");
      rethrow;
    }
  }

  // 5. Ajukan Izin
  Future<IzinModel?> izin(String alasanIzin) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception("Token tidak tersedia");

    print("=== IZIN REQUEST ===");
    print("Alasan: $alasanIzin");
    print("Endpoint: ${Endpoint.izin}");

    try {
      final response = await http
          .post(
            Uri.parse(Endpoint.izin),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({"alasan_izin": alasanIzin}),
          )
          .timeout(const Duration(seconds: 30));

      print("=== IZIN RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return izinModelFromJson(jsonEncode(decoded));
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['message'] ?? 'Failed to submit izin.');
      }
    } catch (e) {
      print("Error during izin: $e");
      rethrow;
    }
  }

  // 6. Hapus Absen
  Future<DeleteAbsenModel?> deleteAbsen(int absenId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception("Token tidak tersedia");

    print("=== DELETE ABSEN REQUEST ===");
    print("Absen ID: $absenId");
    print("Endpoint: ${Endpoint.deleteAbsen}/$absenId");

    try {
      final response = await http
          .delete(
            Uri.parse('${Endpoint.deleteAbsen}/$absenId'),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));

      print("=== DELETE ABSEN RESPONSE ===");
      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return deleteAbsenModelFromJson(jsonEncode(decoded));
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['message'] ?? 'Failed to delete absen.');
      }
    } catch (e) {
      print("Error during deleteAbsen: $e");
      rethrow;
    }
  }
}
