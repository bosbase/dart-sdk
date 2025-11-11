class LangChaingoModelConfig {
  final String? provider;
  final String? model;
  final String? apiKey;
  final String? baseUrl;

  const LangChaingoModelConfig({
    this.provider,
    this.model,
    this.apiKey,
    this.baseUrl,
  });

  Map<String, dynamic> toJson() => {
    if (provider != null) "provider": provider,
    if (model != null) "model": model,
    if (apiKey != null) "apiKey": apiKey,
    if (baseUrl != null) "baseUrl": baseUrl,
  };
}

class LangChaingoCompletionMessage {
  final String? role;
  final String content;

  const LangChaingoCompletionMessage({this.role, required this.content});

  Map<String, dynamic> toJson() => {
    if (role != null) "role": role,
    "content": content,
  };
}

class LangChaingoCompletionRequest {
  final LangChaingoModelConfig? model;
  final String? prompt;
  final List<LangChaingoCompletionMessage>? messages;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final int? candidateCount;
  final List<String>? stop;
  final bool? json;

  const LangChaingoCompletionRequest({
    this.model,
    this.prompt,
    this.messages,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.candidateCount,
    this.stop,
    this.json,
  });

  Map<String, dynamic> toJson() => {
    if (model != null) "model": model!.toJson(),
    if (prompt != null) "prompt": prompt,
    if (messages != null) "messages": messages!.map((m) => m.toJson()).toList(),
    if (temperature != null) "temperature": temperature,
    if (maxTokens != null) "maxTokens": maxTokens,
    if (topP != null) "topP": topP,
    if (candidateCount != null) "candidateCount": candidateCount,
    if (stop != null) "stop": stop,
    if (json != null) "json": json,
  };
}

class LangChaingoFunctionCall {
  final String name;
  final String arguments;

  const LangChaingoFunctionCall({required this.name, required this.arguments});

  factory LangChaingoFunctionCall.fromJson(Map<String, dynamic> json) =>
      LangChaingoFunctionCall(
        name: json["name"] ?? "",
        arguments: json["arguments"] ?? "",
      );
}

class LangChaingoToolCall {
  final String id;
  final String type;
  final LangChaingoFunctionCall? functionCall;

  const LangChaingoToolCall({
    required this.id,
    required this.type,
    this.functionCall,
  });

  factory LangChaingoToolCall.fromJson(Map<String, dynamic> json) =>
      LangChaingoToolCall(
        id: json["id"] ?? "",
        type: json["type"] ?? "",
        functionCall: json["functionCall"] is Map<String, dynamic>
            ? LangChaingoFunctionCall.fromJson(
                json["functionCall"] as Map<String, dynamic>,
              )
            : null,
      );
}

class LangChaingoCompletionResponse {
  final String content;
  final String? stopReason;
  final Map<String, dynamic>? generationInfo;
  final LangChaingoFunctionCall? functionCall;
  final List<LangChaingoToolCall>? toolCalls;

  const LangChaingoCompletionResponse({
    required this.content,
    this.stopReason,
    this.generationInfo,
    this.functionCall,
    this.toolCalls,
  });

  factory LangChaingoCompletionResponse.fromJson(Map<String, dynamic> json) =>
      LangChaingoCompletionResponse(
        content: json["content"] ?? "",
        stopReason: json["stopReason"],
        generationInfo: json["generationInfo"] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json["generationInfo"])
            : null,
        functionCall: json["functionCall"] is Map<String, dynamic>
            ? LangChaingoFunctionCall.fromJson(
                json["functionCall"] as Map<String, dynamic>,
              )
            : null,
        toolCalls: (json["toolCalls"] as List?)
            ?.map(
              (item) =>
                  LangChaingoToolCall.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
}

class LangChaingoRAGFilters {
  final Map<String, String>? where;
  final Map<String, String>? whereDocument;

  const LangChaingoRAGFilters({this.where, this.whereDocument});

  Map<String, dynamic> toJson() => {
    if (where != null) "where": where,
    if (whereDocument != null) "whereDocument": whereDocument,
  };
}

class LangChaingoRAGRequest {
  final LangChaingoModelConfig? model;
  final String collection;
  final String question;
  final int? topK;
  final double? scoreThreshold;
  final LangChaingoRAGFilters? filters;
  final String? promptTemplate;
  final bool? returnSources;

  const LangChaingoRAGRequest({
    this.model,
    required this.collection,
    required this.question,
    this.topK,
    this.scoreThreshold,
    this.filters,
    this.promptTemplate,
    this.returnSources,
  });

  Map<String, dynamic> toJson() => {
    if (model != null) "model": model!.toJson(),
    "collection": collection,
    "question": question,
    if (topK != null) "topK": topK,
    if (scoreThreshold != null) "scoreThreshold": scoreThreshold,
    if (filters != null) "filters": filters!.toJson(),
    if (promptTemplate != null) "promptTemplate": promptTemplate,
    if (returnSources != null) "returnSources": returnSources,
  };
}

class LangChaingoSourceDocument {
  final String content;
  final Map<String, dynamic>? metadata;
  final double? score;

  const LangChaingoSourceDocument({
    required this.content,
    this.metadata,
    this.score,
  });

  factory LangChaingoSourceDocument.fromJson(Map<String, dynamic> json) =>
      LangChaingoSourceDocument(
        content: json["content"] ?? "",
        metadata: json["metadata"] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json["metadata"])
            : null,
        score: json["score"] is num ? (json["score"] as num).toDouble() : null,
      );
}

class LangChaingoRAGResponse {
  final String answer;
  final List<LangChaingoSourceDocument>? sources;

  const LangChaingoRAGResponse({required this.answer, this.sources});

  factory LangChaingoRAGResponse.fromJson(
    Map<String, dynamic> json,
  ) => LangChaingoRAGResponse(
    answer: json["answer"] ?? "",
    sources: (json["sources"] as List?)
        ?.map(
          (item) =>
              LangChaingoSourceDocument.fromJson(item as Map<String, dynamic>),
        )
        .toList(),
  );
}
