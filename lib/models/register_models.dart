// lib/models/register_models.dart

import 'dart:convert'; // FIX: Typo diperbaiki di sini

RegisterModel registerModelFromJson(String str) =>
    RegisterModel.fromJson(json.decode(str));

String registerModelToJson(RegisterModel data) => json.encode(data.toJson());

class RegisterModel {
  final String message;
  final Data? data;

  RegisterModel({required this.message, this.data});

  factory RegisterModel.fromJson(Map<String, dynamic> json) => RegisterModel(
    message: json["message"] ?? 'No message from server.',
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  final String token;
  final User user;
  final String profilePhotoUrl;

  Data({
    required this.token,
    required this.user,
    required this.profilePhotoUrl,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    token: json["token"] ?? '',
    user: User.fromJson(json["user"] ?? {}),
    profilePhotoUrl: json["profile_photo_url"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "token": token,
    "user": user.toJson(),
    "profile_photo_url": profilePhotoUrl,
  };
}

class User {
  final String name;
  final String email;
  final int batchId;
  final int trainingId;
  final String jenisKelamin;
  final String? profilePhoto;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int id;
  final Batch batch;
  final Training training;

  User({
    required this.name,
    required this.email,
    required this.batchId,
    required this.trainingId,
    required this.jenisKelamin,
    this.profilePhoto,
    this.updatedAt,
    this.createdAt,
    required this.id,
    required this.batch,
    required this.training,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json["name"] ?? 'Unknown Name',
    email: json["email"] ?? '',
    batchId: json["batch_id"] ?? 0,
    trainingId: json["training_id"] ?? 0,
    jenisKelamin: json["jenis_kelamin"] ?? '',
    profilePhoto: json["profile_photo"],
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.tryParse(json["updated_at"]),
    createdAt: json["created_at"] == null
        ? null
        : DateTime.tryParse(json["created_at"]),
    id: json["id"] ?? 0,
    batch: Batch.fromJson(json["batch"] ?? {}),
    training: Training.fromJson(json["training"] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "batch_id": batchId,
    "training_id": trainingId,
    "jenis_kelamin": jenisKelamin,
    "profile_photo": profilePhoto,
    "updated_at": updatedAt?.toIso8601String(),
    "created_at": createdAt?.toIso8601String(),
    "id": id,
    "batch": batch.toJson(),
    "training": training.toJson(),
  };
}

class Batch {
  final int id;
  final String batchKe;
  final String startDate;
  final String endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Batch({
    required this.id,
    required this.batchKe,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => Batch(
    id: json["id"] ?? 0,
    batchKe: json["batch_ke"] ?? '',
    startDate: json["start_date"] ?? '',
    endDate: json["end_date"] ?? '',
    createdAt: json["created_at"] == null
        ? null
        : DateTime.tryParse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.tryParse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "batch_ke": batchKe,
    "start_date": startDate,
    "end_date": endDate,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}

class Training {
  final int id;
  final String title;
  final String? description;
  final dynamic participantCount;
  final dynamic standard;
  final dynamic duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Training({
    required this.id,
    required this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory Training.fromJson(Map<String, dynamic> json) => Training(
    id: json["id"] ?? 0,
    title: json["title"] ?? 'No Title',
    description: json["description"],
    participantCount: json["participant_count"],
    standard: json["standard"],
    duration: json["duration"],
    createdAt: json["created_at"] == null
        ? null
        : DateTime.tryParse(json["created_at"]),
    updatedAt: json["updated_at"] == null
        ? null
        : DateTime.tryParse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "participant_count": participantCount,
    "standard": standard,
    "duration": duration,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
  };
}
