## LLM Document API

Chromem-go is embedded directly in BosBase and exposed via `/api/llm-documents`. The Dart SDK provides `LLMDocumentService` for interacting with these endpoints.

### Create Collections

```dart
final pb = Bosbase("http://localhost:8090");

await pb.llmDocuments.createCollection(
  "knowledge-base",
  metadata: {"domain": "internal"},
);
```

### Insert Documents

```dart
await pb.llmDocuments.insert(
  LLMDocument(
    content: "Leaves are green because chlorophyll absorbs red and blue light.",
    metadata: {"topic": "biology"},
  ),
  collection: "knowledge-base",
);

await pb.llmDocuments.insert(
  LLMDocument(
    id: "sky",
    content: "The sky is blue because of Rayleigh scattering.",
    metadata: {"topic": "physics"},
  ),
  collection: "knowledge-base",
);
```

### Query

```dart
final response = await pb.llmDocuments.query(
  LLMQueryOptions(
    queryText: "Why is the sky blue?",
    limit: 2,
    where: {"topic": "physics"},
  ),
  collection: "knowledge-base",
);

for (final match in response["results"]) {
  print("${match["id"]}: ${match["similarity"]}");
}
```

### Manage

```dart
// list with pagination
final docs = await pb.llmDocuments.list(
  collection: "knowledge-base",
  page: 1,
  perPage: 25,
);

// update metadata
await pb.llmDocuments.update(
  "sky",
  LLMDocumentUpdate(metadata: {"topic": "physics", "reviewed": "true"}),
  collection: "knowledge-base",
);

// delete
await pb.llmDocuments.delete(
  "sky",
  collection: "knowledge-base",
);
```

### Go Reference

```go
err := c.AddDocuments(ctx, []chromem.Document{
    {ID: "1", Content: "The sky is blue because of Rayleigh scattering."},
    {ID: "2", Content: "Leaves are green because chlorophyll absorbs red and blue light."},
}, runtime.NumCPU())
if err != nil {
    panic(err)
}

res, err := c.Query(ctx, "Why is the sky blue?", 1, nil, nil)
if err != nil {
    panic(err)
}
_ = res
```

### HTTP Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET /api/llm-documents/collections` | List collections |
| `POST /api/llm-documents/collections/{name}` | Create collection |
| `DELETE /api/llm-documents/collections/{name}` | Delete collection |
| `GET /api/llm-documents/{collection}` | List documents |
| `POST /api/llm-documents/{collection}` | Insert document |
| `GET /api/llm-documents/{collection}/{id}` | Fetch document |
| `PATCH /api/llm-documents/{collection}/{id}` | Update document |
| `DELETE /api/llm-documents/{collection}/{id}` | Delete document |
| `POST /api/llm-documents/{collection}/documents/query` | Query by semantic similarity |
