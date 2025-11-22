class GraphQLResponse {
  final dynamic data;
  final List<dynamic>? errors;
  final Map<String, dynamic>? extensions;

  GraphQLResponse({
    this.data,
    this.errors,
    this.extensions,
  });

  factory GraphQLResponse.fromJson(Map<String, dynamic> json) {
    return GraphQLResponse(
      data: json["data"],
      errors: json["errors"] is List
          ? List<dynamic>.from(json["errors"] as List)
          : null,
      extensions: json["extensions"] is Map
          ? Map<String, dynamic>.from(json["extensions"] as Map)
          : null,
    );
  }
}
