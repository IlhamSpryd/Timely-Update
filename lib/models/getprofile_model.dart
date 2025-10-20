// lib/models/getprofile_model.dart

import 'dart:convert';

GetProfileModel getProfileModelFromJson(String str) =>
    GetProfileModel.fromJson(json.decode(str));

String getProfileModelToJson(GetProfileModel data) =>
    json.encode(data.toJson());

class GetProfileModel {
  String? message;
  Data? data;

  GetProfileModel({this.message, this.data});

  factory GetProfileModel.fromJson(Map<String, dynamic> json) =>
      GetProfileModel(
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  final int id;
  final String name;
  final String email;
  final int batchId;
  final int trainingId;
  final String batchKe;
  final String trainingTitle;
  final String jenisKelamin;
  final String? profilePhotoUrl;
  final Batch batch;
  final Training training;

  Data({
    required this.id,
    required this.name,
    required this.email,
    required this.batchId,
    required this.trainingId,
    required this.batchKe,
    required this.trainingTitle,
    required this.jenisKelamin,
    this.profilePhotoUrl,
    required this.batch,
    required this.training,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["id"] ?? 0,
    name: json["name"] ?? '',
    email: json["email"] ?? '',
    // Mengambil ID dari dalam objek 'batch' dan 'training'
    batchId: json["batch"]?["id"] ?? 0,
    trainingId: json["training"]?["id"] ?? 0,
    // Tetap mengambil data dari level atas untuk kemudahan akses
    batchKe: json["batch_ke"] ?? '',
    trainingTitle: json["training_title"] ?? '',
    jenisKelamin: json["jenis_kelamin"] ?? '',
    profilePhotoUrl: json["profile_photo_url"],
    // Parsing objek 'batch' dan 'training' secara lengkap
    batch: Batch.fromJson(json["batch"] ?? {}),
    training: Training.fromJson(json["training"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "batch_id": batchId,
    "training_id": trainingId,
    "batch_ke": batchKe,
    "training_title": trainingTitle,
    "jenis_kelamin": jenisKelamin,
    "profile_photo_url": profilePhotoUrl,
    "batch": batch.toJson(),
    "training": training.toJson(),
  };
}

// Model untuk objek 'batch' yang ada di dalam 'data'
class Batch {
  final int id;
  final String batchKe;

  Batch({required this.id, required this.batchKe});

  factory Batch.fromJson(Map<String, dynamic> json) =>
      Batch(id: json["id"] ?? 0, batchKe: json["batch_ke"] ?? '');

  Map<String, dynamic> toJson() => {"id": id, "batch_ke": batchKe};
}

// Model untuk objek 'training' yang ada di dalam 'data'
class Training {
  final int id;
  final String title;

  Training({required this.id, required this.title});

  factory Training.fromJson(Map<String, dynamic> json) =>
      Training(id: json["id"] ?? 0, title: json["title"] ?? '');

  Map<String, dynamic> toJson() => {"id": id, "title": title};
}
