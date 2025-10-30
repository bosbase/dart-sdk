import "dart:convert";

import "package:json_annotation/json_annotation.dart";

import "email_template_config.dart";
import "jsonable.dart";

part "otp_config.g.dart";

/// Response DTO of a single collection otp auth config.
@JsonSerializable(explicitToJson: true)
class OTPConfig implements Jsonable {
  num duration;
  num length;
  bool enabled;
  EmailTemplateConfig emailTemplate;

  OTPConfig({
    this.duration = 0,
    this.length = 0,
    this.enabled = false,
    EmailTemplateConfig? emailTemplate,
  }) : emailTemplate = emailTemplate ?? EmailTemplateConfig();

  static OTPConfig fromJson(Map<String, dynamic> json) =>
      _$OTPConfigFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$OTPConfigToJson(this);

  @override
  String toString() => jsonEncode(toJson());
}
