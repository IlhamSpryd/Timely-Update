// lib/models/reset_password_model.dart

import 'dart:convert';

ResetPasswordModel resetPasswordModelFromJson(String str) =>
    ResetPasswordModel.fromJson(json.decode(str));

String resetPasswordModelToJson(ResetPasswordModel data) =>
    json.encode(data.toJson());

class ResetPasswordModel {
  String? message;

  ResetPasswordModel({this.message});

  factory ResetPasswordModel.fromJson(Map<String, dynamic> json) =>
      ResetPasswordModel(message: json["message"]);

  Map<String, dynamic> toJson() => {"message": message};
}
