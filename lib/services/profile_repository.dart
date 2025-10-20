// profile_repository.dart

import 'package:timely/api/profile_api.dart'; // Import ProfileApi yang sudah benar
import 'package:timely/models/editphotoprofile.dart';
import 'package:timely/models/editprofile_model.dart';
import 'package:timely/models/getprofile_model.dart';

class ProfileRepository {
  // Hanya simpan instance dari lapisan API
  final ProfileApi _api = ProfileApi();

  // Metode untuk mengambil data profil
  Future<GetProfileModel> getProfile() async {
    try {
      // Panggil API
      return await _api.getProfile();
    } catch (e) {
      // Anda bisa menambahkan logika caching di sini jika diperlukan
      rethrow;
    }
  }

  // Metode untuk memperbarui data profil
  Future<EditProfileModel> updateProfile({
    required String name,
    required String email,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    try {
      // Panggil API
      return await _api.updateProfile(
        name: name,
        email: email,
        batchId: batchId,
        trainingId: trainingId,
        jenisKelamin: jenisKelamin,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Metode untuk memperbarui foto profil
  Future<EditPhotoProfileModel> updateProfilePhoto(String imagePath) async {
    try {
      // Panggil API
      return await _api.updateProfilePhoto(imagePath);
    } catch (e) {
      rethrow;
    }
  }
}
