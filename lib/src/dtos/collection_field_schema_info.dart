import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "jsonable.dart";

part "collection_field_schema_info.g.dart";

/// Schema information for a single collection field.
/// Used for simplified schema queries that return only field names, types,
/// and basic metadata.
@JsonSerializable(explicitToJson: true)
class CollectionFieldSchemaInfo implements Jsonable {
  String name;
  String type;
  bool? required;
  bool? system;
  bool? hidden;

  CollectionFieldSchemaInfo({
    this.name = "",
    this.type = "",
    this.required,
    this.system,
    this.hidden,
  });

  static CollectionFieldSchemaInfo fromJson(Map<String, dynamic> json) =>
      _$CollectionFieldSchemaInfoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CollectionFieldSchemaInfoToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}

