import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "collection_field_schema_info.dart";
import "jsonable.dart";

part "collection_schema_info.g.dart";

/// Schema information for a single collection.
/// Used for simplified schema queries that return only collection structure information.
@JsonSerializable(explicitToJson: true)
class CollectionSchemaInfo implements Jsonable {
  String name;
  String type;
  List<CollectionFieldSchemaInfo> fields;

  CollectionSchemaInfo({
    this.name = "",
    this.type = "",
    this.fields = const [],
  });

  static CollectionSchemaInfo fromJson(Map<String, dynamic> json) =>
      _$CollectionSchemaInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CollectionSchemaInfoToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

