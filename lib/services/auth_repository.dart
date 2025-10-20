// lib/services/auth_repository.dart

import 'package:timely/api/auth_api.dart';
import 'package:timely/models/login_model.dart';
import 'package:timely/models/otp_request_model.dart.dart';
import 'package:timely/models/register_models.dart';
import 'package:timely/models/reset_password_model.dart';
import 'package:timely/services/auth_services.dart';

class AuthRepository {
  final AuthApi _api = AuthApi();
  final AuthService _service = AuthService();

  Future<bool> login(String email, String password) async {
    try {
      final LoginModel response = await _api.login(email, password);
      if (response.data?.user?.email != null && response.data?.token != null) {
        await _service.saveLogin(
          response.data!.user!.email!,
          response.data!.token!,
          response.data!.user!.name ?? 'User',
        );
        return true;
      } else {
        throw Exception(
          response.message ?? "Invalid login response or incomplete data",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    try {
      final RegisterModel response = await _api.register(
        name: name,
        email: email,
        password: password,
        batchId: batchId,
        trainingId: trainingId,
        jenisKelamin: jenisKelamin,
      );
      if (response.data != null) {
        await _service.saveAuthData(response.data!);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<OtpRequestModel> forgotPassword(String email) async {
    try {
      return await _api.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  // --- FUNGSI DIPERBARUI ---
  // Menyesuaikan parameter dan tipe return agar sesuai dengan API
  Future<ResetPasswordModel> resetPassword({
    required String email,
    required String otp, // Diubah dari 'token'
    required String password,
  }) async {
    try {
      // 2. Memanggil API dengan parameter yang benar dan mengembalikan hasilnya
      return await _api.resetPassword(
        email: email,
        otp: otp,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _service.logout();
  }

  Future<bool> isLoggedIn() async {
    return await _service.isLoggedIn();
  }

  Future<String?> getCurrentUserEmail() async {
    return await _service.getCurrentUserEmail();
  }

  Future<String?> getCurrentUserName() async {
    return await _service.getCurrentUserName();
  }

  Future<String?> getToken() async {
    return await _service.getToken();
  }

  Future<bool> hasSeenOnboarding() async {
    return await _service.hasSeenOnboarding();
  }
}
