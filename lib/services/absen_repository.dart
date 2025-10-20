import 'package:intl/intl.dart';
import 'package:timely/api/attendance_api.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/absen_today.dart';
import 'package:timely/models/checkin_model.dart';
import 'package:timely/models/checkout_model.dart';
import 'package:timely/models/deleteabsen_model.dart';
import 'package:timely/models/izin_model.dart';

class AbsenRepository {
  final AttendanceApi _api = AttendanceApi();

  Future<CheckinModel> checkIn(double lat, double lng, String address) async {
    final checkInTime = DateFormat('HH:mm').format(DateTime.now());
    print("📌 Repository: checkIn called");

    final result = await _api.checkIn(
      lat: lat,
      lng: lng,
      address: address,
      checkInTime: checkInTime,
    );

    if (result == null) throw Exception("Failed to check-in");
    return result;
  }

  Future<CheckoutModel> checkOut(double lat, double lng, String address) async {
    final checkOutTime = DateFormat('HH:mm').format(DateTime.now());
    print("📌 Repository: checkOut called");

    final result = await _api.checkOut(
      lat: lat,
      lng: lng,
      address: address,
      checkOutTime: checkOutTime,
    );

    if (result == null) throw Exception("Failed to check-out");
    return result;
  }

  Future<AbsenTodayModel> getAbsenToday() async {
    print("📌 Repository: getAbsenToday called");
    final result = await _api.getAbsenToday();
    if (result == null) throw Exception("Failed to get today's absen");
    return result;
  }

  Future<AbsenStatsModel> getAbsenStats() async {
    print("📌 Repository: getAbsenStats called");
    final result = await _api.getAbsenStats();
    if (result == null) throw Exception("Failed to get absen stats");
    return result;
  }

  Future<IzinModel> izin(String alasanIzin) async {
    print("📌 Repository: izin called");
    final result = await _api.izin(alasanIzin);
    if (result == null) throw Exception("Failed to submit izin");
    return result;
  }

  Future<DeleteAbsenModel> deleteAbsen(int absenId) async {
    print("📌 Repository: deleteAbsen called");
    final result = await _api.deleteAbsen(absenId);
    if (result == null) throw Exception("Failed to delete absen");
    return result;
  }
}
