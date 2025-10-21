import 'package:flutter_dotenv/flutter_dotenv.dart';

class Endpoint {
  static String get baseURL =>
      dotenv.env['BASE_URL'] ??  "https://appabsensi.mobileprojp.com";

  // Auth
  static String get register => "$baseURL/api/register";
  static String get login => "$baseURL/api/login";
  static String get forgotPassword => "$baseURL/api/forgot-password";
  static String get resetPassword => "$baseURL/api/reset-password";

  // Absen
  static String get checkIn => "$baseURL/api/absen/check-in";
  static String get checkOut => "$baseURL/api/absen/check-out";
  static String get absenToday => "$baseURL/api/absen/today";
  static String get absenStats => "$baseURL/api/absen/stats";
  static String get history => "$baseURL/api/absen/history";
  static String get izin => "$baseURL/api/izin";
  static String get deleteAbsen => "$baseURL/api/delete-absen";

  // Profile
  static String get profile => "$baseURL/api/profile";
  static String get profilePhoto => "$baseURL/api/profile/photo";
  static String get updateProfile => "$baseURL/api/profile";

  // Training & Batch
  static String get trainingList => "$baseURL/api/trainings";
  static String get batches => "$baseURL/api/batches";
  static String get trainingDetail =>
      "$baseURL/api/trainings"; // /trainings/{id}

  // Device Token
  static String get deviceToken => "$baseURL/api/device-token";

  // Users
  static String get allUsers => "$baseURL/api/users";
}
