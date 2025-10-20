// lib/api/profile_api.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/editphotoprofile.dart';
import 'package:timely/models/editprofile_model.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/services/auth_services.dart';

class ProfileApi {
  final AuthService _authService = AuthService();

  Future<GetProfileModel> getProfile() async {
    final token = await _authService.getToken();
    final url = Uri.parse(Endpoint.profile);

    print("====== GET PROFILE REQUEST ======");
    print("➡️ URL: $url");
    print("🔑 Token: Bearer $token");

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print("====== GET PROFILE RESPONSE ======");
    print("statusCode: ${response.statusCode}");
    print("📥 Response Body: ${response.body}");
    print("================================");

    if (response.statusCode == 200) {
      return getProfileModelFromJson(response.body);
    } else {
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get profile.');
      } catch (e) {
        throw Exception(
          'Failed to get profile. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    }
  }

  Future<EditProfileModel> updateProfile({
    required String name,
    required String email,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    final token = await _authService.getToken();
    final url = Uri.parse(Endpoint.updateProfile);

    // Persiapkan body/payload untuk dikirim
    final body = jsonEncode({
      "name": name,
      "email": email,
      "batch_id": batchId, // Mengirim sebagai integer
      "training_id": trainingId, // Mengirim sebagai integer
      "jenis_kelamin": jenisKelamin,
    });

    // --- LOG UNTUK DEBUGGING ---
    print("====== PROFILE UPDATE REQUEST ======");
    print("➡️ URL: $url");
    print("🔑 Token: Bearer $token");
    print("📤 Body: $body");
    // --- AKHIR DARI LOG ---

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    // --- LOG UNTUK DEBUGGING ---
    print("====== PROFILE UPDATE RESPONSE ======");
    print("statusCode: ${response.statusCode}");
    print("📥 Response Body: ${response.body}");
    print("================================");
    // --- AKHIR DARI LOG ---

    if (response.statusCode == 200) {
      return editProfileModelFromJson(response.body);
    } else {
      try {
        final errorData = json.decode(response.body);
        // Lempar pesan error yang lebih spesifik dari server
        throw Exception(errorData['message'] ?? 'Failed to update profile.');
      } catch (e) {
        // Fallback jika respons bukan JSON
        throw Exception(
          'Failed to update profile. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    }
  }

  Future<EditPhotoProfileModel> updateProfilePhoto(String imagePath) async {
    final token = await _authService.getToken();
    final url = Uri.parse(Endpoint.profilePhoto);

    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    String extension = imagePath.split('.').last.toLowerCase();
    if (extension == 'jpg') extension = 'jpeg';
    final imageWithPrefix = "data:image/$extension;base64,$base64Image";

    final response = await http.put(
      url,
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"profile_photo": imageWithPrefix}),
    );

    if (response.statusCode == 200) {
      try {
        return editPhotoProfileModelFromJson(response.body);
      } catch (e) {
        throw Exception('Failed to process server response: ${e.toString()}');
      }
    } else {
      String errorMessage = 'Failed to update profile photo.';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        errorMessage += ' Status: ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  }
}
