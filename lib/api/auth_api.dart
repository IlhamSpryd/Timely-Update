import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/login_model.dart';
import 'package:timely/models/otp_request_model.dart.dart';
import 'package:timely/models/register_models.dart';
import 'package:timely/models/reset_password_model.dart';

class AuthApi {
  Future<LoginModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(Endpoint.login),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"email": email, "password": password}),
    );
    if (response.statusCode == 200) {
      return loginModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(
        errorData['message'] ?? 'Login failed: ${response.statusCode}',
      );
    }
  }

  Future<RegisterModel> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
    required String jenisKelamin,
  }) async {
    final response = await http.post(
      Uri.parse(Endpoint.register),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "batch_id": batchId,
        "training_id": trainingId,
        "jenis_kelamin": jenisKelamin,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return registerModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Registrasi gagal');
    }
  }

  Future<OtpRequestModel> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(Endpoint.forgotPassword),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({"email": email}),
    );
    if (response.statusCode == 200) {
      return otpRequestModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengirim email');
    }
  }

  Future<ResetPasswordModel> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final body = {"email": email, "otp": otp, "password": password};
    final response = await http.post(
      Uri.parse(Endpoint.resetPassword),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return resetPasswordModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal mengatur ulang password');
    }
  }
}
