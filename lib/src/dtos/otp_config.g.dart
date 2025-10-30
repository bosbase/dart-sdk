// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OTPConfig _$OTPConfigFromJson(Map<String, dynamic> json) => OTPConfig(
      duration: json['duration'] as num? ?? 0,
      length: json['length'] as num? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      emailTemplate: json['emailTemplate'] == null
          ? null
          : EmailTemplateConfig.fromJson(
              json['emailTemplate'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OTPConfigToJson(OTPConfig instance) => <String, dynamic>{
      'duration': instance.duration,
      'length': instance.length,
      'enabled': instance.enabled,
      'emailTemplate': instance.emailTemplate.toJson(),
    };
