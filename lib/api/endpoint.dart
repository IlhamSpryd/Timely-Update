class Endpoint {
  static const String baseURL = "https://appabsensi.mobileprojp.com";

  // Auth
  static const String register = "$baseURL/api/register";
  static const String login = "$baseURL/api/login";
  static const String forgotPassword = "$baseURL/api/forgot-password";
  static const String resetPassword = "$baseURL/api/reset-password";

  // Absen
  static const String checkIn = "$baseURL/api/absen/check-in";
  static const String checkOut = "$baseURL/api/absen/check-out";
  static const String absenToday = "$baseURL/api/absen/today";
  static const String absenStats = "$baseURL/api/absen/stats";
  static const String history = "$baseURL/api/absen/history";
  static const String izin = "$baseURL/api/izin";
  static const String deleteAbsen = "$baseURL/api/delete-absen";

  // Profile
  static const String profile = "$baseURL/api/profile";
  static const String profilePhoto = "$baseURL/api/profile/photo";
  static const String updateProfile = "$baseURL/api/profile";

  // Training & Batch
  static const String trainingList = "$baseURL/api/trainings";
  static const String batches = "$baseURL/api/batches";
  static const String trainingDetail =
      "$baseURL/api/trainings"; // /trainings/{id}

  // Device Token
  static const String deviceToken = "$baseURL/api/device-token";

  // Users
  static const String allUsers = "$baseURL/api/users";
}
