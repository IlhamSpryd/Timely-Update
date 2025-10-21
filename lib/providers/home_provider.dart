import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/absen_today.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/services/absen_repository.dart';
import 'package:timely/services/profile_repository.dart';

// Enum untuk status yang lebih jelas
enum HomeState { initial, loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  // 1. Repositori untuk mengambil data
  final AbsenRepository _absenRepo = AbsenRepository();
  final ProfileRepository _profileRepo = ProfileRepository();

  // 2. Variabel State (data)
  HomeState _state = HomeState.initial;
  AbsenTodayModel? _absenToday;
  AbsenStatsModel? _absenStats;
  GetProfileModel? _user;
  String _errorMessage = '';

  // 3. Getter Dasar (agar UI bisa membaca data)
  HomeState get state => _state;
  AbsenTodayModel? get absenToday => _absenToday;
  AbsenStatsModel? get absenStats => _absenStats;
  GetProfileModel? get user => _user;
  String get errorMessage => _errorMessage;

  // --- 4. Getter Turunan (Logika yang dipindah dari UI) ---
  bool get hasCheckedIn => _absenToday?.data?.checkInTime != null;
  bool get hasCheckedOut => _absenToday?.data?.checkOutTime != null;

  String get todayStatusKey {
    if (_absenToday?.data?.status == "Izin") {
      return "leave";
    } else if (hasCheckedOut) {
      return "finished";
    } else if (hasCheckedIn) {
      return "present";
    } else {
      return "not_present";
    }
  }

  DateTime? get checkInTime => _parseTimeString(_absenToday?.data?.checkInTime);
  DateTime? get checkOutTime =>
      _parseTimeString(_absenToday?.data?.checkOutTime);

  String get userName => _user?.data?.name ?? 'Memuat...';
  String get userEmail => _user?.data?.email ?? '...';
  String? get profilePhotoUrl => _user?.data?.profilePhotoUrl;

  // --- 5. Logika Aksi ---

  // Mengambil data awal
  Future<void> fetchData() async {
    _state = HomeState.loading;
    notifyListeners();

    String errors = '';
    bool hasCriticalError = false;

    // 1. Ambil Profil (Kritis)
    try {
      _user = await _profileRepo.getProfile();
    } catch (e) {
      errors += 'Gagal memuat profil. ';
      hasCriticalError = true; // Anggap profil gagal = error utama
    }

    // 2. Ambil Absen Hari Ini (Non-kritis)
    try {
      _absenToday = await _absenRepo.getAbsenToday();
    } catch (e) {
      if (kDebugMode) {
        print("Info: Gagal memuat absen hari ini (mungkin belum absen): $e");
      }
      _absenToday = null;
    }

    // 3. Ambil Statistik (Non-kritis)
    try {
      _absenStats = await _absenRepo.getAbsenStats();
    } catch (e) {
      errors += 'Gagal memuat statistik. ';
      _absenStats = null;
    }

    // Set state akhir
    _errorMessage = errors;
    _state = hasCriticalError ? HomeState.error : HomeState.loaded;

    notifyListeners();
  }

  // Aksi Check-In
  Future<void> checkIn(double lat, double long, String address) async {
    try {
      await _absenRepo.checkIn(lat, long, address);
      await fetchData(); // Panggil fetchData() yang sudah aman
    } catch (e) {
      // Lempar error agar bisa ditangkap oleh UI
      throw e.toString().split("Exception:").last.trim();
    }
  }

  // Aksi Check-Out
  Future<void> checkOut(double lat, double long, String address) async {
    try {
      await _absenRepo.checkOut(lat, long, address);
      await fetchData(); // Panggil fetchData() yang sudah aman
    } catch (e) {
      throw e.toString().split("Exception:").last.trim();
    }
  }

  // Aksi Ajukan Izin
  Future<void> ajukanIzin(String reason) async {
    try {
      await _absenRepo.izin(reason);
      await fetchData(); // Panggil fetchData() yang sudah aman
    } catch (e) {
      throw e.toString().split("Exception:").last.trim();
    }
  }

  // --- 6. Fungsi Bantuan ---
  DateTime? _parseTimeString(String? timeString) {
    if (timeString == null) return null;
    try {
      final now = DateTime.now();
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (e) {
      if (kDebugMode) print("Error parsing time: $e");
    }
    return null;
  }
}
