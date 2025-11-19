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

### LLM Document Queries

> **Note**: This interface is only available to superusers.

When you want to pose a question to a specific `llmDocuments` collection and have LangChaingo+OpenAI synthesize an answer, use `queryDocuments`. It mirrors the RAG arguments but takes a `query` field:

```dart
final response = await pb.langchaingo.queryDocuments(
  LangChaingoDocumentQueryRequest(
    collection: "knowledge-base",
    query: "List three bullet points about Rayleigh scattering.",
    topK: 3,
    returnSources: true,
  ),
);

print(response.answer);
for (final source in response.sources ?? const []) {
  print("${source.score?.toStringAsFixed(3)} ${source.metadata?['title']}");
}
```

### SQL Generation + Execution

> **Important Notes**:
> - This interface is only available to superusers. Requests authenticated with regular `users` tokens return a `401 Unauthorized`.
> - It is recommended to execute query statements (SELECT) only.
> - **Do not use this interface for adding or modifying table structures.** Collection interfaces should be used instead for managing database schema.
> - Directly using this interface for initializing table structures and adding or modifying database tables will cause errors that prevent the automatic generation of APIs.

Superuser tokens (`_superusers` records) can ask LangChaingo to have OpenAI propose a SQL statement, execute it, and return both the generated SQL and execution output.

```dart
final result = await pb.langchaingo.sql(
  LangChaingoSQLRequest(
    query: "Add a demo project row if it doesn't exist, then list the 5 most recent projects.",
    tables: ["projects"], // optional hint to limit which tables the model sees
    topK: 5,
  ),
);

print(result.sql);    // Generated SQL
print(result.answer); // Model's summary of the execution
print(result.columns, result.rows);
```

Use `tables` to restrict which table definitions and sample rows are passed to the model, and `topK` to control how many rows the model should target when building queries. You can also pass the optional `model` block described above to override the default OpenAI model or key for this call.

### Request Types

- `LangChaingoCompletionRequest` – prompt/messages, temperature, stop words, etc.
- `LangChaingoRAGRequest` – collection name, question, topK, filters, custom prompt template.
- `LangChaingoDocumentQueryRequest` – collection name, query, topK, filters, custom prompt template.
- `LangChaingoSQLRequest` – query text, tables, topK, model config.

All request/response types live in `package:bosbase/bosbase.dart`.
