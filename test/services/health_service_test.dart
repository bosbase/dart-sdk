import "dart:convert";

import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:bosbase/bosbase.dart";
import "package:test/test.dart";

void main() {
  group("HealthService", () {
    test("check()", () async {
      final mock = MockClient((request) async {
        expect(request.method, "GET");
        expect(
          request.url.toString(),
          "/base/api/health?a=1&a=2&b=%40demo",
        );
        expect(request.headers["test"], "789");

        return http.Response(jsonEncode({"code": 200, "message": "test"}), 200);
      });

      final client = Bosbase("/base", httpClientFactory: () => mock);

      final result = await client.health.check(
        query: {
          "a": ["1", null, 2],
          "b": "@demo",
        },
        headers: {
          "test": "789",
        },
      );

      expect(result, isA<HealthCheck>());
      expect(result.code, 200);
      expect(result.message, "test");
    });
  });
}
