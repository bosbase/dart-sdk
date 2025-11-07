import "dart:convert";

import "package:bosbase/bosbase.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:test/test.dart";

void main() {
  group("CacheService", () {
    test("list()", () async {
      final mock = MockClient((request) async {
        expect(request.method, "GET");
        expect(request.url.toString(), "/base/api/cache");

        return http.Response(
          jsonEncode({
            "items": [
              {
                "name": "primary",
                "sizeBytes": 1024,
                "defaultTTLSeconds": 60,
                "readTimeoutMs": 25,
              },
            ],
          }),
          200,
        );
      });

      final client = Bosbase("/base", httpClientFactory: () => mock);
      final items = await client.caches.list();

      expect(items, isNotEmpty);
      expect(items.first.name, "primary");
    });

    test("create()", () async {
      final mock = MockClient((request) async {
        expect(request.method, "POST");
        expect(request.url.toString(), "/base/api/cache");
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body["name"], "ai-cache");

        return http.Response(
          jsonEncode({"name": "ai-cache", "sizeBytes": 1024}),
          201,
        );
      });

      final client = Bosbase("/base", httpClientFactory: () => mock);
      final created = await client.caches.create(name: "ai-cache");

      expect(created.name, "ai-cache");
    });

    test("setEntry()", () async {
      final mock = MockClient((request) async {
        expect(request.method, "PUT");
        expect(
          request.url.toString(),
          "/base/api/cache/ai-cache/entries/dialog%3A1",
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body["ttlSeconds"], 90);

        return http.Response(
          jsonEncode({
            "cache": "ai-cache",
            "key": "dialog:1",
            "value": {"hello": "world"},
            "source": "cache",
          }),
          200,
        );
      });

      final client = Bosbase("/base", httpClientFactory: () => mock);
      final entry = await client.caches.setEntry("ai-cache", "dialog:1", {
        "hello": "world",
      }, ttlSeconds: 90);

      expect(entry.cache, "ai-cache");
      expect(entry.value, containsPair("hello", "world"));
    });

    test("deleteEntry()", () async {
      final mock = MockClient((request) async {
        expect(request.method, "DELETE");
        expect(
          request.url.toString(),
          "/base/api/cache/ai-cache/entries/dialog%3A1",
        );

        return http.Response("", 204);
      });

      final client = Bosbase("/base", httpClientFactory: () => mock);
      await client.caches.deleteEntry("ai-cache", "dialog:1");
    });
  });
}
