// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_schema_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectionSchemaInfo _$CollectionSchemaInfoFromJson(
        Map<String, dynamic> json) =>
    CollectionSchemaInfo(
      name: json['name'] as String? ?? "",
      type: json['type'] as String? ?? "",
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) =>
                  CollectionFieldSchemaInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CollectionSchemaInfoToJson(
        CollectionSchemaInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'fields': instance.fields.map((e) => e.toJson()).toList(),
    };
