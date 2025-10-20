// To parse this JSON data, do
//
//     final editProfileModel = editProfileModelFromJson(jsonString);

import 'dart:convert';

EditProfileModel editProfileModelFromJson(String str) =>
    EditProfileModel.fromJson(json.decode(str));

String editProfileModelToJson(EditProfileModel data) =>
    json.encode(data.toJson());

class EditProfileModel {
  String? message;
  EditProfileData? data;

  EditProfileModel({this.message, this.data});

  factory EditProfileModel.fromJson(Map<String, dynamic> json) =>
      EditProfileModel(
        message: json["message"],
        data: json["data"] == null
            ? null
            : EditProfileData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

// Mengubah nama kelas Data menjadi EditProfileData
class EditProfileData {
  int? id;
  String? name;
  String? email;
  String? emailVerifiedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? batchId;
  int? trainingId;
  String? jenisKelamin;
  String? profilePhoto;
  String? onesignalPlayerId;

  EditProfileData({
    this.id,
    this.name,
    this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.batchId,
    this.trainingId,
    this.jenisKelamin,
    this.profilePhoto,
    this.onesignalPlayerId,
  });

  factory EditProfileData.fromJson(Map<String, dynamic> json) =>
      EditProfileData(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        emailVerifiedAt: json["email_verified_at"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        batchId: json["batch_id"] is String
            ? int.tryParse(json["batch_id"])
            : json["batch_id"],
        trainingId: json["training_id"] is String
            ? int.tryParse(json["training_id"])
            : json["training_id"],
        jenisKelamin: json["jenis_kelamin"],
        profilePhoto: json["profile_photo"],
        onesignalPlayerId: json["onesignal_player_id"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "email_verified_at": emailVerifiedAt,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "batch_id": batchId,
    "training_id": trainingId,
    "jenis_kelamin": jenisKelamin,
    "profile_photo": profilePhoto,
    "onesignal_player_id": onesignalPlayerId,
  };
}
