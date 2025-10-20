// To parse this JSON data, do
//
//     final deleteAbsenModel = deleteAbsenModelFromJson(jsonString);

import 'dart:convert';

DeleteAbsenModel deleteAbsenModelFromJson(String str) =>
    DeleteAbsenModel.fromJson(json.decode(str));

String deleteAbsenModelToJson(DeleteAbsenModel data) =>
    json.encode(data.toJson());

class DeleteAbsenModel {
  String? message;
  Data? data;

  DeleteAbsenModel({this.message, this.data});

  factory DeleteAbsenModel.fromJson(Map<String, dynamic> json) =>
      DeleteAbsenModel(
        message: json["message"],

        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class Data {
  String? id;

  Data({this.id});

  factory Data.fromJson(Map<String, dynamic> json) => Data(id: json["id"]);

  Map<String, dynamic> toJson() => {"id": id};
}
