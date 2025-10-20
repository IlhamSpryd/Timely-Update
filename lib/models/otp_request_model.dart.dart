// lib/models/otp_request_model.dart

import 'dart:convert';

OtpRequestModel otpRequestModelFromJson(String str) =>
    OtpRequestModel.fromJson(json.decode(str));

String otpRequestModelToJson(OtpRequestModel data) =>
    json.encode(data.toJson());

class OtpRequestModel {
  String? message;

  OtpRequestModel({this.message});

  factory OtpRequestModel.fromJson(Map<String, dynamic> json) =>
      OtpRequestModel(message: json["message"]);

  Map<String, dynamic> toJson() => {"message": message};
}
