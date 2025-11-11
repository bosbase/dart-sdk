## LangChaingo API (Dart SDK)

The Dart SDK exposes the `/api/langchaingo` endpoints through `pb.langchaingo`. Use it whenever you need an LLM completion or a LangChainGo retrieval workflow from Flutter, CLI, or server-side Dart code.

### Completion Example

```dart
import 'package:bosbase/bosbase.dart';

final pb = Bosbase("http://localhost:8090");

final completion = await pb.langchaingo.completions(
  LangChaingoCompletionRequest(
    model: const LangChaingoModelConfig(provider: "openai", model: "gpt-4o-mini"),
    messages: const [
      LangChaingoCompletionMessage(role: "system", content: "Answer in one sentence."),
      LangChaingoCompletionMessage(role: "user", content: "Explain Rayleigh scattering.")
    ],
    temperature: 0.2,
  ),
);

print(completion.content);
```

The model block is optional—BosBase defaults to OpenAI + `gpt-4o-mini` if the server already has the relevant environment variables.

### Retrieval-Augmented Generation

Combine the LangChaingo API with `pb.llmDocuments` collections to build RAG flows.

```dart
final response = await pb.langchaingo.rag(
  LangChaingoRAGRequest(
    collection: "knowledge-base",
    question: "Why is the sky blue?",
    topK: 4,
    returnSources: true,
    filters: const LangChaingoRAGFilters(where: {"topic": "physics"}),
  ),
);

print(response.answer);
for (final source in response.sources ?? const []) {
  print("${source.score?.toStringAsFixed(3)} ${source.metadata?['title']}");
}
```

Use the optional `promptTemplate` when you want to customize how the retrieved context is stuffed into the answer prompt:

```dart
await pb.langchaingo.rag(
  LangChaingoRAGRequest(
    collection: "knowledge-base",
    question: "Summarize the context below.",
    promptTemplate: "Context:\\n{{.context}}\\n\\nQuestion: {{.question}}\\nSummary:",
  ),
);
```

### Request Types

- `LangChaingoCompletionRequest` – prompt/messages, temperature, stop words, etc.
- `LangChaingoRAGRequest` – collection name, question, topK, filters, custom prompt template.

All request/response types live in `package:bosbase/bosbase.dart`.
