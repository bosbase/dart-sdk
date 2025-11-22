import "dart:async";
import "dart:convert";
import "dart:math";

import "package:web_socket_channel/web_socket_channel.dart";

import "../client_exception.dart";
import "base_service.dart";

class PubSubMessage<T> {
  final String id;
  final String topic;
  final String created;
  final T data;

  PubSubMessage({
    required this.id,
    required this.topic,
    required this.created,
    required this.data,
  });
}

class PublishAck {
  final String id;
  final String topic;
  final String created;

  PublishAck({
    required this.id,
    required this.topic,
    required this.created,
  });
}

typedef PubSubListener = void Function(PubSubMessage<dynamic> message);
typedef UnsubscribePubSub = Future<void> Function();

class PubSubService extends BaseService {
  PubSubService(super.client);

  final Map<String, Set<PubSubListener>> _subscriptions = {};
  final Map<String, _PendingAck> _pendingAcks = {};
  final List<Completer<void>> _pendingConnects = [];

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _reconnectTimer;
  Timer? _connectTimeout;
  int _reconnectAttempts = 0;
  bool _manualClose = false;
  bool _isReady = false;

  final List<int> _reconnectIntervals = [200, 300, 500, 1000, 1200, 1500, 2000];
  final int _ackTimeoutMs = 10000;
  final int _maxConnectTimeoutMs = 15000;

  bool get isConnected => _isReady;

  Future<PublishAck> publish(String topic, dynamic data) async {
    if (topic.isEmpty) {
      throw ArgumentError("topic must be set.");
    }

    await _ensureSocket();

    final requestId = _nextRequestId();
    final ackFuture = _waitForAck<PublishAck>(requestId, (payload) {
      return PublishAck(
        id: payload["id"]?.toString() ?? "",
        topic: payload["topic"]?.toString() ?? topic,
        created: payload["created"]?.toString() ?? "",
      );
    });

    await _sendEnvelope({
      "type": "publish",
      "topic": topic,
      "data": data,
      "requestId": requestId,
    });

    return ackFuture;
  }

  Future<UnsubscribePubSub> subscribe(String topic, PubSubListener listener) async {
    if (topic.isEmpty) {
      throw ArgumentError("topic must be set.");
    }

    var isFirst = false;
    if (!_subscriptions.containsKey(topic)) {
      _subscriptions[topic] = <PubSubListener>{};
      isFirst = true;
    }
    _subscriptions[topic]!.add(listener);

    await _ensureSocket();

    if (isFirst) {
      final requestId = _nextRequestId();
      _waitForAck<bool>(requestId, (_) => true).catchError((_) => false);
      await _sendEnvelope({
        "type": "subscribe",
        "topic": topic,
        "requestId": requestId,
      });
    }

    return () async {
      _subscriptions[topic]?.remove(listener);
      if (_subscriptions[topic]?.isEmpty ?? false) {
        _subscriptions.remove(topic);
        await _sendUnsubscribe(topic);
      }

      if (_subscriptions.isEmpty) {
        disconnect();
      }
    };
  }

  Future<void> unsubscribe([String topic = ""]) async {
    if (topic.isEmpty) {
      _subscriptions.clear();
      await _sendEnvelope({"type": "unsubscribe"});
      disconnect();
      return;
    }

    _subscriptions.remove(topic);
    await _sendUnsubscribe(topic);

    if (_subscriptions.isEmpty) {
      disconnect();
    }
  }

  void disconnect() {
    _manualClose = true;
    _rejectAllPending(ClientException(
      url: null,
      originalError: StateError("pubsub connection closed"),
    ));
    _closeChannel();
    _pendingConnects.clear();
  }

  Future<void> _ensureSocket() async {
    if (_isReady && _channel != null) {
      return;
    }

    final completer = Completer<void>();
    _pendingConnects.add(completer);

    if (_pendingConnects.length == 1) {
      _initConnect();
    }

    return completer.future;
  }

  void _initConnect() {
    _closeChannel(keepSubscriptions: true);
    _manualClose = false;
    _isReady = false;

    Uri url;
    try {
      url = _buildWebSocketURL();
    } catch (err) {
      _connectErrorHandler(err);
      return;
    }

    try {
      _channel = WebSocketChannel.connect(url);
    } catch (err) {
      _connectErrorHandler(err);
      return;
    }

    _connectTimeout?.cancel();
    _connectTimeout = Timer(Duration(milliseconds: _maxConnectTimeoutMs), () {
      _connectErrorHandler(StateError("WebSocket connect took too long."));
    });

    _channelSubscription = _channel!.stream.listen(
      (event) => _handleMessage(event),
      onError: (Object err, StackTrace stackTrace) =>
          _connectErrorHandler(err),
      onDone: _handleClose,
      cancelOnError: true,
    );
  }

  void _handleMessage(dynamic payload) {
    _connectTimeout?.cancel();

    if (payload is! String) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (data["type"]) {
      case "ready":
        _handleConnected();
        break;
      case "message":
        final topic = data["topic"]?.toString() ?? "";
        final listeners = _subscriptions[topic];
        if (listeners == null) return;
        final message = PubSubMessage(
          id: data["id"]?.toString() ?? "",
          topic: topic,
          created: data["created"]?.toString() ?? "",
          data: data["data"],
        );
        for (final listener in listeners.toList()) {
          try {
            listener(message);
          } catch (_) {}
        }
        break;
      case "published":
      case "subscribed":
      case "unsubscribed":
      case "pong":
        final requestId = data["requestId"]?.toString();
        if (requestId != null) {
          _resolvePending(requestId, data);
        }
        break;
      case "error":
        final requestId = data["requestId"]?.toString();
        if (requestId != null) {
          _rejectPending(
            requestId,
            ClientException(
              url: null,
              originalError: StateError(
                data["message"]?.toString() ?? "pubsub error",
              ),
            ),
          );
        }
        break;
    }
  }

  void _handleConnected() {
    final shouldResubscribe = _reconnectAttempts > 0;
    _reconnectAttempts = 0;
    _isReady = true;
    _reconnectTimer?.cancel();
    _connectTimeout?.cancel();

    for (final completer in _pendingConnects) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pendingConnects.clear();

    if (shouldResubscribe) {
      final topics = _subscriptions.keys.toList();
      for (final topic in topics) {
        final requestId = _nextRequestId();
        _waitForAck<bool>(requestId, (_) => true).catchError((_) {});
        _sendEnvelope({
          "type": "subscribe",
          "topic": topic,
          "requestId": requestId,
        });
      }
    }
  }

  void _handleClose() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;
    _isReady = false;
    _connectTimeout?.cancel();
    _reconnectTimer?.cancel();

    if (_manualClose) {
      return;
    }

    _rejectAllPending(StateError("pubsub connection closed"));

    if (_subscriptions.isEmpty) {
      // wake up any pending connect callers
      for (final c in _pendingConnects) {
        if (!c.isCompleted) {
          c.completeError(StateError("pubsub connection closed"));
        }
      }
      _pendingConnects.clear();
      return;
    }

    final timeout = _reconnectIntervals[
        _reconnectAttempts < _reconnectIntervals.length
            ? _reconnectAttempts
            : _reconnectIntervals.length - 1];
    if (_reconnectAttempts < 1 << 30) {
      _reconnectAttempts++;
      _reconnectTimer?.cancel();
      _reconnectTimer =
          Timer(Duration(milliseconds: timeout), () => _initConnect());
    }
  }

  Future<void> _sendEnvelope(Map<String, dynamic> data) async {
    if (_channel == null || !_isReady) {
      await _ensureSocket();
    }
    final ws = _channel;
    if (ws == null) {
      throw StateError("Unable to send websocket message - socket not initialized.");
    }
    ws.sink.add(jsonEncode(data));
  }

  Future<void> _sendUnsubscribe(String topic) async {
    if (_channel == null) {
      return;
    }
    final requestId = _nextRequestId();
    _waitForAck<bool>(requestId, (_) => true).catchError((_) {});
    await _sendEnvelope({
      "type": "unsubscribe",
      "topic": topic,
      "requestId": requestId,
    });
  }

  Uri _buildWebSocketURL() {
    final query = <String, dynamic>{};
    if (client.authStore.isValid) {
      query["token"] = client.authStore.token;
    }
    final httpUrl = client.buildURL("/api/pubsub", query);
    final isSecure = httpUrl.scheme == "https";
    return httpUrl.replace(scheme: isSecure ? "wss" : "ws");
  }

  void _connectErrorHandler(Object err) {
    _connectTimeout?.cancel();

    if (_reconnectAttempts > 1 << 30 || _manualClose) {
      _rejectAllPending(err);
      _closeChannel();
      return;
    }

    _closeChannel(keepSubscriptions: true);
    final timeout = _reconnectIntervals[
        _reconnectAttempts < _reconnectIntervals.length
            ? _reconnectAttempts
            : _reconnectIntervals.length - 1];
    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer =
        Timer(Duration(milliseconds: timeout), () => _initConnect());
  }

  void _closeChannel({bool keepSubscriptions = false}) {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connectTimeout?.cancel();
    _reconnectTimer?.cancel();

    if (!keepSubscriptions) {
      _subscriptions.clear();
      _pendingAcks.clear();
    }
  }

  Future<T> _waitForAck<T>(
      String requestId, T Function(Map<String, dynamic>) mapper) {
    final completer = Completer<T>();
    Timer? timer;

    timer = Timer(Duration(milliseconds: _ackTimeoutMs), () {
      _pendingAcks.remove(requestId);
      if (!completer.isCompleted) {
        completer.completeError(
          StateError("Timed out waiting for pubsub response."),
        );
      }
    });

    _pendingAcks[requestId] = _PendingAck(
      resolve: (payload) {
        timer?.cancel();
        if (!completer.isCompleted) {
          try {
            completer.complete(mapper(payload));
          } catch (err, stack) {
            completer.completeError(err, stack);
          }
        }
      },
      reject: (err) {
        timer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(err);
        }
      },
    );

    return completer.future;
  }

  void _resolvePending(String requestId, Map<String, dynamic> payload) {
    final pending = _pendingAcks.remove(requestId);
    pending?.resolve(payload);
  }

  void _rejectPending(String requestId, Object err) {
    final pending = _pendingAcks.remove(requestId);
    pending?.reject(err);
  }

  void _rejectAllPending(Object err) {
    for (final pending in _pendingAcks.values) {
      pending.reject(err);
    }
    _pendingAcks.clear();

    for (final pending in _pendingConnects) {
      if (!pending.isCompleted) {
        pending.completeError(err);
      }
    }
    _pendingConnects.clear();
  }

  String _nextRequestId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
        Random().nextInt(1 << 32).toRadixString(36);
  }
}

class _PendingAck {
  final void Function(Map<String, dynamic>) resolve;
  final void Function(Object) reject;

  _PendingAck({
    required this.resolve,
    required this.reject,
  });
}
