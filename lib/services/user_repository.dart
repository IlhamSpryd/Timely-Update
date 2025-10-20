// lib/repositories/user_repository.dart

import 'package:timely/api/user_api.dart';
import 'package:timely/models/alldatauser_model.dart';

class UserRepository {
  final UserApi _api = UserApi();

  Future<AllDataUserModel> getAllUsers() async {
    try {
      // Panggil API untuk mendapatkan semua pengguna
      return await _api.getAllUsers();
    } catch (e) {
      // Lempar kembali error jika terjadi masalah
      rethrow;
    }
  }
}
